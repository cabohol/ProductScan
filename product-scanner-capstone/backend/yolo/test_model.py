# backend/yolo/test_model.py (IMPROVED VERSION)
from ultralytics import YOLO
from PIL import Image
import os
import glob

model = YOLO('models/best (1).pt')

test_folder = 'test_images'
image_files = glob.glob(f'{test_folder}/*.jpg') + glob.glob(f'{test_folder}/*.png')

if not image_files:
    print(f" No images found in {test_folder}/")
    exit()

print(f" Found {len(image_files)} images to test\n")

# Test each image
for img_path in image_files:
    print("="*60)
    print(f"Testing: {os.path.basename(img_path)}")
    print("="*60)
    
    # Lower confidence threshold for better detection
    results = model.predict(
        source=img_path,
        save=True,
        conf=0.25,        # ← LOWER = more detections (was 0.5)
        iou=0.45,         # ← IoU threshold
        imgsz=640,
        verbose=False     # ← Less output noise
    )
    
    #  Enhanced results display
    for result in results:
        boxes = result.boxes
        
        if len(boxes) == 0:
            print(" No jewelry detected")
            print(" Try: Better lighting, closer photo, different angle\n")
        else:
            #  Sort by confidence (highest first)
            sorted_boxes = sorted(
                boxes, 
                key=lambda x: float(x.conf[0]), 
                reverse=True
            )
            
            for i, box in enumerate(sorted_boxes, 1):
                class_id = int(box.cls[0])
                confidence = float(box.conf[0])
                class_name = model.names[class_id]
                coords = box.xyxy[0].tolist()
                
                #  Color-coded output
                if confidence >= 0.7:
                    status = " HIGH"
                elif confidence >= 0.5:
                    status = " MEDIUM"
                else:
                    status = " LOW"
                
                print(f"\n{i}. {status} CONFIDENCE")
                print(f"   Type: {class_name.upper()}")
                print(f"   Confidence: {confidence:.1%}")
                print(f"   Box: [{coords[0]:.1f}, {coords[1]:.1f}, {coords[2]:.1f}, {coords[3]:.1f}]")
    
    print(f"\n Result saved to: {result.save_dir}\n")

print("\n" + "="*60)
print("All tests completed!")
print("="*60)