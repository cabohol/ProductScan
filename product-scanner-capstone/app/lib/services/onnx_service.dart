import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

class OnnxService {
  OrtSession? _session;
  List<String>? _labels;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      print('🔄 Loading ONNX model...');
      
      // Initialize ONNX Runtime
      OrtEnv.instance.init();
      
      // Load model from assets
      final sessionOptions = OrtSessionOptions();
      const assetFileName = 'assets/best1.onnx';
      final rawAssetFile = await rootBundle.load(assetFileName);
      final bytes = rawAssetFile.buffer.asUint8List();
      
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      
      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData.split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      
      _isModelLoaded = true;
      print('✅ ONNX model loaded successfully');
      print('📋 Classes: ${_labels?.length ?? 0}');
      print('📋 Labels: $_labels');
      
    } catch (e) {
      print('❌ Error loading ONNX model: $e');
      _isModelLoaded = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> predict(File imageFile) async {
    if (!_isModelLoaded || _session == null) {
      print('❌ Model not loaded!');
      return {
        'success': false,
        'product_name': 'Model not loaded',
        'category': 'Error',
        'confidence': 0.0,
        'authenticity': 'Error',
        'estimated_value': 'N/A',
      };
    }

    try {
      print('🔍 Starting prediction...');
      
      // Preprocess image
      final inputTensor = await _preprocessImage(imageFile);
      
      // Run inference
      final runOptions = OrtRunOptions();
      final inputs = {'images': inputTensor};
      final outputs = _session!.run(runOptions, inputs);
      
      // Process outputs
      final result = _processOutput(outputs);
      
      // Cleanup
      inputTensor.release();
      runOptions.release();
      outputs?.forEach((element) => element?.release());
      
      return result;
      
    } catch (e) {
      print('❌ Prediction error: $e');
      return {
        'success': false,
        'product_name': 'Prediction failed',
        'category': 'Error',
        'confidence': 0.0,
        'authenticity': 'Error',
        'estimated_value': 'N/A',
        'error': e.toString(),
      };
    }
  }

  Future<OrtValueTensor> _preprocessImage(File imageFile) async {
    try {
      // Load image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) throw Exception('Failed to decode image');
      
      print('📐 Original image size: ${image.width}x${image.height}');
      
      // Resize to 640x640 (YOLO input size)
      final resized = img.copyResize(image, width: 640, height: 640);
      
      // Convert to float32 array [1, 3, 640, 640] - CHW format
      final inputShape = [1, 3, 640, 640];
      final inputData = Float32List(1 * 3 * 640 * 640);
      
      // Fill data in CHW format (Channel, Height, Width)
      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          final pixel = resized.getPixel(x, y);
          final offset = y * 640 + x;
          
          // Normalize to [0, 1]
          inputData[offset] = pixel.r / 255.0;                      // R channel
          inputData[offset + 640 * 640] = pixel.g / 255.0;         // G channel
          inputData[offset + 2 * 640 * 640] = pixel.b / 255.0;     // B channel
        }
      }
      
      print('✅ Image preprocessed: ${inputShape}');
      
      return OrtValueTensor.createTensorWithDataList(inputData, inputShape);
      
    } catch (e) {
      print('❌ Preprocessing error: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? _processOutput(List<OrtValue?>? outputs) {
    if (outputs == null || outputs.isEmpty) {
      print('❌ No outputs from model');
      return {
        'success': false,
        'product_name': 'No detection',
        'category': 'Unknown',
        'confidence': 0.0,
        'authenticity': 'Unable to determine',
        'estimated_value': 'N/A',
      };
    }
    
    try {
      // YOLO output format: [1, num_detections, 5 + num_classes]
      // [x, y, w, h, confidence, class_scores...]
      final outputData = outputs[0]?.value;
      
      print('📊 Output type: ${outputData.runtimeType}');
      
      double maxConfidence = 0.0;
      int maxClass = 0;
      
      // Parse output based on structure
      if (outputData is List) {
        for (var batch in outputData) {
          if (batch is List) {
            for (var detection in batch) {
              if (detection is List && detection.length > 5) {
                final objectness = detection[4].toDouble();
                
                if (objectness > 0.25) {  // Confidence threshold
                  // Get class scores (after first 5 elements)
                  final classScores = detection.sublist(5).map((e) => e.toDouble()).toList();
                  final maxScore = classScores.reduce((a, b) => a > b ? a : b);
                  final classId = classScores.indexOf(maxScore);
                  
                  final confidence = objectness * maxScore;
                  
                  if (confidence > maxConfidence) {
                    maxConfidence = confidence;
                    maxClass = classId;
                  }
                }
              }
            }
          }
        }
      }
      
      print('🎯 Best detection: class=$maxClass, confidence=$maxConfidence');
      
      if (maxConfidence > 0.25 && _labels != null && maxClass < _labels!.length) {
        final label = _labels![maxClass];
        
        return {
          'success': true,
          'product_name': label,
          'category': label,
          'confidence': maxConfidence,
          'authenticity': _getAuthenticity(maxConfidence),
          'estimated_value': _estimateValue(label, maxConfidence),
        };
      }
      
      return {
        'success': false,
        'product_name': 'No jewelry detected',
        'category': 'Unknown',
        'confidence': maxConfidence,
        'authenticity': 'Low confidence',
        'estimated_value': 'N/A',
      };
      
    } catch (e) {
      print('❌ Output processing error: $e');
      return null;
    }
  }

  String _getAuthenticity(double confidence) {
    if (confidence > 0.85) return "High Confidence - Likely Authentic";
    if (confidence > 0.65) return "Medium Confidence - Needs Verification";
    return "Low Confidence - Expert Review Recommended";
  }

  String _estimateValue(String category, double confidence) {
    Map<String, int> baseValues = {
      'ring': 500,
      'necklace': 800,
      'earring': 400,
      'bracelet': 600,
      'pendant': 700,
    };
    
    int base = baseValues[category.toLowerCase()] ?? 500;
    double estimated = base * (0.5 + confidence * 0.5);
    
    return '₱${estimated.toStringAsFixed(0)} - ₱${(estimated * 1.5).toStringAsFixed(0)}';
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
    _isModelLoaded = false;
    print('🔒 ONNX model closed');
  }
}