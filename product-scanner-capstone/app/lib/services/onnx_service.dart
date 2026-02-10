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
      const assetFileName = 'assets/best_cleaned.onnx';
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
      final outputData = output?.value;

      if (outputData is! List) {
        print('❌ Unexpected output format');
        return _noDetectionResult();
      }

      if (outputData.isEmpty || outputData[0] is! List) {
        return _noDetectionResult();
      }

      final batch = outputData[0] as List;
      if (batch.length < 5) {
        return _noDetectionResult();
      }

      int numDetections = (batch[0] as List).length;
      print('📊 Processing $numDetections detections...');

      // ✅ STRICTER THRESHOLDS
      const double DETECTION_THRESHOLD = 0.50;
      const double MINIMUM_CONFIDENCE = 0.65;
      const int MINIMUM_DETECTIONS = 5;
      const double CONSENSUS_RATIO = 0.6; // 60% must agree

      // Track detections per class
      Map<int, List<double>> classDetections = {
        0: [], // earring
        1: [], // necklace
        2: [], // ring
      };

      Map<int, int> classVotes = {0: 0, 1: 0, 2: 0};
      int totalValidDetections = 0;

      // Collect all valid detections
      for (int i = 0; i < numDetections; i++) {
        List<double> classScores = [];
        for (int c = 4; c < batch.length; c++) {
          classScores.add((batch[c][i] as num).toDouble());
        }

        double maxScore = classScores.reduce((a, b) => a > b ? a : b);
        int classId = classScores.indexOf(maxScore);

        if (maxScore > DETECTION_THRESHOLD) {
          classDetections[classId]?.add(maxScore);
          classVotes[classId] = (classVotes[classId] ?? 0) + 1;
          totalValidDetections++;
        }
      }

      // 🔍 DETAILED DEBUG
      print('\n📊 ========== DETECTION SUMMARY ==========');
      print(
          '🔵 EARRING (class 0): ${classDetections[0]?.length ?? 0} detections, ${classVotes[0]} votes');
      if (classDetections[0]!.isNotEmpty) {
        print(
            '   Top scores: ${classDetections[0]!.take(3).map((s) => s.toStringAsFixed(3)).join(", ")}');
      }

      print(
          '🟢 NECKLACE (class 1): ${classDetections[1]?.length ?? 0} detections, ${classVotes[1]} votes');
      if (classDetections[1]!.isNotEmpty) {
        print(
            '   Top scores: ${classDetections[1]!.take(3).map((s) => s.toStringAsFixed(3)).join(", ")}');
      }

      print(
          '🔴 RING (class 2): ${classDetections[2]?.length ?? 0} detections, ${classVotes[2]} votes');
      if (classDetections[2]!.isNotEmpty) {
        print(
            '   Top scores: ${classDetections[2]!.take(3).map((s) => s.toStringAsFixed(3)).join(", ")}');
      }

      print('📈 Total valid detections: $totalValidDetections');
      print('==========================================\n');

      // ✅ VALIDATION 1: Enough detections?
      if (totalValidDetections < MINIMUM_DETECTIONS) {
        print(
            '❌ REJECTED: Not enough detections ($totalValidDetections < $MINIMUM_DETECTIONS)');
        return _noDetectionResult();
      }

      // ✅ VALIDATION 2: Clear consensus?
      int maxVotes = classVotes.values.reduce((a, b) => a > b ? a : b);
      if (maxVotes < totalValidDetections * CONSENSUS_RATIO) {
        print(
            '❌ REJECTED: No consensus (${(maxVotes / totalValidDetections * 100).toStringAsFixed(1)}% < ${CONSENSUS_RATIO * 100}%)');
        return _noDetectionResult();
      }

      // Find winning class
      int winningClass =
          classVotes.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // ✅ VALIDATION 3: Winning class must have good scores
      List<double> winningScores = classDetections[winningClass]!
          .where((s) => s > MINIMUM_CONFIDENCE)
          .toList();

      if (winningScores.isEmpty) {
        print('❌ REJECTED: No scores above minimum confidence');
        return _noDetectionResult();
      }

      // ✅ VALIDATION 4: Use AVERAGE of top scores (more robust)
      winningScores.sort((a, b) => b.compareTo(a));
      List<double> topScores = winningScores.take(5).toList();
      double avgConfidence =
          topScores.reduce((a, b) => a + b) / topScores.length;

      print('🎯 WINNER: class=$winningClass (${_labels?[winningClass]})');
      print(
          '   Votes: $maxVotes/$totalValidDetections (${(maxVotes / totalValidDetections * 100).toStringAsFixed(1)}%)');
      print('   Max confidence: ${winningScores.first.toStringAsFixed(3)}');
      print('   Avg confidence: ${avgConfidence.toStringAsFixed(3)}');

      // Final confidence check
      if (avgConfidence < MINIMUM_CONFIDENCE) {
        print(
            '❌ REJECTED: Average confidence too low (${avgConfidence.toStringAsFixed(3)} < $MINIMUM_CONFIDENCE)');
        return _noDetectionResult(avgConfidence);
      }

      // ✅ SUCCESS - Return result
      if (_labels != null && winningClass < _labels!.length) {
        final label = _labels![winningClass].trim(); // ← Ensure trimmed
        print(
            '✅ FINAL DETECTION: "$label" with ${avgConfidence.toStringAsFixed(3)} confidence\n');

        return {
          'success': true,
          'product_name': label,
          'category': label,
          'confidence': avgConfidence, // Use averaged confidence
          'authenticity': _getAuthenticity(avgConfidence),
          'estimated_value': _estimateValue(label, avgConfidence),
          'votes': maxVotes,
          'total_detections': totalValidDetections,
        };
      }

      return _noDetectionResult();
    } catch (e, stackTrace) {
      print('❌ Output processing error: $e');
      print('❌ Stack: $stackTrace');
      return null;
    }
  }

  Map<String, dynamic> _noDetectionResult([double conf = 0.0]) {
    String message = 'No jewelry detected';

    if (conf > 0.0 && conf < 0.40) {
      message = 'Low confidence - not clear jewelry';
    } else if (conf >= 0.40 && conf < 0.65) {
      message = 'Uncertain detection - try better lighting/angle';
    }

    return {
      'success': false,
      'product_name': message,
      'category': 'Unknown',
      'confidence': conf,
      'authenticity': 'Not detected',
      'estimated_value': 'N/A',
    };
  }

  String _getAuthenticity(double confidence) {
    if (confidence > 0.85) return "High Confidence - Likely Authentic";
    if (confidence > 0.65) return "Medium Confidence - Needs Verification";
    return "Low Confidence - Expert Review Recommended";
  }

  String _estimateValue(String category, double confidence) {
    print('💰 Calculating price for: "$category"');

    Map<String, int> baseValues = {
      'ring': 800,
      'necklace': 600,
      'earring': 400,
    };

    int base = baseValues[category] ?? 500;

    print('💰 Base value: ₱$base');

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
