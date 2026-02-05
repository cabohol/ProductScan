from flask import Flask, request, jsonify
from flask_cors import CORS
from ultralytics import YOLO
import cv2
import numpy as np
from PIL import Image
import io
import base64
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web/mobile access

# Load YOLO model 
MODEL_PATH = 'yolo/models/best1.pt' 
model = YOLO(MODEL_PATH)

# Jewelry categories mapping
JEWELRY_CATEGORIES = {
    0: 'Ring',
    1: 'Necklace',
    2: 'Earring',
}

def estimate_value(category, confidence):
    """Simple value estimation based on category and confidence"""
    base_values = {
        'Ring': 500,
        'Necklace': 800,
        'Bracelet': 600,
        'Earring': 400,
        'Watch': 1200,
    }
    base = base_values.get(category, 500)
    # Adjust based on confidence
    estimated = base * (0.5 + confidence * 0.5)
    return f"${estimated:.2f} - ${estimated * 1.5:.2f}"

def determine_authenticity(confidence):
    """Determine authenticity based on model confidence"""
    if confidence > 0.85:
        return "High Confidence - Likely Authentic"
    elif confidence > 0.65:
        return "Medium Confidence - Needs Verification"
    else:
        return "Low Confidence - Expert Review Recommended"

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'model_path': MODEL_PATH
    })

@app.route('/predict', methods=['POST'])
def predict():
    """
    Endpoint to receive image and return YOLO predictions
    
    Expected request format:
    - multipart/form-data with 'image' file
    OR
    - JSON with base64 encoded image
    """
    try:
        # Check if image is sent as file
        if 'image' in request.files:
            file = request.files['image']
            img_bytes = file.read()
            
        # Check if image is sent as base64
        elif request.json and 'image' in request.json:
            base64_img = request.json['image']
            # Remove header if present
            if ',' in base64_img:
                base64_img = base64_img.split(',')[1]
            img_bytes = base64.b64decode(base64_img)
        else:
            return jsonify({'error': 'No image provided'}), 400

        # Convert bytes to image
        img = Image.open(io.BytesIO(img_bytes))
        img_array = np.array(img)
        
        # Convert RGB to BGR for OpenCV
        if len(img_array.shape) == 3 and img_array.shape[2] == 3:
            img_array = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)

        # Run YOLO inference
        results = model(img_array)
        
        # Process results
        predictions = []
        for result in results:
            boxes = result.boxes
            for box in boxes:
                # Get box coordinates
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                
                # Get confidence and class
                confidence = float(box.conf[0])
                class_id = int(box.cls[0])
                
                # Get category name
                category = JEWELRY_CATEGORIES.get(class_id, f'Class_{class_id}')
                
                predictions.append({
                    'bbox': {
                        'x1': float(x1),
                        'y1': float(y1),
                        'x2': float(x2),
                        'y2': float(y2)
                    },
                    'confidence': confidence,
                    'class_id': class_id,
                    'category': category
                })

        # Get best prediction
        if predictions:
            best_pred = max(predictions, key=lambda x: x['confidence'])
            
            response = {
                'success': True,
                'product_name': best_pred['category'],
                'category': best_pred['category'],
                'confidence': best_pred['confidence'],
                'authenticity': determine_authenticity(best_pred['confidence']),
                'estimated_value': estimate_value(best_pred['category'], best_pred['confidence']),
                'all_detections': predictions
            }
        else:
            response = {
                'success': False,
                'product_name': 'No jewelry detected',
                'category': 'Unknown',
                'confidence': 0.0,
                'authenticity': 'Unable to determine',
                'estimated_value': 'N/A',
                'all_detections': []
            }

        return jsonify(response)

    except Exception as e:
        return jsonify({
            'error': str(e),
            'success': False
        }), 500

@app.route('/predict_batch', methods=['POST'])
def predict_batch():
    """Endpoint for batch image processing"""
    try:
        images = request.files.getlist('images')
        results = []
        
        for img_file in images:
            img_bytes = img_file.read()
            img = Image.open(io.BytesIO(img_bytes))
            img_array = np.array(img)
            
            if len(img_array.shape) == 3 and img_array.shape[2] == 3:
                img_array = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
            
            predictions = model(img_array)
            # Process predictions...
            results.append({'filename': img_file.filename, 'predictions': []})
        
        return jsonify({'results': results})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Check if model file exists
    if not os.path.exists(MODEL_PATH):
        print(f"Warning: Model file not found at {MODEL_PATH}")
        print("Please update MODEL_PATH in the script")
    
    print(f"Starting YOLO API server...")
    print(f"Model: {MODEL_PATH}")
    
    # Run on all interfaces, port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)