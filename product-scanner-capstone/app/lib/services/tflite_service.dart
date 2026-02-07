import 'dart:io';
import 'package:flutter_tflite/flutter_tflite.dart';

class TFLiteService {
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      print(' Loading TFLite model...');
      
      String? res = await Tflite.loadModel(
        model: "assets/best1.tflite",
        labels: "assets/labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false,
      );
      
      _isModelLoaded = (res != null);
      
      if (_isModelLoaded) {
        print(' Model loaded successfully');
      } else {
        print(' Failed to load model');
      }
    } catch (e) {
      print(' Error loading model: $e');
      _isModelLoaded = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> predict(File imageFile) async {
    if (!_isModelLoaded) {
      print(' Model not loaded!');
      return {
        'success': false,
        'product_name': 'Model not loaded',
        'category': 'Unknown',
        'confidence': 0.0,
        'authenticity': 'Error',
        'estimated_value': 'N/A',
      };
    }

    try {
      print(' Starting prediction...');
      
      var recognitions = await Tflite.detectObjectOnImage(
        path: imageFile.path,
        model: "SSDMobileNet",
        threshold: 0.25,
        imageMean: 0.0,
        imageStd: 255.0,
        numResultsPerClass: 1,
        asynch: true,
      );
      
      print(' Raw results: $recognitions');
      
      if (recognitions == null || recognitions.isEmpty) {
        print(' No detections found');
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
      var best = recognitions.first;
      
      // Extract data safely
      double confidence = 0.0;
      String label = 'Unknown';
      
      if (best['confidenceInClass'] != null) {
        confidence = best['confidenceInClass'] is double 
            ? best['confidenceInClass'] 
            : (best['confidenceInClass'] as num).toDouble();
      }
      
      if (best['detectedClass'] != null) {
        label = best['detectedClass'].toString();
      } else if (best['label'] != null) {
        label = best['label'].toString();
      }
  
      print(' Detection: $label (${(confidence * 100).toStringAsFixed(1)}%)');

      return {
        'success': true,
        'product_name': label,
        'category': label,
        'confidence': confidence,
        'authenticity': _getAuthenticity(confidence),
        'estimated_value': _estimateValue(label, confidence),
      };
      
    } catch (e) {
      print(' Prediction error: $e');
      return {
        'success': false,
        'product_name': 'Prediction error',
        'category': 'Error',
        'confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  String _getAuthenticity(double confidence) {
    if (confidence > 0.85) return "High Confidence - Likely Authentic";
    if (confidence > 0.65) return "Medium Confidence - Needs Verification";
    return "Low Confidence - Expert Review Recommended";
  }

  String _estimateValue(String category, double confidence) {
    Map<String, int> baseValues = {
      'Ring': 500,
      'ring': 500,
      'Necklace': 800,
      'necklace': 800,
      'Earring': 400,
      'earring': 400,
    };
    
    int base = baseValues[category] ?? 500;
    double estimated = base * (0.5 + confidence * 0.5);
    
    return '₱${estimated.toStringAsFixed(0)} - ₱${(estimated * 1.5).toStringAsFixed(0)}';
  }

  void dispose() async {
    await Tflite.close();
    _isModelLoaded = false;
    print(' TFLite model closed');
  }
}