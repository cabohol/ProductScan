import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;
  
  static const int INPUT_SIZE = 640;
  static const double CONFIDENCE_THRESHOLD = 0.25;

  // Load model and labels
  Future<void> loadModel() async {
    try {
      print(' Loading TFLite model...');
      
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset('assets/best.tflite');
      
      // Load labels
      String labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.trim().isNotEmpty).toList();
      
      print(' Model loaded successfully');
      print(' Labels: $_labels');
      print(' Input: ${_interpreter?.getInputTensors()}');
      print(' Output: ${_interpreter?.getOutputTensors()}');
    } catch (e) {
      print(' Error loading model: $e');
      rethrow;
    }
  }

  // Run inference
  Future<Map<String, dynamic>?> predict(File imageFile) async {
    if (_interpreter == null) {
      print(' Model not loaded!');
      return null;
    }

    try {
      print(' Starting prediction...');
      
      // Read image
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        print(' Failed to decode image');
        return null;
      }

      // Resize to 640x640
      img.Image resizedImage = img.copyResize(
        image,
        width: INPUT_SIZE,
        height: INPUT_SIZE,
      );

      // Convert to input tensor
      var input = _imageToFloat32List(resizedImage);

      // Prepare output
      var outputShape = _interpreter!.getOutputTensor(0).shape;
      var output = List.filled(
        outputShape.reduce((a, b) => a * b), 
        0.0
      ).reshape(outputShape);
      
      // Run inference
      print(' Running inference...');
      _interpreter!.run(input, output);

      // Process results
      var result = _processOutput(output);
      
      print(' Prediction complete: ${result['product_name']}');
      return result;
      
    } catch (e) {
      print(' Prediction error: $e');
      return {
        'success': false,
        'product_name': 'Error',
        'error': e.toString(),
      };
    }
  }

  // Convert image to Float32 normalized
  Float32List _imageToFloat32List(img.Image image) {
    var buffer = Float32List(1 * INPUT_SIZE * INPUT_SIZE * 3);
    int pixelIndex = 0;

    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        var pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return buffer;
  }

  // Process YOLO output
  Map<String, dynamic> _processOutput(List output) {
    List<Map<String, dynamic>> detections = [];
    
    // Parse detections
    int numDetections = output[0].length;
    
    for (var i = 0; i < numDetections; i++) {
      var detection = output[0][i];
      
      // YOLO output format: [x, y, w, h, conf, class_scores...]
      double confidence = detection[4];
      
      if (confidence > CONFIDENCE_THRESHOLD) {
        // Find class with highest score
        double maxScore = 0;
        int classId = 0;
        
        for (var c = 0; c < _labels!.length; c++) {
          double score = detection[5 + c];
          if (score > maxScore) {
            maxScore = score;
            classId = c;
          }
        }
        
        double finalConf = confidence * maxScore;
        
        if (finalConf > CONFIDENCE_THRESHOLD) {
          detections.add({
            'class_id': classId,
            'class_name': _labels![classId],
            'confidence': finalConf,
          });
        }
      }
    }

    // No detections
    if (detections.isEmpty) {
      return {
        'success': false,
        'product_name': 'No jewelry detected',
        'category': 'Unknown',
        'confidence': 0.0,
        'authenticity': 'Unable to determine',
        'estimated_value': 'N/A',
      };
    }

    // Get best detection
    detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    var best = detections.first;

    return {
      'success': true,
      'product_name': best['class_name'],
      'category': best['class_name'],
      'confidence': best['confidence'],
      'authenticity': _getAuthenticity(best['confidence']),
      'estimated_value': _estimateValue(best['class_name'], best['confidence']),
    };
  }

  String _getAuthenticity(double confidence) {
    if (confidence > 0.85) return "High Confidence - Likely Authentic";
    if (confidence > 0.65) return "Medium Confidence - Needs Verification";
    return "Low Confidence - Expert Review Recommended";
  }

  String _estimateValue(String category, double confidence) {
    Map<String, int> baseValues = {
      'Ring': 500,
      'Necklace': 800,
      'Earring': 400,
    };
    
    int base = baseValues[category] ?? 500;
    double estimated = base * (0.5 + confidence * 0.5);
    
    return '₱${estimated.toStringAsFixed(0)} - ₱${(estimated * 1.5).toStringAsFixed(0)}';
  }

  void dispose() {
    _interpreter?.close();
  }
}