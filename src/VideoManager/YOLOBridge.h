#pragma once

#include <QtCore/QObject>
#include <QtCore/QProcess>
#include <QtCore/QString>
#include <QtCore/QVariantList>
#include <QtCore/QVariantMap>
#include <QtQmlIntegration/QtQmlIntegration>

class YOLOBridge : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool     running          READ running          NOTIFY runningChanged)
    Q_PROPERTY(bool     paused           READ paused           NOTIFY pausedChanged)
    Q_PROPERTY(int      frameCount       READ frameCount       NOTIFY statsChanged)
    Q_PROPERTY(int      totalDetections  READ totalDetections  NOTIFY statsChanged)
    Q_PROPERTY(double   fps              READ fps              NOTIFY statsChanged)
    Q_PROPERTY(int      currentCount     READ currentCount     NOTIFY detectionsChanged)
    Q_PROPERTY(QVariantList detections   READ detections       NOTIFY detectionsChanged)
    Q_PROPERTY(QString  logMessage       READ logMessage       NOTIFY logMessageChanged)
    Q_PROPERTY(double   confidence       READ confidence       WRITE setConfidence NOTIFY confidenceChanged)

public:
    explicit YOLOBridge(QObject* parent = nullptr);
    ~YOLOBridge() override;

    static YOLOBridge* create(QQmlEngine*, QJSEngine*);
    static YOLOBridge* instance();

    bool        running()         const { return _running; }
    bool        paused()          const { return _paused; }
    int         frameCount()      const { return _frameCount; }
    int         totalDetections() const { return _totalDetections; }
    double      fps()             const { return _fps; }
    int         currentCount()    const { return _detections.size(); }
    QVariantList detections()     const { return _detections; }
    QString     logMessage()      const { return _logMessage; }
    double      confidence()      const { return _confidence; }

    Q_INVOKABLE void start(const QString& pythonPath = "python3",
                           const QString& scriptPath = "",
                           const QString& modelPath  = "yolo11n.pt",
                           int cameraId = 0);
    Q_INVOKABLE void stop();
    Q_INVOKABLE void togglePause();
    Q_INVOKABLE void setConfidence(double conf);
    Q_INVOKABLE void selectObject(int objectId);

signals:
    void runningChanged();
    void pausedChanged();
    void statsChanged();
    void detectionsChanged();
    void logMessageChanged();
    void confidenceChanged();
    void detectionReceived(int frame, double fps, QVariantList dets);

private slots:
    void _onReadyRead();
    void _onProcessError(QProcess::ProcessError error);
    void _onProcessFinished(int exitCode, QProcess::ExitStatus status);

private:
    void _sendCommand(const QVariantMap& cmd);
    void _handlePacket(const QVariantMap& packet);
    void _setRunning(bool r);

    QProcess*    _process    = nullptr;
    bool         _running    = false;
    bool         _paused     = false;
    int          _frameCount = 0;
    int          _totalDetections = 0;
    double       _fps        = 0.0;
    double       _confidence = 0.25;
    QVariantList _detections;
    QString      _logMessage;
    QString      _scriptPath;

    static YOLOBridge* _instance;
};
