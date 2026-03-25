#!/bin/bash

echo "🧹 Complete YOLO Cleanup Script"
echo "================================="

# 1. Remove YOLO-related files from root
echo "1. Removing YOLO files from root..."
cd /Users/elisabeth/Dev/qgroundcontrol
rm -f download_yolo_model.sh
rm -f yolo11n.pt
rm -f test_simple_yolo.py
rm -f test_yolo_integration.sh
rm -rf yolo_data_2026-03-19/

# 2. Remove detection test files
echo "2. Removing detection test files..."
rm -f test_detection.py
rm -f test_detection_standalone.py
rm -f test_real_detection.py
rm -f test_opencv_detection.py
rm -f test_complete_detection.py
rm -f test_detection_ready.sh
rm -f test_simple_processor.py
rm -f test_detection.jpg

# 3. Remove Python scripts from VideoReceiver
echo "3. Removing Python detection scripts..."
rm -f src/VideoManager/VideoReceiver/SimpleDetector.py
rm -f src/VideoManager/VideoReceiver/VideoProcessor.py
rm -f src/VideoManager/VideoReceiver/VideoProcessorSimple.py
rm -rf src/VideoManager/VideoReceiver/__pycache__/

# 4. Remove DetectionSystem files (if they exist)
echo "4. Removing DetectionSystem files..."
rm -f src/VideoManager/DetectionSystem.h
rm -f src/VideoManager/DetectionSystem.cc

# 5. Remove Qt fix scripts
echo "5. Removing Qt fix scripts..."
rm -f fix_qt_version.sh
rm -f fix_qt_comprehensive.sh
rm -f fix_qt_qt5.sh
rm -f Dockerfile

echo "✅ File cleanup complete!"
echo "================================="
