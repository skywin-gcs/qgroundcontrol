#!/usr/bin/env python3
"""
YOLO Processor for QGroundControl
Receives raw frames from stdin via pipe, runs YOLO detection, outputs JSON to stdout
"""
import os
import sys
import json
import struct
import cv2
import numpy as np

# Set environment variable to handle OpenMP issues
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'

# Import YOLO with error handling
try:
    from ultralytics import YOLO
except ImportError as e:
    print(f"Failed to import YOLO from ultralytics: {e}", file=sys.stderr)
    sys.exit(1)

class YOLOProcessor:
    def __init__(self):
        self.model = YOLO('yolov8n.pt')  # Use YOLOv8n for speed
        self.frame_count = 0
        self.total_detections = 0

        print("YOLO processor started, waiting for frames...", file=sys.stderr)

    def process_frame(self, frame_data):
        """Process a single frame and return detection results"""
        try:
            # Decode frame
            frame = cv2.imdecode(np.frombuffer(frame_data, np.uint8), cv2.IMREAD_COLOR)
            if frame is None:
                return []

            # Run YOLO detection
            results = self.model(frame, conf=0.25, verbose=False)[0]

            # Process detections
            detections = []
            if results.boxes is not None:
                for box in results.boxes:
                    x1, y1, x2, y2 = box.xyxy[0].tolist()
                    conf = box.conf[0].item()
                    cls = int(box.cls[0].item())

                    detection = {
                        'class': self.model.names[cls],
                        'class_id': cls,
                        'confidence': conf,
                        'bbox': [x1, y1, x2, y2],
                        'center': [(x1 + x2) / 2, (y1 + y2) / 2],
                        'area': (x2 - x1) * (y2 - y1)
                    }
                    detections.append(detection)

            self.frame_count += 1
            self.total_detections += len(detections)

            return detections

        except Exception as e:
            print(f"Error processing frame: {e}", file=sys.stderr)
            return []

    def run(self):
        """Main processing loop"""
        try:
            while True:
                # Read frame size (4 bytes little-endian)
                size_data = sys.stdin.buffer.read(4)
                if not size_data:
                    break

                frame_size = struct.unpack('<I', size_data)[0]

                # Read frame data
                frame_data = sys.stdin.buffer.read(frame_size)
                if len(frame_data) != frame_size:
                    break

                # Process frame
                detections = self.process_frame(frame_data)

                # Output results
                result = {
                    'detections': detections,
                    'frame_count': self.frame_count,
                    'total_detections': self.total_detections
                }

                print(json.dumps(result))
                sys.stdout.flush()

        except Exception as e:
            print(f"Error in main loop: {e}", file=sys.stderr)

if __name__ == "__main__":
    processor = YOLOProcessor()
    processor.run()
