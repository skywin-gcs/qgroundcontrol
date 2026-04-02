#include "YoloDetector.h"
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QCoreApplication>
#include <QLoggingCategory>

Q_LOGGING_CATEGORY(YoloDetectorLog, "YoloDetectorLog")

YoloDetector::YoloDetector(QObject* parent)
    : QObject(parent)
{
#ifdef HAVE_OPENCV
    // Look for model in application directory and common locations.
    // Order matters: most specific / most likely first.
    const QString appDir  = QCoreApplication::applicationDirPath();
    const QString cwdDir  = QDir::currentPath();

    QStringList searchPaths = {
        // ── macOS .app bundle ──────────────────────────────────────────────
        // Binary lives at   QGroundControl.app/Contents/MacOS/QGroundControl
        // Resources live at QGroundControl.app/Contents/Resources/
        appDir + "/../Resources/yolov8n.onnx",

        // ── Next to the executable (any platform) ──────────────────────────
        appDir + "/yolov8n.onnx",

        // ── cmake build-release output directory ───────────────────────────
        // build-release/Release/QGroundControl.app/Contents/MacOS  →  go up 4 levels
        appDir + "/../../../../resources/models/yolov8n.onnx",
        // build-release/Release/  →  look in project root
        appDir + "/../../../resources/models/yolov8n.onnx",

        // ── Working directory (running from project root in dev) ───────────
        cwdDir + "/resources/models/yolov8n.onnx",
        cwdDir + "/yolov8n.onnx",

        // ── Fallback: common install / deployment locations ────────────────
        appDir + "/models/yolov8n.onnx",
        cwdDir + "/models/yolov8n.onnx",
    };

    QString modelPath;
    for (const QString& path : searchPaths) {
        if (QFile::exists(path)) {
            modelPath = path;
            break;
        }
    }

    if (modelPath.isEmpty()) {
        qWarning() << "YoloDetector: yolov8n.onnx not found. Searched:" << searchPaths;
        return;
    }

    try {
        m_net = cv::dnn::readNetFromONNX(modelPath.toStdString());

        if (m_net.empty()) {
            qWarning() << "YoloDetector: Failed to load ONNX model from:" << modelPath;
        } else {
            qDebug() << "YoloDetector: Model loaded successfully from:" << modelPath;
            // Prefer CPU for compatibility, can use CUDA if available
            m_net.setPreferableBackend(cv::dnn::DNN_BACKEND_OPENCV);
            m_net.setPreferableTarget(cv::dnn::DNN_TARGET_CPU);
            // Auto-enable detection now that the model is ready.
            // The user can toggle it off via the UI button.
            m_enabled = true;
            qDebug() << "YoloDetector: Detection auto-enabled";
        }
    } catch (const std::exception& e) {
        qWarning() << "YoloDetector: Exception loading model:" << e.what();
    } catch (...) {
        qWarning() << "YoloDetector: Unknown exception loading model";
    }

    // COCO class names (80 classes)
    m_classNames = {
        "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat",
        "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat",
        "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack",
        "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball",
        "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
        "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
        "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake",
        "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop",
        "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
        "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
    };
#else
    qWarning() << "YoloDetector: OpenCV not available, detection disabled";
#endif
}

YoloDetector::~YoloDetector() = default;

void YoloDetector::setEnabled(bool enabled)
{
    QMutexLocker lock(&m_mutex);
    if (m_enabled == enabled) return;
    m_enabled = enabled;
    emit enabledChanged(enabled);
}

void YoloDetector::setConfidenceThreshold(float threshold)
{
    QMutexLocker lock(&m_mutex);
    if (qFuzzyCompare(m_confThreshold, threshold)) return;
    m_confThreshold = threshold;
    emit confidenceThresholdChanged(threshold);
}

void YoloDetector::processFrame(const QImage& frame)
{
#ifdef HAVE_OPENCV
    {
        QMutexLocker lock(&m_mutex);
        if (!m_enabled) return;
        if (frame.isNull()) {
            qCDebug(YoloDetectorLog) << "Frame is null";
            return;
        }
        if (m_net.empty()) {
            qCDebug(YoloDetectorLog) << "Net is empty";
            return;
        }
        if (m_isProcessing) return;
        m_isProcessing = true;
    }

    qCDebug(YoloDetectorLog) << "Processing frame of size" << frame.size();

    cv::Mat rgbFrame = qImageToMat(frame);
    if (rgbFrame.empty()) {
        QMutexLocker lock(&m_mutex);
        m_isProcessing = false;
        return;
    }

    cv::Size originalSize = rgbFrame.size();

    try {
        // Prepare blob for YOLOv8 (640x640 is standard input size)
        cv::Mat blob = cv::dnn::blobFromImage(rgbFrame, 1.0/255.0, cv::Size(640, 640), cv::Scalar(0,0,0), true, false);
        m_net.setInput(blob);

        std::vector<cv::Mat> outputs;
        m_net.forward(outputs, m_net.getUnconnectedOutLayersNames());

        if (!outputs.empty() && !outputs[0].empty()) {
            // YOLOv8 output shape is [1, 84, 8400]
            // We need to transpose it to [8400, 84] to make it easier to process
            cv::Mat output = outputs[0];
            if (output.dims == 3 && output.size[0] == 1) {
                output = cv::Mat(output.size[1], output.size[2], CV_32F, output.ptr<float>());
            }

            cv::Mat transposed;
            cv::transpose(output, transposed);
            output = transposed;

            std::vector<Detection> detections = postProcess(output, m_confThreshold, originalSize);

            QVariantList qmlList = convertDetectionsToQML(detections);
            emit detectionsUpdated(qmlList);
        }
    } catch (const std::exception& e) {
        qWarning() << "YoloDetector: Exception during inference:" << e.what();
    } catch (...) {
        qWarning() << "YoloDetector: Unknown exception during inference";
    }

    {
        QMutexLocker lock(&m_mutex);
        m_isProcessing = false;
    }
#else
    Q_UNUSED(frame)
#endif
}

#ifdef HAVE_OPENCV
cv::Mat YoloDetector::qImageToMat(const QImage& image)
{
    if (image.isNull()) return cv::Mat();

    QImage converted = image;

    // Convert to RGB888 format if needed
    if (image.format() != QImage::Format_RGB888) {
        if (image.format() == QImage::Format_ARGB32 || image.format() == QImage::Format_ARGB32_Premultiplied) {
            converted = image.convertToFormat(QImage::Format_RGB888);
        } else if (image.format() == QImage::Format_RGBA8888) {
            converted = image.convertToFormat(QImage::Format_RGB888);
        } else {
            converted = image.convertToFormat(QImage::Format_RGB888);
        }
    }

    // QImage is stored as (R, G, B) but OpenCV expects (B, G, R)
    cv::Mat mat(converted.height(), converted.width(), CV_8UC3, (void*)converted.constBits(), converted.bytesPerLine());
    cv::Mat rgbMat;
    cv::cvtColor(mat, rgbMat, cv::COLOR_RGB2BGR);

    return rgbMat.clone();  // Clone to ensure data ownership
}

std::vector<Detection> YoloDetector::postProcess(const cv::Mat& output, float confThreshold, const cv::Size& originalSize)
{
    std::vector<Detection> detections;

    // YOLOv8 output shape after transpose: [8400, 84]
    // 8400 = number of predictions (grid points)
    // 84 = 4 bbox coords + 80 class scores

    int rows = output.rows;  // 8400
    int cols = output.cols;  // 84

    if (rows <= 0 || cols < 4) return detections;

    float xFactor = static_cast<float>(originalSize.width) / 640.0f;
    float yFactor = static_cast<float>(originalSize.height) / 640.0f;

    std::vector<cv::Rect> boxes;
    std::vector<float> scores;
    std::vector<int> classIds;

    for (int i = 0; i < rows; ++i) {
        // Get class scores (skip first 4 bbox values)
        const float* rowData = output.ptr<float>(i);
        const float* classesScores = rowData + 4;

        // Find max class score
        cv::Mat scoresMat(1, cols - 4, CV_32FC1, (void*)classesScores);
        cv::Point classIdPoint;
        double maxClassScore;
        cv::minMaxLoc(scoresMat, nullptr, &maxClassScore, nullptr, &classIdPoint);

        if (maxClassScore > confThreshold) {
            // Get bounding box (center_x, center_y, width, height)
            float cx = rowData[0];
            float cy = rowData[1];
            float w = rowData[2];
            float h = rowData[3];

            // Convert to corner coordinates
            int left = static_cast<int>((cx - 0.5f * w) * xFactor);
            int top = static_cast<int>((cy - 0.5f * h) * yFactor);
            int width = static_cast<int>(w * xFactor);
            int height = static_cast<int>(h * yFactor);

            boxes.emplace_back(left, top, width, height);
            scores.push_back(static_cast<float>(maxClassScore));
            classIds.push_back(classIdPoint.x);
        }
    }

    // Non-Maximum Suppression
    std::vector<int> nmsIndices;
    float nmsThreshold = 0.45f;
    cv::dnn::NMSBoxes(boxes, scores, confThreshold, nmsThreshold, nmsIndices);

    for (int idx : nmsIndices) {
        Detection d;
        d.className = QString::fromStdString(m_classNames[classIds[idx]]);
        d.confidence = scores[idx];
        d.x1 = boxes[idx].x;
        d.y1 = boxes[idx].y;
        d.x2 = boxes[idx].x + boxes[idx].width;
        d.y2 = boxes[idx].y + boxes[idx].height;
        d.centerX = boxes[idx].x + boxes[idx].width / 2;
        d.centerY = boxes[idx].y + boxes[idx].height / 2;
        detections.push_back(d);
    }

    return detections;
}
#endif

QVariantList YoloDetector::convertDetectionsToQML(const std::vector<Detection>& detections)
{
    QVariantList list;
    for (const auto& d : detections) {
        QVariantMap map;
        map["className"] = d.className;
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
