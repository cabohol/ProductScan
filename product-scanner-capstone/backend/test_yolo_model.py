"""
YOLO Model Test Script
Run this to verify your YOLO model is working correctly before integrating with Flutter
"""

import os
import sys
from ultralytics import YOLO
import cv2
import numpy as np
from pathlib import Path

def test_model():
    print("=" * 50)
    print("YOLO Model Test Script")
    print("=" * 50)
    
    # 1. Check model file exists
    model_paths = [
        'yolo/models/best.pt',
        'yolo/models/best(1).pt',
        'models/best.pt',
        'best.pt',
    ]
    
    model_path = None
    for path in model_paths:
        if os.path.exists(path):
            model_path = path
            print(f"✓ Model found at: {path}")
            break
    
    if not model_path:
        print("✗ Model file not found!")
        print("Please update the model_paths list with your model location")
        return False
    
    # 2. Load model
    try:
        print("\nLoading YOLO model...")
        model = YOLO(model_path)
        print("✓ Model loaded successfully!")
    except Exception as e:
        print(f"✗ Error loading model: {e}")
        return False
    
    # 3. Check model info
    print("\nModel Information:")
    print(f"  - Model type: {type(model)}")
    print(f"  - Model task: {model.task}")
    try:
        names = model.names
        print(f"  - Number of classes: {len(names)}")
        print(f"  - Class names: {names}")
    except:
        print("  - Could not retrieve class information")
    
    # 4. Test with sample image
    test_image_paths = [
        'yolo/test_images',
        'test_images',
        'yolo/runs',
    ]
    
    test_image = None
    for dir_path in test_image_paths:
        if os.path.exists(dir_path):
            image_files = list(Path(dir_path).glob('*.jpg')) + \
                         list(Path(dir_path).glob('*.png')) + \
                         list(Path(dir_path).glob('*.jpeg'))
            if image_files:
                test_image = str(image_files[0])
                break
    
    if test_image:
        print(f"\n✓ Test image found: {test_image}")
        try:
            print("Running inference...")
            results = model(test_image)
            
            print("✓ Inference successful!")
            
            # Display results
            for result in results:
                boxes = result.boxes
                print(f"\nDetections found: {len(boxes)}")
                
                for i, box in enumerate(boxes):
                    conf = float(box.conf[0])
                    cls = int(box.cls[0])
                    class_name = names.get(cls, f"Class_{cls}")
                    
                    print(f"  Detection {i+1}:")
                    print(f"    - Class: {class_name}")
                    print(f"    - Confidence: {conf:.2%}")
                    
                if len(boxes) == 0:
                    print("  No objects detected in this image")
            
        except Exception as e:
            print(f"✗ Error during inference: {e}")
            return False
    else:
        print("\n! No test images found")
        print("Creating a dummy test...")
        
        # Create a dummy image for testing
        dummy_img = np.random.randint(0, 255, (640, 640, 3), dtype=np.uint8)
        try:
            results = model(dummy_img)
            print("✓ Model can process images (tested with dummy image)")
        except Exception as e:
            print(f"✗ Error processing dummy image: {e}")
            return False
    
    # 5. Test performance
    print("\n" + "=" * 50)
    print("Performance Test (10 predictions)")
    print("=" * 50)
    
    import time
    dummy_img = np.random.randint(0, 255, (640, 640, 3), dtype=np.uint8)
    
    times = []
    for i in range(10):
        start = time.time()
        _ = model(dummy_img, verbose=False)
        times.append(time.time() - start)
    
    avg_time = sum(times) / len(times)
    print(f"Average inference time: {avg_time:.3f} seconds")
    print(f"Estimated FPS: {1/avg_time:.1f}")
    
    if avg_time < 0.5:
        print("✓ Performance: Excellent (< 0.5s)")
    elif avg_time < 1.0:
        print("✓ Performance: Good (< 1s)")
    elif avg_time < 2.0:
        print("! Performance: Acceptable (< 2s)")
    else:
        print("! Performance: Slow (> 2s) - Consider using a smaller model")
    
    # 6. Summary
    print("\n" + "=" * 50)
    print("Test Summary")
    print("=" * 50)
    print("✓ All tests passed!")
    print("\nYour YOLO model is ready to be integrated with Flutter!")
    print("\nNext steps:")
    print("1. Run: python yolo_api.py")
    print("2. Test API: curl http://localhost:5000/health")
    print("3. Update Flutter app with your server IP")
    print("4. Deploy and test!")
    
    return True

if __name__ == "__main__":
    try:
        success = test_model()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\nUnexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)