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
      try {
        OrtEnv.instance.init();
      } catch (e) {
        print('⚠️ OrtEnv already initialized or failed: $e');
      }

      // Load model from assets
      final sessionOptions = OrtSessionOptions();
      const assetFileName = 'assets/best_final.onnx';
      final rawAssetFile = await rootBundle.load(assetFileName);
      final bytes = rawAssetFile.buffer.asUint8List();

      _session = OrtSession.fromBuffer(bytes, sessionOptions);

      // Load labels
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsData
          .split('\n')
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

  Future<void> testModel() async {
    print('🧪 ============ MODEL TEST ============');
    print('✅ Model loaded: $_isModelLoaded');
    print('✅ Session exists: ${_session != null}');
    print('✅ Labels count: ${_labels?.length ?? 0}');
    print('✅ Labels: $_labels');

    if (_session != null) {
      try {
        print('📥 Input names: ${_session!.inputNames}');
        print('📤 Output names: ${_session!.outputNames}');

        // Try to get input/output shapes
        final inputs = _session!.inputNames;
        final outputs = _session!.outputNames;

        print('📐 Number of inputs: ${inputs.length}');
        print('📐 Number of outputs: ${outputs.length}');
      } catch (e) {
        print('❌ Error getting model info: $e');
      }
    }
    print('🧪 ============ TEST END ============\n');
  }

  Future<void> _testModel() async {
    print('🧪 Testing model...');
    print('Session: ${_session != null}');
    print('Labels: ${_labels?.length}');
    print('Model loaded: $_isModelLoaded');

    if (_session != null) {
      print('Input names: ${_session!.inputNames}');
      print('Output names: ${_session!.outputNames}');
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
      print('📸 Loading image...');
      final bytes = await imageFile.readAsBytes();
      print('📸 Bytes loaded: ${bytes.length}');

      final image = img.decodeImage(bytes);

      if (image == null) throw Exception('Failed to decode image');

      print('📐 Original size: ${image.width}x${image.height}');

      // Resize to 640x640
      final resized = img.copyResize(image, width: 640, height: 640);
      print('📐 Resized to: ${resized.width}x${resized.height}');

      // Convert to float32 array [1, 3, 640, 640]
      final inputShape = [1, 3, 640, 640];
      final inputData = Float32List(1 * 3 * 640 * 640);

      int pixelIndex = 0;
      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          final pixel = resized.getPixel(x, y);

          // CHW format
          inputData[pixelIndex] = pixel.r / 255.0;
          inputData[640 * 640 + pixelIndex] = pixel.g / 255.0;
          inputData[2 * 640 * 640 + pixelIndex] = pixel.b / 255.0;

          pixelIndex++;
        }
      }

      print('✅ Preprocessed: $inputShape');
      print(
          '✅ Data range: ${inputData[0].toStringAsFixed(3)} to ${inputData[inputData.length - 1].toStringAsFixed(3)}');

      return OrtValueTensor.createTensorWithDataList(inputData, inputShape);
    } catch (e, stackTrace) {
      print('❌ Preprocessing error: $e');
      print('❌ Stack: $stackTrace');
      rethrow;
    }
  }

    Map<String, dynamic>? _processOutput(List<OrtValue?>? outputs) {
    if (outputs == null || outputs.isEmpty) {
      print('❌ No outputs from model');
      return _noDetectionResult();
    }

    try {
      final output = outputs[0];
      print('📊 Output exists: ${output != null}');

      final outputData = output?.value;
      print('📊 Data type: ${outputData.runtimeType}');

      if (outputData is! List) {
        print('❌ Unexpected output format');
        return _noDetectionResult();
      }

      // YOLOv8 format: [1, 7, 8400]
      // batch_size=1, num_classes+4=7 (3 classes + 4 bbox coords), detections=8400
      
      double maxConfidence = 0.0;
      int maxClass = 0;
      
      print('📊 Batch size: ${outputData.length}');
      
      if (outputData.isEmpty || outputData[0] is! List) {
        print('❌ Invalid batch format');
        return _noDetectionResult();
      }

      final batch = outputData[0] as List; // Get first batch
      print('📊 Number of features: ${batch.length}'); // Should be 7
      
      if (batch.length < 5) {
        print('❌ Not enough features in output');
        return _noDetectionResult();
      }

      // YOLOv8 format has detections in columns (transposed)
      // batch[0-3] = bbox coordinates (x, y, w, h)
      // batch[4-6] = class scores for 3 classes
      
      int numDetections = (batch[0] as List).length;
      print('📊 Processing $numDetections detections...');

      for (int i = 0; i < numDetections; i++) {
        // Get class scores (indices 4, 5, 6)
        List<double> classScores = [];
        for (int c = 4; c < batch.length; c++) {
          classScores.add((batch[c][i] as num).toDouble());
        }

        // Find max class score and its index
        double maxScore = classScores.reduce((a, b) => a > b ? a : b);
        int classId = classScores.indexOf(maxScore);

        if (maxScore > 0.25) { // Confidence threshold
          print('   Detection $i: class=$classId, score=${maxScore.toStringAsFixed(3)}');

          if (maxScore > maxConfidence) {
            maxConfidence = maxScore;
            maxClass = classId;
          }
        }
      }

      print('🎯 Total detections checked: $numDetections');
      print('🎯 Best detection: class=$maxClass, confidence=${maxConfidence.toStringAsFixed(3)}');

      if (maxConfidence > 0.25 && _labels != null && maxClass < _labels!.length) {
        final label = _labels![maxClass];
        print('✅ DETECTION SUCCESS: $label (${(maxConfidence * 100).toStringAsFixed(1)}%)');

        return {
          'success': true,
          'product_name': label,
          'category': label,
          'confidence': maxConfidence,
          'authenticity': _getAuthenticity(maxConfidence),
          'estimated_value': _estimateValue(label, maxConfidence),
        };
      }

      print('⚠️ No confident detection found');
      return _noDetectionResult(maxConfidence);
      
    } catch (e, stackTrace) {
      print('❌ Output processing error: $e');
      print('❌ Stack: $stackTrace');
      return null;
    }
  }

  Map<String, dynamic> _noDetectionResult([double conf = 0.0]) {
    return {
      'success': false,
      'product_name': 'No jewelry detected',
      'category': 'Unknown',
      'confidence': conf,
      'authenticity': 'Low confidence',
      'estimated_value': 'N/A',
    };
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
      'earring': 400
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
