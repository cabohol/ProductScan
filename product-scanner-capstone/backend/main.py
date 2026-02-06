import os
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from PIL import Image
import io
import numpy as np
from ultralytics import YOLO

app = FastAPI()

# CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load YOLO model
MODEL_PATH = os.getenv("MODEL_PATH", "yolo/models/best1.pt")
model = YOLO(MODEL_PATH)

@app.get("/")
def root():
    return {"message": "YOLO Jewelry Scanner API is running on Render!"}

@app.post("/predict")
async def predict(image: UploadFile = File(...)):
    try:
        contents = await image.read()
        pil_image = Image.open(io.BytesIO(contents))
        img_array = np.array(pil_image)
        
        results = model(img_array)
        
        if len(results) > 0 and len(results[0].boxes) > 0:
            box = results[0].boxes[0]
            class_id = int(box.cls[0])
            confidence = float(box.conf[0])
            class_name = results[0].names[class_id]
            
            return {
                "product_name": class_name,
                "category": "Jewelry",
                "yolo_label": class_name,
                "confidence": confidence,
                "authenticity": "Genuine" if confidence > 0.75 else "Needs Verification",
                "estimated_value": f"₱{int(5000 * confidence):,}",
            }
        else:
            return {
                "product_name": "No jewelry detected",
                "category": "Unknown",
                "confidence": 0.0,
                "authenticity": "Not detected",
                "estimated_value": "N/A",
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    uvicorn.run(app, host="0.0.0.0", port=port)