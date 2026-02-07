from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import io
import numpy as np
from ultralytics import YOLO
import gradio as gr

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model
model = YOLO('best1.pt')

JEWELRY_CATEGORIES = {
    0: 'Ring',
    1: 'Necklace',
    2: 'Earring',
}

@app.get("/")
def read_root():
    return {"message": "Jewelry Scanner API - Running on Hugging Face!"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "model_loaded": True}

@app.post("/predict")
async def predict(image: UploadFile = File(...)):
    try:
        contents = await image.read()
        pil_image = Image.open(io.BytesIO(contents))
        img_array = np.array(pil_image)
        
        results = model(img_array, conf=0.25)
        
        if len(results) > 0 and len(results[0].boxes) > 0:
            box = results[0].boxes[0]
            class_id = int(box.cls[0])
            confidence = float(box.conf[0])
            class_name = JEWELRY_CATEGORIES.get(class_id, f'Class_{class_id}')
            
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
            }
            
    except Exception as e:
        return {"error": str(e)}

# Mount Gradio app for UI
io = gr.Interface(
    fn=lambda img: model(np.array(img)),
    inputs=gr.Image(type="pil"),
    outputs=gr.Image(),
    title="Jewelry Scanner"
)

app = gr.mount_gradio_app(app, io, path="/")