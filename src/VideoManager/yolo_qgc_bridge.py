#!/usr/bin/env python3
"""
yolo_qgc_bridge.py - YOLO detection bridge for QGroundControl
Runs headlessly, reads frames from camera, outputs JSON detection lines to stdout.
Receives commands from stdin (JSON lines).
"""
import cv2
from ultralytics import YOLO
import time
from datetime import datetime
import json
import sys
import threading
import os
import csv
from pathlib import Path

# Disable OpenCV GUI (headless mode for QGC integration)
os.environ["OPENCV_VIDEOIO_MSMF_ENABLE_HW_TRANSFORMS"] = "0"

class YOLOQGCBridge:
    def __init__(self, model_path='yolo11n.pt', camera_id=0, conf_threshold=0.25):
        self.model_path = model_path
        self.camera_id = camera_id
        self.conf_threshold = conf_threshold
        self.running = False
        self.paused = False

        # Stats
        self.frame_count = 0
        self.total_detections = 0
        self.fps = 0.0

        # Object tracking
        self.object_id_counter = 0
        self.tracked_objects = {}
        self.selected_object_id = None

        # Data logging
        self.base_folder = self._create_session_folder()
        self.csv_file = self.base_folder / "detections.csv"
        self._init_csv()

        # Video saving
        self.video_writer = None
        self.clip_counter = 0
        self.videos_folder = self.base_folder / "clips"
        self.videos_folder.mkdir(exist_ok=True)
        self.frames_since_detection = 0
        self.MAX_GAP_FRAMES = 30

        self._log(f"Session folder: {self.base_folder}")

    def _create_session_folder(self):
        base = Path(f"yolo_data_{datetime.now().strftime('%Y-%m-%d')}")
        counter = 1
        folder = base
        while folder.exists():
            folder = Path(f"{base}_{counter:02d}")
            counter += 1
        folder.mkdir(parents=True)
        (folder / "frames").mkdir()
        return folder

    def _init_csv(self):
        with open(self.csv_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['timestamp', 'frame', 'class', 'confidence',
                             'cx', 'cy', 'x1', 'y1', 'x2', 'y2', 'area'])

    def _log(self, msg, level="info"):
        """Send a log message to QGC via stdout JSON"""
        packet = {"type": "log", "level": level, "message": msg}
        print(json.dumps(packet), flush=True)

    def _send_detections(self, detections):
        """Send detection results to QGC via stdout JSON"""
        packet = {
            "type": "detections",
            "frame": self.frame_count,
            "fps": round(self.fps, 1),
            "total_detections": self.total_detections,
            "count": len(detections),
            "detections": detections
        }
        print(json.dumps(packet), flush=True)

    def _send_status(self, status):
        """Send status update"""
        packet = {"type": "status", "status": status, "frame": self.frame_count,
                  "fps": round(self.fps, 1), "total": self.total_detections}
        print(json.dumps(packet), flush=True)

    def _assign_ids(self, detections):
        new_tracked = {}
        for det in detections:
            cx, cy = det['cx'], det['cy']
            matched_id = None
            min_dist = 120

            for obj_id, obj in self.tracked_objects.items():
                dist = ((cx - obj['cx'])**2 + (cy - obj['cy'])**2)**0.5
                if dist < min_dist and obj['class'] == det['class']:
                    matched_id = obj_id
                    min_dist = dist
                    break

            if matched_id is None:
                self.object_id_counter += 1
                matched_id = self.object_id_counter

            det['id'] = matched_id
            new_tracked[matched_id] = det

        self.tracked_objects = new_tracked
        return detections

    def _log_detection_csv(self, det):
        with open(self.csv_file, 'a', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([
                datetime.now().isoformat(), self.frame_count,
                det['class'], round(det['confidence'], 3),
                int(det['cx']), int(det['cy']),
                int(det['x1']), int(det['y1']),
                int(det['x2']), int(det['y2']),
                int(det['area'])
            ])

    def _read_stdin(self):
        """Background thread: read commands from stdin"""
        for line in sys.stdin:
            try:
                cmd = json.loads(line.strip())
                action = cmd.get("cmd", "")
                if action == "stop":
                    self.running = False
                elif action == "pause":
                    self.paused = not self.paused
                elif action == "set_conf":
                    self.conf_threshold = float(cmd.get("value", 0.25))
                    self._log(f"Confidence set to {self.conf_threshold}")
                elif action == "select":
                    self.selected_object_id = cmd.get("id")
                    self._log(f"Selected object #{self.selected_object_id}")
                elif action == "ping":
                    self._send_status("running" if self.running else "stopped")
            except Exception as e:
                pass  # Ignore malformed commands

    def run(self):
        self._log(f"Loading model: {self.model_path}")
        model = YOLO(self.model_path)
        class_names = model.names
        self._log(f"Model loaded. Classes: {len(class_names)}")

        # Open camera
        import sys as _sys
        backend = cv2.CAP_DSHOW if _sys.platform == 'win32' else cv2.CAP_AVFOUNDATION
        cap = cv2.VideoCapture(self.camera_id, backend)
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
        cap.set(cv2.CAP_PROP_FPS, 30)

        if not cap.isOpened():
            self._log(f"Failed to open camera {self.camera_id}", "error")
            return

        self._log("Camera opened. Starting detection loop.")
        self.running = True

        # Start stdin listener thread
        stdin_thread = threading.Thread(target=self._read_stdin, daemon=True)
        stdin_thread.start()

        fps_start = time.time()
        fps_counter = 0

        try:
            while self.running:
                ret, frame = cap.read()
                if not ret:
                    time.sleep(0.01)
                    continue

                if self.paused:
                    time.sleep(0.05)
                    continue

                self.frame_count += 1
                fps_counter += 1
                self.frames_since_detection += 1

                # FPS calculation
                if fps_counter >= 30:
                    elapsed = time.time() - fps_start
                    self.fps = 30.0 / elapsed if elapsed > 0 else 0
                    fps_start = time.time()
                    fps_counter = 0

                # Run YOLO
                results = model(frame, conf=self.conf_threshold, verbose=False)[0]

                frame_dets = []
                if results.boxes is not None:
                    for box in results.boxes:
                        x1, y1, x2, y2 = box.xyxy[0].tolist()
                        conf = float(box.conf[0])
                        cls = int(box.cls[0])
                        det = {
                            "class": class_names[cls],
                            "class_id": cls,
                            "confidence": conf,
                            "x1": x1, "y1": y1, "x2": x2, "y2": y2,
                            "cx": (x1 + x2) / 2,
                            "cy": (y1 + y2) / 2,
                            "area": (x2 - x1) * (y2 - y1),
                            "id": 0
                        }
                        frame_dets.append(det)
                        self.total_detections += 1
                        self._log_detection_csv(det)

                if frame_dets:
                    self.frames_since_detection = 0
                    frame_dets = self._assign_ids(frame_dets)

                    # Start video clip
                    if self.video_writer is None:
                        self.clip_counter += 1
                        ts = datetime.now().strftime('%H%M%S')
                        vpath = self.videos_folder / f"clip_{self.clip_counter:03d}_{ts}.mp4"
                        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
                        self.video_writer = cv2.VideoWriter(str(vpath), fourcc, 20.0, (640, 480))
                        self._log(f"Recording clip {self.clip_counter}: {vpath.name}")

                    # Draw and save frame
                    annotated = results.plot()
                    frame_path = self.base_folder / "frames" / f"frame_{self.frame_count:06d}.jpg"
                    cv2.imwrite(str(frame_path), annotated)
                    if self.video_writer:
                        self.video_writer.write(annotated)

                    self._send_detections(frame_dets)

                elif self.video_writer and self.frames_since_detection > self.MAX_GAP_FRAMES:
                    self.video_writer.release()
                    self.video_writer = None
                    self._log(f"Clip {self.clip_counter} saved (gap detected)")
                    self._send_detections([])

                elif self.frame_count % 30 == 0:
                    # Send heartbeat with empty detections
                    self._send_detections([])

        except KeyboardInterrupt:
            pass
        finally:
            cap.release()
            if self.video_writer:
                self.video_writer.release()
            self._send_status("stopped")
            self._log(f"Session complete. Total: {self.total_detections} detections over {self.frame_count} frames.")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--model', default='yolo11n.pt')
    parser.add_argument('--camera', type=int, default=0)
    parser.add_argument('--conf', type=float, default=0.25)
    args = parser.parse_args()

    bridge = YOLOQGCBridge(
        model_path=args.model,
        camera_id=args.camera,
        conf_threshold=args.conf
    )
    bridge.run()
