#include "YOLODetector.h"
#include "QGCLoggingCategory.h"
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonObject>
#include <QtCore/QTimer>
#include <QtCore/QStandardPaths>
#include <QtCore/QDir>
#include <QtGui/QImage>

QGC_LOGGING_CATEGORY(YOLODetectorLog, "Video.YOLODetector")

YOLODetector::YOLODetector(QObject* parent)
    : QObject(parent)
    , _process(new QProcess(this))
    , _restartTimer(new QTimer(this))
    , _pythonPath("/Users/elisabeth/Dev/qgroundcontrol/yolo_env/bin/python")
    , _scriptPath("")
    , _modelPath("yolov8n.pt")
    , _confidence(0.5)
    , _enabled(false)
    , _processRunning(false)
    , _status("Stopped")
    , _frameCount(0)
    , _fps(0.0)
    , _fpsFrameCount(0)
    , _hasFrame(false)
{
    // Set script path to project root
    _scriptPath = QStandardPaths::writableLocation(QStandardPaths::HomeLocation) + "/Dev/qgroundcontrol/yolo_processor.py";

    // Setup process connections
    connect(_process, &QProcess::readyReadStandardOutput, this, &YOLODetector::onProcessOutput);
    connect(_process, &QProcess::readyReadStandardError, this, &YOLODetector::onProcessError);
    connect(_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &YOLODetector::onProcessFinished);

    // Setup restart timer
    _restartTimer->setSingleShot(true);
    _restartTimer->setInterval(2000); // 2 seconds
    connect(_restartTimer, &QTimer::timeout, this, &YOLODetector::onRestartTimer);

    // Setup FPS timer
    _fpsTimer.start();

    qCDebug(YOLODetectorLog) << "YOLODetector initialized with script:" << _scriptPath;
}

YOLODetector::~YOLODetector()
{
    stopProcess();
}

void YOLODetector::setEnabled(bool enabled)
{
    if (_enabled != enabled) {
        _enabled = enabled;
        qCDebug(YOLODetectorLog) << "YOLODetector enabled:" << enabled;

        if (enabled) {
            startProcess();
        } else {
            stopProcess();
        }

        emit enabledChanged();
    }
}

void YOLODetector::setConfidence(double confidence)
{
    if (_confidence != confidence) {
        _confidence = confidence;
        qCDebug(YOLODetectorLog) << "YOLODetector confidence:" << confidence;
        emit confidenceChanged();
    }
}

void YOLODetector::setModelPath(const QString &modelPath)
{
    if (_modelPath != modelPath) {
        _modelPath = modelPath;
        qCDebug(YOLODetectorLog) << "YOLODetector model path:" << modelPath;
        emit modelPathChanged();

        // Restart process if running to apply new model
        if (_enabled && _processRunning) {
            stopProcess();
            startProcess();
        }
    }
}

void YOLODetector::processFrameBytes(const QByteArray& frameData, int width, int height, int strideBytes)
{
    Q_UNUSED(strideBytes)

    if (!_enabled || !_processRunning) {
        return;
    }

    sendFrameBytes(frameData, width, height);
}

void YOLODetector::processFrame(const QImage &frame)
{
    if (!_enabled || !_processRunning) {
        return;
    }

    sendFrame(frame);
}

void YOLODetector::sendFrame(const QImage &frame)
{
    if (!_process || _process->state() != QProcess::Running) {
        return;
    }

    // Convert frame to RGB888 format
    QImage rgbFrame = frame.convertToFormat(QImage::Format_RGB888);

    // Send frame dimensions and data
    int width = rgbFrame.width();
    int height = rgbFrame.height();
    int channels = 3;

    // Write header: width, height, channels (4 bytes each, little-endian)
    _process->write(reinterpret_cast<const char*>(&width), 4);
    _process->write(reinterpret_cast<const char*>(&height), 4);
    _process->write(reinterpret_cast<const char*>(&channels), 4);

    // Write image data
    QByteArray frameBytes = QByteArray::fromRawData(
        reinterpret_cast<const char*>(rgbFrame.bits()),
        rgbFrame.sizeInBytes()
    );
    _process->write(frameBytes);

    updateFPS();
}

void YOLODetector::sendFrameBytes(const QByteArray &frameData, int width, int height)
{
    if (!_process || _process->state() != QProcess::Running) {
        return;
    }

    int channels = 3; // Assume RGB

    // Write header: width, height, channels (4 bytes each, little-endian)
    _process->write(reinterpret_cast<const char*>(&width), 4);
    _process->write(reinterpret_cast<const char*>(&height), 4);
    _process->write(reinterpret_cast<const char*>(&channels), 4);

    // Write frame data
    _process->write(frameData);

    updateFPS();
}

void YOLODetector::onProcessOutput()
{
    if (!_process) {
        return;
    }

    QByteArray output = _process->readAllStandardOutput();
    _outputBuffer.append(output);

    // Process complete lines
    while (_outputBuffer.contains('\n')) {
        int newlinePos = _outputBuffer.indexOf('\n');
        QByteArray line = _outputBuffer.left(newlinePos);
        _outputBuffer = _outputBuffer.mid(newlinePos + 1);

        parseOutput(line);
    }
}

void YOLODetector::parseOutput(const QByteArray &data)
{
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);

    if (error.error == QJsonParseError::NoError && doc.isObject()) {
        QJsonObject obj = doc.object();

        // Update detections
        QJsonArray detections = obj["detections"].toArray();
        updateDetections(detections);

        // Update FPS
        if (obj.contains("fps")) {
            _fps = obj["fps"].toDouble();
            emit fpsChanged();
        }

        // Update frame count
        if (obj.contains("frame_count")) {
            _frameCount = obj["frame_count"].toInt();
            emit frameCountChanged();
        }
    } else {
        qCWarning(YOLODetectorLog) << "Failed to parse JSON from YOLO process:" << error.errorString();
        qCWarning(YOLODetectorLog) << "Raw output:" << data;
    }
}

void YOLODetector::onProcessError()
{
    if (!_process) {
        return;
    }

    QByteArray errorOutput = _process->readAllStandardError();
    if (!errorOutput.isEmpty()) {
        qCWarning(YOLODetectorLog) << "YOLO process error:" << errorOutput;
        _status = "Error: " + QString(errorOutput).trimmed();
        emit statusChanged();
        emit errorOccurred(_status);
    }
}

void YOLODetector::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus)

    qCWarning(YOLODetectorLog) << "YOLO process finished with exit code:" << exitCode;
    _processRunning = false;
    _status = "Process stopped";
    emit statusChanged();

    // Restart process if it crashed and we're still enabled
    if (_enabled && exitCode != 0) {
        qCDebug(YOLODetectorLog) << "Restarting YOLO process in 2 seconds...";
        _restartTimer->start();
    }
}

void YOLODetector::onRestartTimer()
{
    if (_enabled) {
        startProcess();
    }
}

void YOLODetector::startProcess()
{
    if (_process && _process->state() == QProcess::Running) {
        return;
    }

    qCDebug(YOLODetectorLog) << "Starting YOLO process:" << _scriptPath;

    // Check if script exists
    if (!QFile::exists(_scriptPath)) {
        qCCritical(YOLODetectorLog) << "YOLO script not found:" << _scriptPath;
        _status = "Script not found";
        emit statusChanged();
        return;
    }

    // Build command line arguments
    QStringList args;
    args << _scriptPath;
    args << "--model" << _modelPath;
    args << "--confidence" << QString::number(_confidence);

    qCDebug(YOLODetectorLog) << "Starting:" << _pythonPath << args;

    _process->start(_pythonPath, args);

    if (!_process->waitForStarted(5000)) {
        qCCritical(YOLODetectorLog) << "Failed to start YOLO process:" << _process->errorString();
        _status = "Failed to start: " + _process->errorString();
        emit statusChanged();
        emit errorOccurred(_status);
        return;
    }

    _processRunning = true;
    _status = "Running";
    emit statusChanged();

    qCDebug(YOLODetectorLog) << "YOLO process started successfully";
}

void YOLODetector::stopProcess()
{
    if (_process && _process->state() == QProcess::Running) {
        qCDebug(YOLODetectorLog) << "Stopping YOLO process";
        _process->terminate();

        if (!_process->waitForFinished(3000)) {
            qCWarning(YOLODetectorLog) << "YOLO process did not terminate gracefully, killing it";
            _process->kill();
            _process->waitForFinished(1000);
        }
    }

    _processRunning = false;
    _status = "Stopped";
    emit statusChanged();
}

void YOLODetector::updateDetections(const QJsonArray& newDetections)
{
    _detections = newDetections;
    emit detectionsChanged();

    qCDebug(YOLODetectorLog) << "Updated detections:" << newDetections.size() << "objects";
}

void YOLODetector::updateFPS()
{
    _fpsFrameCount++;

    // Update FPS every second
    if (_fpsTimer.elapsed() >= 1000) {
        _fps = _fpsFrameCount * 1000.0 / _fpsTimer.elapsed();
        _fpsFrameCount = 0;
        _fpsTimer.restart();
        emit fpsChanged();
    }
}
