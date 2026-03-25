#!/usr/bin/env python3
"""
YOLO Processor for QGroundControl
Reads RGB frames from stdin, runs YOLO detection, outputs JSON to stdout

Usage:
    python3 yolo_processor.py --model yolov8n.pt --confidence 0.5

Input format: Raw RGB bytes (width, height, channels)
Output format: JSON lines with detections
"""

import sys
import json
import struct
import argparse
import time

try:
    import numpy as np
    from ultralytics import YOLO
except ImportError:
    print("YOLO dependencies not found. Please install with:", file=sys.stderr)
    print("pip install ultralytics numpy", file=sys.stderr)
    sys.exit(1)

class YOLOProcessor:
    def __init__(self, model_path="yolov8n.pt", confidence=0.5):
        """Initialize YOLO model"""
        print(f"Initializing YOLO with model: {model_path}", file=sys.stderr)
        try:
            self.model = YOLO(model_path)
            self.confidence = confidence
            self.frame_count = 0
            self.start_time = time.time()
            print("YOLO model loaded successfully", file=sys.stderr)
        except Exception as e:
            print(f"Error loading YOLO model: {e}", file=sys.stderr)
            sys.exit(1)

    def read_frame(self):
        """Read frame from stdin
        Format: width(4), height(4), channels(4), data
        """
        try:
            # Read header
            header = sys.stdin.buffer.read(12)
            if len(header) < 12:
                return None

            width, height, channels = struct.unpack('III', header)

            # Read image data
            data_size = width * height * channels
            data = sys.stdin.buffer.read(data_size)

            if len(data) < data_size:
                return None

            # Convert to numpy array
            frame = np.frombuffer(data, dtype=np.uint8)
            frame = frame.reshape((height, width, channels))

            return frame, width, height

        except Exception as e:
            print(f"Error reading frame: {e}", file=sys.stderr)
            return None

    def process_frame(self, frame, width, height):
        """Process frame with YOLO and return detections"""
        try:
            # Run YOLO detection
            results = self.model(frame, conf=self.confidence, verbose=False)

            detections = []

            for result in results:
                boxes = result.boxes
                if boxes is not None:
                    for box in boxes:
                        # Get box coordinates (xyxy format)
                        x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()

                        # Convert to relative coordinates (0-1)
                        rel_x1 = x1 / width
                        rel_y1 = y1 / height
                        rel_x2 = x2 / width
                        rel_y2 = y2 / height
                        rel_width = rel_x2 - rel_x1
                        rel_height = rel_y2 - rel_y1

                        # Get class and confidence
                        cls = int(box.cls[0].cpu().numpy())
                        conf = float(box.conf[0].cpu().numpy())

                        # Get class name
                        class_name = self.model.names[cls]

                        detection = {
                            "x": float(rel_x1),
                            "y": float(rel_y1),
                            "width": float(rel_width),
                            "height": float(rel_height),
                            "label": class_name,
                            "confidence": float(conf),
                            "color": self._get_class_color(cls)
                        }

                        detections.append(detection)

            return detections

        except Exception as e:
            print(f"Error processing frame: {e}", file=sys.stderr)
            return []

    def _get_class_color(self, class_id):
        """Get color for class ID"""
        colors = [
            "#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF",
            "#00FFFF", "#FF8800", "#8800FF", "#00FF88", "#FF0088"
        ]
        return colors[class_id % len(colors)]

    def run(self):
        """Main processing loop"""
        print("Starting YOLO processing loop", file=sys.stderr)

        try:
            while True:
                # Read frame
                result = self.read_frame()
                if result is None:
                    break

                frame, width, height = result

                # Process frame
                detections = self.process_frame(frame, width, height)

                # Calculate FPS
                self.frame_count += 1
                elapsed_time = time.time() - self.start_time
                fps = self.frame_count / elapsed_time if elapsed_time > 0 else 0

                # Output JSON
                output = {
                    "detections": detections,
                    "fps": round(fps, 1),
                    "frame_count": self.frame_count
                }

                print(json.dumps(output))
                sys.stdout.flush()

        except KeyboardInterrupt:
            print("YOLO processing interrupted", file=sys.stderr)
        except Exception as e:
            print(f"Error in processing loop: {e}", file=sys.stderr)

def main():
    parser = argparse.ArgumentParser(description='YOLO Processor for QGroundControl')
    parser.add_argument('--model', default='yolov8n.pt', help='YOLO model path')
    parser.add_argument('--confidence', type=float, default=0.5, help='Confidence threshold')

    args = parser.parse_args()

    # Initialize processor
    processor = YOLOProcessor(args.model, args.confidence)

    # Run processing
    processor.run()

if __name__ == "__main__":
    main()
