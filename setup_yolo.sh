#!/bin/bash

# YOLO Setup Script for QGroundControl
echo "Setting up YOLO for QGroundControl..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

# Install required Python packages
echo "Installing Python dependencies..."
pip3 install ultralytics numpy

# Check if YOLO model exists, download if not
MODEL_PATH="$HOME/Dev/qgroundcontrol/yolov8n.pt"
if [ ! -f "$MODEL_PATH" ]; then
    echo "Downloading YOLOv8n model..."
    python3 -c "
from ultralytics import YOLO
model = YOLO('yolov8n.pt')
print('Model downloaded successfully')
"
fi

# Make the Python script executable
chmod +x "$HOME/Dev/qgroundcontrol/yolo_processor.py"

echo "YOLO setup complete!"
echo "Model path: $MODEL_PATH"
echo "Python script: $HOME/Dev/qgroundcontrol/yolo_processor.py"
