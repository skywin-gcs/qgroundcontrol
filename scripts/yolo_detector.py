
import sys
import cv2
import numpy as np
from ultralytics import YOLO
import json

def main():
    # Initialize YOLO model
    model = YOLO("yolov8n.pt")

    while True:
        # Read frame size from stdin
        header = sys.stdin.buffer.read(4)
        if not header:
            break
        frame_size = int.from_bytes(header, 'little')

        # Read frame data from stdin
        frame_data = sys.stdin.buffer.read(frame_size)
        if not frame_data:
            break

        # Decode the frame
        frame = cv2.imdecode(np.frombuffer(frame_data, np.uint8), cv2.IMREAD_COLOR)

        # Perform YOLO detection
        results = model(frame)

        # Prepare results for JSON output
        detections = []
        for result in results:
            for box in result.boxes:
                x1, y1, x2, y2 = box.xyxy[0]
                conf = box.conf[0]
                cls = box.cls[0]
                label = model.names[int(cls)]
                detections.append({
                    "box": [int(x1), int(y1), int(x2), int(y2)],
                    "confidence": float(conf),
                    "label": label
                })

        # Write detections as JSON to stdout
        output = json.dumps(detections)
        sys.stdout.write(output + '
')
        sys.stdout.flush()

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        # It's a good practice to log errors to stderr
        print(f"Error in yolo_detector.py: {e}", file=sys.stderr)
        sys.exit(1)
