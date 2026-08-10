import sys
import os
import io
from pathlib import Path
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import uvicorn
import torch
from contextlib import asynccontextmanager

# Inject custom YOLOv12 repository path into Python runtime search path
BASE_DIR = Path(__file__).parent
YOLO_DIR = BASE_DIR / "yolov12"
if YOLO_DIR.exists():
    sys.path.insert(0, str(YOLO_DIR))
    print(f"[SYSTEM] Injected native YOLOv12 repository into sys.path: {YOLO_DIR}")

# Global YOLO model instance
model = None

# Model weights location
WEIGHTS_PATH = os.getenv(
    "YOLO_WEIGHTS_PATH",
    "d:/Projects/OtoScan/scenario_5_full_results/scenario_5_high_recall_insurance/weights/best.pt"
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    global model
    try:
        from ultralytics import YOLO
        if os.path.exists(WEIGHTS_PATH):
            model = YOLO(WEIGHTS_PATH)
            print(f"✅ YOLOv12 model successfully loaded from {WEIGHTS_PATH}")
        else:
            print(f"⚠️ Model weights not found at {WEIGHTS_PATH}. Running in fallback mode.")
    except Exception as e:
        print(f"⚠️ Error loading YOLOv12 model: {e}")
    yield

app = FastAPI(
    title="OtoScan AI YOLOv12 Vehicle Inspection Service",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Class mappings to standard codes
CLASS_MAPPING = {
    0: "dent",
    1: "scratch",
    2: "crack",
    3: "glass_shatter",
    4: "lamp_broken",
    5: "tire_flat",
}

@app.get("/")
@app.get("/health")
def health_check():
    return {
        "status": "online",
        "service": "OtoScan YOLOv12 AI Service",
        "model_loaded": model is not None,
        "weights_path": WEIGHTS_PATH
    }

@app.post("/predict")
async def predict_damage(
    file: UploadFile = File(...),
    output_filename: str = Form(None),
    conf_threshold: float = Form(0.15)
):
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image file: {str(e)}")

    predictions = []
    summary_counts = {}
    annotated_public_url = ""

    if model is not None:
        try:
            # Model inference with imgsz=800 and iou=0.45 matching training setup
            results = model.predict(source=image, conf=conf_threshold, iou=0.45, imgsz=800, verbose=False)
            model_names = getattr(model, "names", CLASS_MAPPING)

            for r in results:
                boxes = r.boxes
                if len(boxes) > 0:
                    try:
                        # Render bounding box annotations on image
                        plotted_bgr = r.plot()
                        # Convert BGR array from YOLO plot to RGB PIL Image
                        plotted_rgb = Image.fromarray(plotted_bgr[..., ::-1])

                        result_dir = os.path.abspath("../otoscan-api/uploads/results")
                        os.makedirs(result_dir, exist_ok=True)
                        
                        import uuid
                        if output_filename and output_filename.strip():
                            annotated_filename = output_filename.strip()
                        else:
                            annotated_filename = f"result_{uuid.uuid4().hex[:12]}.jpg"

                        annotated_filepath = os.path.join(result_dir, annotated_filename)
                        plotted_rgb.save(annotated_filepath, format="JPEG", quality=92)

                        annotated_public_url = f"/uploads/results/{annotated_filename}"
                    except Exception as img_err:
                        print(f"⚠️ Error rendering annotated image: {img_err}")

                for box in boxes:
                    cls_id = int(box.cls[0].item())
                    conf = float(box.conf[0].item())
                    xyxy = box.xyxy[0].tolist()

                    class_code = model_names.get(cls_id, CLASS_MAPPING.get(cls_id, f"class_{cls_id}"))
                    summary_counts[class_code] = summary_counts.get(class_code, 0) + 1

                    predictions.append({
                        "class_code": class_code,
                        "class_id": cls_id,
                        "confidence": round(conf, 4),
                        "box_xyxy": [round(val, 2) for val in xyxy],
                    })
        except Exception as e:
            print(f"⚠️ Error during YOLOv12 prediction: {e}")

    return {
        "status": "success",
        "total_detections": len(predictions),
        "annotated_image_path": annotated_public_url,
        "summary": summary_counts,
        "predictions": predictions
    }

if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    print(f"🚀 Starting YOLOv12 AI Microservice on http://localhost:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
