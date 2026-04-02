#!/usr/bin/env python3
"""
Export YOLO11n to ONNX format for use with QGroundControl's OpenCV DNN backend.

Usage:
    python3 export_yolo11.py

Output:
    resources/models/yolo11n.onnx

Requirements:
    pip install ultralytics onnx onnxsim
"""

import os
import sys
import shutil

def main():
    # ── Dependency check ──────────────────────────────────────────────────────
    try:
        from ultralytics import YOLO
    except ImportError:
        print("[ERROR] ultralytics not installed.")
        print("        Run: pip install ultralytics")
        sys.exit(1)

    try:
        import onnx
    except ImportError:
        print("[ERROR] onnx not installed.")
        print("        Run: pip install onnx")
        sys.exit(1)

    # ── Paths ─────────────────────────────────────────────────────────────────
    script_dir   = os.path.dirname(os.path.abspath(__file__))
    output_dir   = os.path.join(script_dir, "resources", "models")
    output_path  = os.path.join(output_dir, "yolo11n.onnx")

    os.makedirs(output_dir, exist_ok=True)

    # ── Load YOLO11n ──────────────────────────────────────────────────────────
    print("[1/4] Loading YOLO11n weights (downloads ~5 MB on first run)...")
    model = YOLO("yolo11n.pt")

    params = sum(p.numel() for p in model.model.parameters())
    print(f"      Parameters : {params:,}  (~2.6M vs YOLOv8n's ~3.2M)")
    print(f"      mAP50-95   : 39.5  (vs YOLOv8n 37.3 on COCO)")

    # ── Export to ONNX ────────────────────────────────────────────────────────
    # opset=12  : broadest OpenCV DNN compatibility (supports up to opset 13)
    # simplify  : constant-folds dead branches, shrinks file size ~10-15%
    # imgsz=640 : standard YOLOv8/11 input resolution (must match inference)
    # dynamic=False : static input shape — required by cv::dnn::readNetFromONNX
    print("\n[2/4] Exporting to ONNX (opset 12, simplified, 640x640)...")
    exported = model.export(
        format   = "onnx",
        opset    = 12,
        simplify = True,
        imgsz    = 640,
        dynamic  = False,
    )

    exported_str = str(exported)
    if not os.path.exists(exported_str):
        print(f"[ERROR] Export did not produce a file at: {exported_str}")
        sys.exit(1)

    print(f"      Exported   : {exported_str}")

    # ── Validate ONNX model ───────────────────────────────────────────────────
    print("\n[3/4] Validating ONNX graph...")
    import onnx
    onnx_model = onnx.load(exported_str)
    onnx.checker.check_model(onnx_model)

    # Print input / output tensor shapes so the developer can verify
    graph = onnx_model.graph
    print("      Inputs:")
    for inp in graph.input:
        shape = [d.dim_value for d in inp.type.tensor_type.shape.dim]
        print(f"        {inp.name:30s}  {shape}")
    print("      Outputs:")
    for out in graph.output:
        shape = [d.dim_value for d in out.type.tensor_type.shape.dim]
        print(f"        {out.name:30s}  {shape}")
        # Expected for COCO-80 model: [1, 84, 8400]
        # 84  = 4 bbox coords + 80 class scores
        # 8400 = 80x80 + 40x40 + 20x20 anchor grid points

    # ── Copy to resources/models/ ─────────────────────────────────────────────
    print(f"\n[4/4] Copying to {output_path} ...")
    shutil.copy2(exported_str, output_path)

    size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f"      Size       : {size_mb:.1f} MB")
    print(f"\n[OK]  YOLO11n ONNX model ready at:")
    print(f"      {output_path}")
    print()
    print("Next steps:")
    print("  1. Rebuild QGroundControl — CMake will bundle the model into")
    print("     QGroundControl.app/Contents/Resources/yolo11n.onnx")
    print("  2. The detector auto-selects yolo11n.onnx over yolov8n.onnx")
    print("     (see YoloDetector.cc search path order)")

if __name__ == "__main__":
    # Suppress OpenMP duplicate-library warning that appears on macOS
    # when both PyTorch and system OpenMP are present
    os.environ.setdefault("KMP_DUPLICATE_LIB_OK", "TRUE")
    main()
