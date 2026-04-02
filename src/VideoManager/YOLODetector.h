#pragma once

#include <QtCore/QObject>
#include <QtCore/QVariantList>
#include <QtCore/QThread>
#include <QtCore/QMutex>
#include <QtGui/QImage>
#include <vector>
#include <string>

// Conditional OpenCV includes
#ifdef HAVE_OPENCV
#include <opencv2/dnn.hpp>
#include <opencv2/imgproc.hpp>
#endif

struct Detection {
    QString className;
    float confidence;
    int x1, y1, x2, y2;
    int centerX, centerY;
};

#include <QtQmlIntegration/QtQmlIntegration>

class YoloDetector : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("YoloDetector is exposed via VideoManager")
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(float confidenceThreshold READ confidenceThreshold WRITE setConfidenceThreshold NOTIFY confidenceThresholdChanged)

public:
    explicit YoloDetector(QObject* parent = nullptr);
    ~YoloDetector();

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    float confidenceThreshold() const { return m_confThreshold; }
    void setConfidenceThreshold(float threshold);

public slots:
    // Process frame from VideoReceiver (QImage format)
    void processFrame(const QImage& frame);

signals:
    void enabledChanged(bool enabled);
    void confidenceThresholdChanged(float threshold);
    void detectionsUpdated(const QVariantList& detections);   // List of QVariantMap

private:
    bool m_enabled = false;
    float m_confThreshold = 0.45f;
    std::vector<std::string> m_classNames;

    QMutex m_mutex;
    bool m_isProcessing = false;

#ifdef HAVE_OPENCV
    cv::dnn::Net m_net;
    cv::Mat qImageToMat(const QImage& image);
    std::vector<Detection> postProcess(const cv::Mat& output, float confThreshold, const cv::Size& originalSize);
#endif

    QVariantList convertDetectionsToQML(const std::vector<Detection>& detections);
};
