#!/bin/bash

echo "🔄 Reverting Code Modifications"
echo "================================="

cd /Users/elisabeth/Dev/qgroundcontrol

# 1. Remove DetectionSystem includes and code from VideoManager.cc
echo "1. Cleaning VideoManager.cc..."
# Create clean version without detection system
cat > src/VideoManager/VideoManager.cc.clean << 'EOF'
#include "VideoManager.h"
#include "QGCApplication.h"
#include "QGCCameraManager.h"
#include "QGCCorePlugin.h"
#include "QGCLoggingCategory.h"
#include "SettingsManager.h"
#include "SubtitleWriter.h"
#include "Vehicle.h"
#include "VideoReceiver.h"
#include "VideoSettings.h"
#ifdef QGC_GST_STREAMING
#include "GStreamer.h"
#include "VideoItemStub.h"
#else
#include "VideoItemStub.h"
#endif
#include <QtCore/QApplicationStatic>
#include <QtCore/QDir>
#include <QtCore/QTimer>
#include <QtQml/QQmlEngine>

QGC_LOGGING_CATEGORY(VideoManagerLog, "Video.VideoManager")

static constexpr const char* kFileExtension[VideoReceiver::FILE_FORMAT_MAX + 1] = {"mkv", "mov", "mp4"};

Q_APPLICATION_STATIC(VideoManager, _videoManagerInstance);

VideoManager::VideoManager(QObject* parent)
    : QObject(parent),
      _subtitleWriter(new SubtitleWriter(this)),
      _videoSettings(SettingsManager::instance()->videoSettings())
{
    qCDebug(VideoManagerLog) << this;

    (void)qRegisterMetaType<VideoReceiver::STATUS>("STATUS");

#ifdef QGC_GST_STREAMING
    const bool skipGStreamerForUnitTests =
        qgcApp() && qgcApp()->runningUnitTests() && !qEnvironmentVariableIsSet("QGC_TEST_ENABLE_GSTREAMER");

    if (skipGStreamerForUnitTests) {
        qCDebug(VideoManagerLog) << "Skipping GStreamer initialization for unit tests";
        return;
    }

    //-- Initialize GStreamer
    QGCCorePlugin::instance()->preGStreamerInit();

    if (!QGC::gstreamerInit()) {
        qCWarning(VideoManagerLog) << "Error initializing GStreamer";
    } else {
        qCDebug(VideoManagerLog) << "GStreamer initialized";
    }
#endif
}

VideoManager::~VideoManager()
{
    _videoReceivers.clear();
}

VideoManager* VideoManager::instance()
{
    return _videoManagerInstance;
}

void VideoManager::init(QQuickWindow* mainWindow)
{
    _mainWindow = mainWindow;
}

void VideoManager::_initAfterQmlIsReady()
{
    if (_initialized) {
        return;
    }
    _initialized = true;
}

void VideoManager::startVideo()
{
    if (!_videoSettings->videoSource()->rawValue().toString().isEmpty()) {
        qCDebug(VideoManagerLog) << "Starting video" << _videoSettings->videoSource()->rawValue();
        _restartAllVideos();
    }
}

void VideoManager::stopVideo()
{
    qCDebug(VideoManagerLog) << "Stopping video";
    for (auto& receiver : _videoReceivers) {
        _stopReceiver(receiver);
    }
}

void VideoManager::grabImage(const QString& imageFile)
{
    QString finalImageFile = imageFile;
    if (finalImageFile.isEmpty()) {
        finalImageFile = QDir::temp().filePath("QGCImage.jpg");
    }
    for (auto& receiver : _videoReceivers) {
        receiver->grabImage(finalImageFile);
    }
}

void VideoManager::startRecording(const QString& videoFile)
{
    QString finalVideoFile = videoFile;
    if (finalVideoFile.isEmpty()) {
        finalVideoFile = videoFileForCurrentTime();
    }
    for (auto& receiver : _videoReceivers) {
        receiver->startRecording(finalVideoFile);
    }
}

void VideoManager::stopRecording()
{
    for (auto& receiver : _videoReceivers) {
        receiver->stopRecording();
    }
}

void VideoManager::_initVideoReceiver(VideoReceiver* receiver, QQuickWindow* window)
{
    if (!receiver) {
        return;
    }

    receiver->setParent(this);

    (void)connect(receiver, &VideoReceiver::timeout, this, &VideoManager::_receiverTimeout);
    (void)connect(receiver, &VideoReceiver::recordingStarted, this, &VideoManager::recordingStarted);
    (void)connect(receiver, &VideoReceiver::recordingEnded, this, &VideoManager::recordingEnded);
    (void)connect(receiver, &VideoReceiver::streamingChanged, this, &VideoManager::streamingChanged);
    (void)connect(receiver, &VideoReceiver::decodingChanged, this, &VideoManager::decodingChanged);

    (void)_updateAutoStream(receiver);

    (void)_updateSettings(receiver);

    _videoReceivers.append(receiver);

    if (hasVideo()) {
        _startReceiver(receiver);
    }
}

void VideoManager::_restartAllVideos()
{
    for (auto& receiver : _videoReceivers) {
        _restartVideo(receiver);
    }
}

void VideoManager::_restartVideo(VideoReceiver* receiver)
{
    if (!receiver) {
        return;
    }

    _stopReceiver(receiver);
    _startReceiver(receiver);
}

void VideoManager::_startReceiver(VideoReceiver* receiver)
{
    if (!receiver) {
        return;
    }

    if (_mainWindow) {
        receiver->setVideoWindow(_mainWindow);
    }

    const QString& uri = _videoSettings->videoSource()->rawValue().toString();
    if (!uri.isEmpty()) {
        receiver->start(uri);
    }
}

void VideoManager::_stopReceiver(VideoReceiver* receiver)
{
    if (!receiver) {
        return;
    }

    receiver->stop();
}

QString VideoManager::videoFileForCurrentTime()
{
    return QDir::temp().filePath(QString("QGC_%1.mp4").arg(QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm-ss-zzz")));
}

bool VideoManager::_updateAutoStream(VideoReceiver* receiver)
{
    if (!receiver || !_videoSettings) {
        return false;
    }

    return receiver->setAutoStreamMode(_videoSettings->autoStreamMode());
}

bool VideoManager::_updateUVC(VideoReceiver* receiver)
{
    if (!receiver || !_videoSettings) {
        return false;
    }

    return receiver->setUVC(_videoSettings->uvcVideoSourceID()->rawValue().toString());
}

bool VideoManager::_updateSettings(VideoReceiver* receiver)
{
    if (!receiver || !_videoSettings) {
        return false;
    }

    return receiver->setVideoDecoder(_videoSettings->videoDecoder());
}

bool VideoManager::_updateVideoUri(VideoReceiver* receiver, const QString& uri)
{
    if (!receiver) {
        return false;
    }

    return receiver->setUri(uri);
}

void VideoManager::_receiverTimeout()
{
    qCWarning(VideoManagerLog) << "Video receiver timeout";
}

void VideoManager::_cleanupOldVideos()
{
    // Implementation needed
}

bool VideoManager::hasVideo()
{
    return !_videoReceivers.isEmpty();
}

bool VideoManager::isRecording()
{
    return _recording;
}

bool VideoManager::isStreaming()
{
    return _streaming;
}

bool VideoManager::loopVideo()
{
    return _loopVideo;
}

bool VideoManager::recordingFileExists() const
{
    return false; // TODO: Implement
}

bool VideoManager::recordingFileReady() const
{
    return false; // TODO: Implement
}

bool VideoManager::thermalVisible() const
{
    return _thermalVisible;
}

QString VideoManager::imageFile() const
{
    return _imageFile;
}

QString VideoManager::uvcVideoSourceID() const
{
    return _uvcVideoSourceID;
}

double VideoManager::aspectRatio() const
{
    return _aspectRatio;
}

double VideoManager::hfov() const
{
    return _hfov;
}

double VideoManager::thermalAspectRatio() const
{
    return _thermalAspectRatio;
}

double VideoManager::thermalHfov() const
{
    return _thermalHfov;
}

QSize VideoManager::videoSize() const
{
    return _videoSize;
}

bool VideoManager::fullScreen()
{
    return _fullScreen;
}

void VideoManager::setLoopVideo(bool loop)
{
    if (_loopVideo != loop) {
        _loopVideo = loop;
        emit loopVideoChanged();
    }
}

void VideoManager::setThermalVisible(bool visible)
{
    if (_thermalVisible != visible) {
        _thermalVisible = visible;
        emit thermalVisibleChanged();
    }
}

void VideoManager::setfullScreen(bool on)
{
    if (_fullScreen != on) {
        _fullScreen = on;
        emit fullScreenChanged();
    }
}
EOF

# 2. Create clean VideoManager.h
echo "2. Cleaning VideoManager.h..."
cat > src/VideoManager/VideoManager.h.clean << 'EOF'
#pragma once

#include <QtCore/QObject>
#include <QtCore/QSize>
#include <QtCore/QString>
#include <QtCore/QTimer>
#include <QtGui/QImage>
#include <QtQuick/QQuickWindow>

Q_DECLARE_LOGGING_CATEGORY(VideoManagerLog)

// Forward declarations only (no full includes here to avoid cycles)
class QQuickWindow;
class FinishVideoInitialization;
class SubtitleWriter;
class Vehicle;
class VideoReceiver;
class VideoSettings;

class VideoManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")

    Q_MOC_INCLUDE("Vehicle.h")

    // Properties
    Q_PROPERTY(bool gstreamerEnabled READ gstreamerEnabled CONSTANT)
    Q_PROPERTY(bool qtmultimediaEnabled READ qtmultimediaEnabled CONSTANT)
    Q_PROPERTY(bool uvcEnabled READ uvcEnabled CONSTANT)
    Q_PROPERTY(bool autoStreamConfigured READ autoStreamConfigured NOTIFY autoStreamConfiguredChanged)
    Q_PROPERTY(bool decoding READ decoding NOTIFY decodingChanged)
    Q_PROPERTY(bool fullScreen READ fullScreen WRITE setfullScreen NOTIFY fullScreenChanged)
    Q_PROPERTY(bool hasThermal READ hasThermal NOTIFY decodingChanged)
    Q_PROPERTY(bool hasVideo READ hasVideo NOTIFY hasVideoChanged)
    Q_PROPERTY(bool isRecording READ isRecording NOTIFY isRecordingChanged)
    Q_PROPERTY(bool isStreaming READ isStreaming NOTIFY isStreamingChanged)
    Q_PROPERTY(bool loopVideo READ loopVideo WRITE setLoopVideo NOTIFY loopVideoChanged)
    Q_PROPERTY(bool recordingFileExists READ recordingFileExists NOTIFY recordingFileExistsChanged)
    Q_PROPERTY(bool recordingFileReady READ recordingFileReady NOTIFY recordingFileReadyChanged)
    Q_PROPERTY(bool thermalVisible READ thermalVisible WRITE setThermalVisible NOTIFY thermalVisibleChanged)
    Q_PROPERTY(double aspectRatio READ aspectRatio NOTIFY aspectRatioChanged)
    Q_PROPERTY(double hfov READ hfov NOTIFY aspectRatioChanged)
    Q_PROPERTY(double thermalAspectRatio READ thermalAspectRatio NOTIFY aspectRatioChanged)
    Q_PROPERTY(double thermalHfov READ thermalHfov NOTIFY aspectRatioChanged)
    Q_PROPERTY(QSize videoSize READ videoSize NOTIFY videoSizeChanged)
    Q_PROPERTY(QString imageFile READ imageFile NOTIFY imageFileChanged)
    Q_PROPERTY(QString uvcVideoSourceID READ uvcVideoSourceID NOTIFY uvcVideoSourceIDChanged)

public:
    explicit VideoManager(QObject* parent = nullptr);
    ~VideoManager();

    friend class FinishVideoInitialization;

    static VideoManager* instance();

    // QML-callable methods
    Q_INVOKABLE void grabImage(const QString& imageFile = QString());
    Q_INVOKABLE void startRecording(const QString& videoFile = QString());
    Q_INVOKABLE void startVideo();
    Q_INVOKABLE void stopRecording();
    Q_INVOKABLE void stopVideo();

    void init(QQuickWindow* mainWindow);

    // Property getters
    static bool gstreamerEnabled();
    static bool qtmultimediaEnabled();
    static bool uvcEnabled();

    bool hasVideo();
    bool isRecording() const;
    bool isStreaming() const;
    bool loopVideo() const;
    bool recordingFileExists() const;
    bool recordingFileReady() const;
    bool thermalVisible() const;
    QString imageFile() const;
    QString uvcVideoSourceID() const;
    double aspectRatio() const;
    double hfov() const;
    double thermalAspectRatio() const;
    double thermalHfov() const;
    QSize videoSize() const;
    bool fullScreen();

    // Property setters
    void setLoopVideo(bool loop);
    void setThermalVisible(bool visible);
    void setfullScreen(bool on);

signals:
    void aspectRatioChanged();
    void autoStreamConfiguredChanged();
    void decodingChanged();
    void fullScreenChanged();
    void hasVideoChanged();
    void imageFileChanged(const QString& filename);
    void isAutoStreamChanged();
    void isRecordingChanged();
    void isStreamingChanged();
    void loopVideoChanged();
    void recordingFileExistsChanged();
    void recordingFileReadyChanged();
    void streamingChanged();
    void thermalVisibleChanged();
    void uvcVideoSourceIDChanged();
    void videoSizeChanged();

private slots:
    void _initAfterQmlIsReady();
    void _initVideoReceiver(VideoReceiver* receiver, QQuickWindow* window);
    bool _updateAutoStream(VideoReceiver* receiver);
    bool _updateUVC(VideoReceiver* receiver);
    bool _updateSettings(VideoReceiver* receiver);
    bool _updateVideoUri(VideoReceiver* receiver, const QString& uri);
    void _restartAllVideos();
    void _restartVideo(VideoReceiver* receiver);
    void _startReceiver(VideoReceiver* receiver);
    void _stopReceiver(VideoReceiver* receiver);
    static void _cleanupOldVideos();
    void _receiverTimeout();

private:
    QList<VideoReceiver*> _videoReceivers;

    SubtitleWriter* _subtitleWriter = nullptr;
    VideoSettings* _videoSettings = nullptr;

    bool _initialized = false;
    bool _initAfterQmlIsReadyDone = false;
    bool _fullScreen = false;
    bool _loopVideo = false;
    bool _thermalVisible = false;
    QAtomicInteger<bool> _decoding = false;
    QAtomicInteger<bool> _recording = false;
    QAtomicInteger<bool> _streaming = false;
    QSize _videoSize;
    QString _imageFile;
    QString _uvcVideoSourceID;
    double _aspectRatio = 0.0;
    double _hfov = 0.0;
    double _thermalAspectRatio = 0.0;
    double _thermalHfov = 0.0;
    QQuickWindow* _mainWindow = nullptr;
};
EOF

echo "✅ Code cleanup complete!"
echo "================================="
