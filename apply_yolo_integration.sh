#!/bin/bash

echo "🔧 Apply YOLO Integration"
echo "=========================="

# 1. Update CMakeLists.txt
echo "1. Adding YOLODetector to CMakeLists.txt..."
cat > src/VideoManager/CMakeLists.txt << 'EOF'
# ============================================================================
# Video Manager Module
# Handles video streaming and subtitle generation
# ============================================================================

target_sources(QGroundControl PRIVATE
    SubtitleWriter.cc
    SubtitleWriter.h
    VideoManager.cc
    YOLODetector.cc
    YOLODetector.h
)

target_include_directories(QGroundControl PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# ----------------------------------------------------------------------------
# Video Receiver Subsystem
# ----------------------------------------------------------------------------
add_subdirectory(VideoReceiver)
EOF

# 2. Update VideoManager.h
echo "2. Adding YOLODetector to VideoManager.h..."
cp src/VideoManager/VideoManager.h src/VideoManager/VideoManager.h.backup

# Add YOLODetector include and property
sed -i '' '/class VideoSettings;/a\
class YOLODetector;' src/VideoManager/VideoManager.h

sed -i '' '/Q_PROPERTY(QString uvcVideoSourceID/a\
    Q_PROPERTY(YOLODetector* yoloDetector READ yoloDetector CONSTANT)' src/VideoManager/VideoManager.h

sed -i '' '/VideoSettings\* _videoSettings = nullptr;/a\
    YOLODetector* _yoloDetector = nullptr;' src/VideoManager/VideoManager.h

# Add getter method
sed -i '' '/QString uvcVideoSourceID() const;/a\
    YOLODetector* yoloDetector() const { return _yoloDetector; }' src/VideoManager/VideoManager.h

# 3. Update VideoManager.cc
echo "3. Adding YOLODetector to VideoManager.cc..."
cp src/VideoManager/VideoManager.cc src/VideoManager/VideoManager.cc.backup

# Add include
sed -i '' '/#include "VideoSettings.h"/a\
#include "YOLODetector.h"' src/VideoManager/VideoManager.cc

# Add initialization
sed -i '' 's/_videoSettings(SettingsManager::instance()->videoSettings())/_videoSettings(SettingsManager::instance()->videoSettings()),\
      _yoloDetector(new YOLODetector(this))/' src/VideoManager/VideoManager.cc

# Add connection to rgbFrameReady signal
sed -i '' '/#ifdef QGC_GST_STREAMING/,/#endif/{
    /#endif/i\
    \
    // Connect YOLO detector on main (non-thermal) stream only\
    if (_yoloDetector && receiver && !receiver->isThermal()) {\
        qWarning() << "VideoManager: Connecting YOLO detector to receiver";\
        if (auto gstReceiver = qobject_cast<GstVideoReceiver*>(receiver)) {\
            qWarning() << "VideoManager: Found GstVideoReceiver, connecting rgbFrameReady signal";\
            (void)connect(gstReceiver, &GstVideoReceiver::rgbFrameReady,\
                          _yoloDetector, &YOLODetector::processFrameBytes,\
                          Qt::QueuedConnection);\
        } else {\
            qWarning() << "VideoManager: Receiver is not a GstVideoReceiver";\
        }\
    } else {\
        if (!_yoloDetector) {\
            qWarning() << "VideoManager: No YOLO detector available";\
        } else if (!receiver) {\
            qWarning() << "VideoManager: No receiver provided";\
        } else if (receiver->isThermal()) {\
            qWarning() << "VideoManager: Receiver is thermal, skipping YOLO";\
        }\
    }
}' src/VideoManager/VideoManager.cc

echo "✅ YOLO integration complete!"
echo "=========================="
echo ""
echo "Next steps:"
echo "1. Download YOLO model: python3 -c \"from ultralytics import YOLO; YOLO('yolov8n.pt')\""
echo "2. Build project: cd build && make"
echo "3. Test detection in QGroundControl"
