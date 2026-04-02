#pragma once

#include <QtCore/QLoggingCategory>
#include <QtCore/QObject>
#include <QtCore/QRunnable>
#include <QtCore/QSize>
#include <QtQmlIntegration/QtQmlIntegration>
// Add near top with other includes
#include "YoloDetector.h"

// Inside class VideoManager:


// Forward declarations only (no full includes here to avoid cycles)
class QQuickWindow;
class FinishVideoInitialization;
class SubtitleWriter;
class Vehicle;
class VideoReceiver;
class VideoSettings;

// class YoloInference;  // uncomment only if needed, and include full header in .cpp

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
    Q_PROPERTY(bool isStreamSource READ isStreamSource NOTIFY isStreamSourceChanged)
    Q_PROPERTY(bool isUvc READ isUvc NOTIFY isUvcChanged)
    Q_PROPERTY(bool recording READ recording NOTIFY recordingChanged)
    Q_PROPERTY(bool streaming READ streaming NOTIFY streamingChanged)
    Q_PROPERTY(double aspectRatio READ aspectRatio NOTIFY aspectRatioChanged)
    Q_PROPERTY(double hfov READ hfov NOTIFY aspectRatioChanged)
    Q_PROPERTY(double thermalAspectRatio READ thermalAspectRatio NOTIFY aspectRatioChanged)
    Q_PROPERTY(double thermalHfov READ thermalHfov NOTIFY aspectRatioChanged)
    Q_PROPERTY(QSize videoSize READ videoSize NOTIFY videoSizeChanged)
    Q_PROPERTY(QString imageFile READ imageFile NOTIFY imageFileChanged)
    Q_PROPERTY(QString uvcVideoSourceID READ uvcVideoSourceID NOTIFY uvcVideoSourceIDChanged)
    Q_PROPERTY(YoloDetector* yoloDetector READ yoloDetector CONSTANT)
    Q_PROPERTY(QVariantList detections READ detections NOTIFY detectionsUpdated)
    Q_PROPERTY(QVariantList videoReceivers READ videoReceivers CONSTANT)

public:
    explicit VideoManager(QObject* parent = nullptr);
    ~VideoManager();

    friend class FinishVideoInitialization;

    static VideoManager* instance();

    YoloDetector* yoloDetector() { return m_yoloDetector; }
    QVariantList detections() const { return _detections; }
    QVariantList videoReceivers() const;

    // QML-callable methods
    Q_INVOKABLE void grabImage(const QString& imageFile = QString());
    Q_INVOKABLE void startRecording(const QString& videoFile = QString());
    Q_INVOKABLE void startVideo();
    Q_INVOKABLE void stopRecording();
    Q_INVOKABLE void stopVideo();

    /// Called from FlightDisplayViewUVC.qml to connect the QML VideoOutput's
    /// internal QVideoSink to the YOLO detector.  videoOutputItem must be the
    /// QML VideoOutput object (QQuickVideoOutput in C++).
    Q_INVOKABLE void connectUVCToYolo(QObject* videoOutputItem);

    /// Disconnect the UVC → YOLO bridge (called when camera goes inactive).
    Q_INVOKABLE void disconnectUVCFromYolo();

    void init(QQuickWindow* mainWindow);
    void cleanup();

    bool autoStreamConfigured() const;

    bool decoding() const
    {
        return _decoding;
    }

    bool fullScreen() const
    {
        return _fullScreen;
    }

    bool hasThermal() const;
    bool hasVideo() const;
    bool isStreamSource() const;
    bool isUvc() const;

    bool recording() const
    {
        return _recording;
    }

    bool streaming() const
    {
        return _streaming;
    }

    double aspectRatio() const;
    double hfov() const;
    double thermalAspectRatio() const;
    double thermalHfov() const;

    QSize videoSize() const
    {
        return _videoSize;
    }

    QString imageFile() const
    {
        return _imageFile;
    }

    QString uvcVideoSourceID() const
    {
        return _uvcVideoSourceID;
    }

    void setfullScreen(bool on);
    void onDetectionsUpdated(const QVariantList& detections);

    /// Set the decoding/streaming flags from external sources (e.g. UVC path).
    void setDecodingActive(bool active);
    void setStreamingActive(bool active);

    static bool gstreamerEnabled();
    static bool qtmultimediaEnabled();
    static bool uvcEnabled();

signals:
    void aspectRatioChanged();
    void autoStreamConfiguredChanged();
    void decodingChanged();
    void fullScreenChanged();
    void hasVideoChanged();
    void imageFileChanged(const QString& filename);
    void isAutoStreamChanged();
    void isStreamSourceChanged();
    void isUvcChanged();
    void recordingChanged(bool recording);
    void recordingStarted(const QString& filename);
    void streamingChanged();
    void uvcVideoSourceIDChanged();
    void videoSizeChanged();
    void detectionsUpdated(const QVariantList& detections);
private slots:
    void _communicationLostChanged(bool communicationLost);
    void _setActiveVehicle(Vehicle* vehicle);
    void _videoSourceChanged();

private:
    YoloDetector* m_yoloDetector = nullptr;
    QMetaObject::Connection m_uvcYoloConnection;   ///< UVC camera → YOLO bridge
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

    QList<VideoReceiver*> _videoReceivers;

    SubtitleWriter* _subtitleWriter = nullptr;
    VideoSettings* _videoSettings = nullptr;

    bool _initialized = false;
    bool _initAfterQmlIsReadyDone = false;
    bool _fullScreen = false;
    QAtomicInteger<bool> _decoding = false;
    QAtomicInteger<bool> _recording = false;
    QAtomicInteger<bool> _streaming = false;
    QSize _videoSize;
    QString _imageFile;
    QString _uvcVideoSourceID;
    QVariantList _detections;
    Vehicle* _activeVehicle = nullptr;
    QQuickWindow* _mainWindow = nullptr;
};

Q_DECLARE_LOGGING_CATEGORY(VideoManagerLog)

/*===========================================================================*/

class FinishVideoInitialization : public QRunnable
{
public:
    FinishVideoInitialization();
    ~FinishVideoInitialization();

    void run() final;
};
