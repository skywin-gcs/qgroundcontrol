#include "YOLODetector.h"
#include <QDebug>
#include <QFile>

YoloDetector::YoloDetector(QObject* parent)
    : QObject(parent)
{
#ifdef HAVE_OPENCV
    // Put your YOLO ONNX model next to the executable or in Resources
    QString modelPath = "yolov8n.onnx";   // ← Change this to your exported ONNX model

    m_net = cv::dnn::readNetFromONNX(modelPath.toStdString());

    if (m_net.empty()) {
        qWarning() << "YoloDetector: Failed to load ONNX model!";
    } else {
        qDebug() << "YoloDetector: Model loaded successfully";
    }

    // Basic COCO class names (add your custom classes if needed)
    m_classNames = {"person", "bicycle", "car", "motorcycle", "airplane", "bus", "train",
                    "truck", "boat", "traffic light", "drone", "bird", "cat", "dog"};
#else
    qWarning() << "YoloDetector: OpenCV not available, detection disabled";
#endif
}

YoloDetector::~YoloDetector() = default;

void YoloDetector::setEnabled(bool enabled)
{
    if (m_enabled == enabled) return;
    m_enabled = enabled;
    emit enabledChanged(enabled);
}

void YoloDetector::setConfidenceThreshold(float threshold)
{
    if (qFuzzyCompare(m_confThreshold, threshold)) return;
    m_confThreshold = threshold;
    emit confidenceThresholdChanged(threshold);
}

#ifdef HAVE_OPENCV
void YoloDetector::processFrame(const cv::Mat& rgbFrame)
{
    if (!m_enabled || rgbFrame.empty() || m_net.empty()) return;

    // Prepare blob for YOLOv8 (640x640 is standard)
    cv::Mat blob = cv::dnn::blobFromImage(rgbFrame, 1/255.0, cv::Size(640, 640), cv::Scalar(0,0,0), true, false);
    m_net.setInput(blob);

    std::vector<cv::Mat> outputs;
    m_net.forward(outputs, m_net.getUnconnectedOutLayersNames());

    // TODO: Add proper YOLOv8 post-processing here (I'll give full version next if you want)
    // For now, placeholder - we'll fill this properly once basic integration works

    std::vector<Detection> detections;
    // ... post-processing code will go here ...

    QVariantList qmlList = convertDetectionsToQML(detections);
    emit detectionsUpdated(qmlList);
}
#else
void YoloDetector::processFrame(void* rgbFrame)
{
    Q_UNUSED(rgbFrame)
}
#endif

QVariantList YoloDetector::convertDetectionsToQML(const std::vector<Detection>& detections)
{
    QVariantList list;
    for (const auto& d : detections) {
        QVariantMap map;
        map["class"] = d.className;
        map["confidence"] = d.confidence;
        map["x1"] = d.x1;
        map["y1"] = d.y1;
        map["x2"] = d.x2;
        map["y2"] = d.y2;
        map["centerX"] = d.centerX;
        map["centerY"] = d.centerY;
        list << map;
    }
    return list;
}
