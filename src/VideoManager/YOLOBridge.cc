#include "YOLOBridge.h"

#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QJsonValue>
#include <QtCore/QStandardPaths>

YOLOBridge* YOLOBridge::_instance = nullptr;

YOLOBridge::YOLOBridge(QObject* parent)
    : QObject(parent)
{
    _instance = this;
}

YOLOBridge::~YOLOBridge()
{
    stop();
    _instance = nullptr;
}

YOLOBridge* YOLOBridge::create(QQmlEngine*, QJSEngine*)
{
    if (!_instance) {
        _instance = new YOLOBridge(nullptr); // No parent; let QML Engine own it
    }
    return _instance;
}

YOLOBridge* YOLOBridge::instance()
{
    return _instance;
}

void YOLOBridge::start(const QString& pythonPath, const QString& scriptPath,
                       const QString& modelPath, int cameraId)
{
    if (_running) {
        qWarning() << "YOLOBridge: already running";
        return;
    }

    // Resolve script path: prefer explicit arg, then next to the app bundle
    QString resolvedScript = scriptPath;
    if (resolvedScript.isEmpty()) {
        // Look next to the executable first
        QString appDir = QCoreApplication::applicationDirPath();
        QStringList candidates = {
            appDir + "/yolo_qgc_bridge.py",
            appDir + "/../Resources/yolo_qgc_bridge.py",
            QDir::currentPath() + "/yolo_qgc_bridge.py",
            QDir::currentPath() + "/src/VideoManager/yolo_qgc_bridge.py"
        };
        for (const QString& c : candidates) {
            if (QFile::exists(c)) {
                resolvedScript = c;
                break;
            }
        }
    }

    if (resolvedScript.isEmpty() || !QFile::exists(resolvedScript)) {
        _logMessage = "yolo_qgc_bridge.py not found. Check script path.";
        emit logMessageChanged();
        qWarning() << "YOLOBridge:" << _logMessage;
        return;
    }

    _scriptPath = resolvedScript;
    _detections.clear();
    _frameCount = 0;
    _totalDetections = 0;
    _fps = 0.0;

    _process = new QProcess(this);

    connect(_process, &QProcess::readyReadStandardOutput, this, &YOLOBridge::_onReadyRead);
    connect(_process, &QProcess::errorOccurred, this, &YOLOBridge::_onProcessError);
    connect(_process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, &YOLOBridge::_onProcessFinished);

    QStringList args = {
        resolvedScript,
        "--model", modelPath,
        "--camera", QString::number(cameraId),
        "--conf", QString::number(_confidence)
    };

    _process->start(pythonPath, args);

    if (!_process->waitForStarted(5000)) {
        _logMessage = "Failed to start Python process. Check python3 path.";
        emit logMessageChanged();
        _process->deleteLater();
        _process = nullptr;
        return;
    }

    _setRunning(true);
    _logMessage = QString("Started: %1").arg(resolvedScript);
    emit logMessageChanged();
}

void YOLOBridge::stop()
{
    if (!_running || !_process) return;

    _sendCommand({{"cmd", "stop"}});

    if (!_process->waitForFinished(3000)) {
        _process->kill();
    }
    // cleanup happens in _onProcessFinished
}

void YOLOBridge::togglePause()
{
    if (!_running) return;
    _sendCommand({{"cmd", "pause"}});
    _paused = !_paused;
    emit pausedChanged();
}

void YOLOBridge::setConfidence(double conf)
{
    _confidence = qBound(0.01, conf, 1.0);
    emit confidenceChanged();
    if (_running) {
        _sendCommand({{"cmd", "set_conf"}, {"value", _confidence}});
    }
}

void YOLOBridge::selectObject(int objectId)
{
    if (!_running) return;
    _sendCommand({{"cmd", "select"}, {"id", objectId}});
}

// ── Private ──────────────────────────────────────────────────────────────────

void YOLOBridge::_sendCommand(const QVariantMap& cmd)
{
    if (!_process || _process->state() != QProcess::Running) return;
    QJsonDocument doc(QJsonObject::fromVariantMap(cmd));
    _process->write(doc.toJson(QJsonDocument::Compact) + "\n");
}

void YOLOBridge::_onReadyRead()
{
    if (!_process) return;

    while (_process->canReadLine()) {
        const QByteArray line = _process->readLine().trimmed();
        if (line.isEmpty()) continue;

        QJsonParseError err;
        const QJsonDocument doc = QJsonDocument::fromJson(line, &err);
        if (err.error != QJsonParseError::NoError) continue;

        _handlePacket(doc.object().toVariantMap());
    }
}

void YOLOBridge::_handlePacket(const QVariantMap& packet)
{
    const QString type = packet.value("type").toString();

    if (type == "detections") {
        _frameCount       = packet.value("frame").toInt();
        _fps              = packet.value("fps").toDouble();
        _totalDetections  = packet.value("total_detections").toInt();

        _detections.clear();
        const QVariantList dets = packet.value("detections").toList();
        for (const QVariant& d : dets) {
            _detections.append(d);
        }

        emit statsChanged();
        emit detectionsChanged();
        emit detectionReceived(_frameCount, _fps, _detections);

    } else if (type == "log") {
        _logMessage = packet.value("message").toString();
        emit logMessageChanged();
        qDebug() << "[YOLO]" << _logMessage;

    } else if (type == "status") {
        const QString status = packet.value("status").toString();
        if (status == "stopped") {
            _setRunning(false);
        }
        _frameCount      = packet.value("frame").toInt();
        _fps             = packet.value("fps").toDouble();
        _totalDetections = packet.value("total").toInt();
        emit statsChanged();
    }
}

void YOLOBridge::_onProcessError(QProcess::ProcessError error)
{
    _logMessage = QString("Process error: %1").arg(static_cast<int>(error));
    emit logMessageChanged();
    _setRunning(false);
}

void YOLOBridge::_onProcessFinished(int exitCode, QProcess::ExitStatus /*status*/)
{
    _logMessage = QString("Process exited (code %1)").arg(exitCode);
    emit logMessageChanged();
    _setRunning(false);
    _process->deleteLater();
    _process = nullptr;
}

void YOLOBridge::_setRunning(bool r)
{
    if (_running != r) {
        _running = r;
        emit runningChanged();
    }
}
