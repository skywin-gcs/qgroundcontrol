#pragma once

#include <QtCore/QObject>
#include <QtCore/QProcess>
#include <QtCore/QTimer>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonObject>
#include <QtCore/QElapsedTimer>
#include <QtCore/QMutex>
#include <QtGui/QImage>

class YOLODetector : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QJsonArray detections READ detections NOTIFY detectionsChanged)
    Q_PROPERTY(double confidence READ confidence WRITE setConfidence NOTIFY confidenceChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString modelPath READ modelPath WRITE setModelPath NOTIFY modelPathChanged)
    Q_PROPERTY(double fps READ fps NOTIFY fpsChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY frameCountChanged)

public:
    explicit YOLODetector(QObject* parent = nullptr);
    ~YOLODetector();

    // Property getters
    bool enabled() const { return _enabled; }
    QJsonArray detections() const { return _detections; }
    double confidence() const { return _confidence; }
    QString status() const { return _status; }
    QString modelPath() const { return _modelPath; }
    double fps() const { return _fps; }
    int frameCount() const { return _frameCount; }

public slots:
    void setEnabled(bool enabled);
    void setConfidence(double confidence);
    void setModelPath(const QString &modelPath);
    void processFrameBytes(const QByteArray& frameData, int width, int height, int strideBytes);
    void processFrame(const QImage &frame);

signals:
    void enabledChanged();
    void detectionsChanged();
    void confidenceChanged();
    void statusChanged();
    void modelPathChanged();
    void fpsChanged();
    void frameCountChanged();
    void errorOccurred(const QString &error);

private slots:
    void onProcessOutput();
    void onProcessError();
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onRestartTimer();

private:
    void startProcess();
    void stopProcess();
    void sendFrame(const QImage &frame);
    void sendFrameBytes(const QByteArray &frameData, int width, int height);
    void parseOutput(const QByteArray &data);
    void updateDetections(const QJsonArray& newDetections);
    void updateFPS();

    // Process management
    QProcess* _process;
    QTimer* _restartTimer;
    QString _pythonPath;
    QString _scriptPath;
    QString _modelPath;
    double _confidence;
    bool _enabled;
    bool _processRunning;
    QString _status;

    // Statistics
    QElapsedTimer _fpsTimer;
    int _frameCount;
    double _fps;
    int _fpsFrameCount;

    // Thread safety
    QMutex _mutex;

    // State
    QJsonArray _detections;
    QByteArray _outputBuffer;
    bool _hasFrame;
};
