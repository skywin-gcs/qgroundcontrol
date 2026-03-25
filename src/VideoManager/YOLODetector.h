#pragma once

#include <QtCore/QObject>
#include <QtCore/QVariantList>
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

class YoloDetector : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(float confidenceThreshold READ confidenceThreshold WRITE setConfidenceThreshold NOTIFY confidenceThresholdChanged)

public:
    explicit YoloDetector(QObject* parent = nullptr);
    ~YoloDetector();

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    float confidenceThreshold() const { return m_confThreshold; }
    void setConfidenceThreshold(float threshold);

    // Call this every new frame from GStreamer
#ifdef HAVE_OPENCV
    void processFrame(const cv::Mat& rgbFrame);
#else
    void processFrame(void* rgbFrame);
#endif

signals:
    void enabledChanged(bool enabled);
    void confidenceThresholdChanged(float threshold);
    void detectionsUpdated(const QVariantList& detections);   // List of QVariantMap

private:
    bool m_enabled = false;
    float m_confThreshold = 0.45f;
    std::vector<std::string> m_classNames;

#ifdef HAVE_OPENCV
    cv::dnn::Net m_net;
#endif

    QVariantList convertDetectionsToQML(const std::vector<Detection>& detections);
};
