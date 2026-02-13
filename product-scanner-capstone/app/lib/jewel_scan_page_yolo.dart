import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/onnx_service.dart';
import 'pages/nearby_stores_map_page.dart';
import '../services/supabase_service.dart';

class JewelScanPage extends StatefulWidget {
  const JewelScanPage({super.key});

  @override
  State<JewelScanPage> createState() => _JewelScanPageState();
}

class _JewelScanPageState extends State<JewelScanPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  File? _scannedImage;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  final OnnxService _onnxService = OnnxService();
  bool _isAnalyzing = false;
  bool _isModelLoading = true; // ← ADD THIS
  Map<String, dynamic>? _analysisResult;
  int? _lastScanId; // Track the last scan ID for saving store selection

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeTFLite();

    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _scanAnimationController, curve: Curves.easeInOut),
    );
  }

  void _findNearbyStores() {
    if (_analysisResult == null) {
      _showError('Please scan a product first');
      return;
    }

    final yoloLabel = _analysisResult!['category'] ??
        _analysisResult!['yolo_label'] ??
        'jewelry';
    final String productName = yoloLabel.toString().toLowerCase();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearbyStoresMapPage(
          productType: productName,
          productName: productName,
          scanId: _lastScanId,
        ),
      ),
    );
  }

  Future<void> _initializeTFLite() async {
    setState(() {
      _isModelLoading = true; // ← UPDATE STATE
    });

    try {
      await _onnxService.loadModel();
      print('✅ ONNX model ready!');

      // TEST THE MODEL
      await _onnxService.testModel();

      setState(() {
        _isModelLoading = false; // ← MODEL LOADED
      });
    } catch (e) {
      print('❌ Failed to load ONNX: $e');
      print('❌ Stack trace: ${StackTrace.current}');

      setState(() {
        _isModelLoading = false;
      });

      // Show error to user
      if (mounted) {
        _showError('Failed to load AI model. Please restart the app.');
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _onnxService.dispose();
    _cameraController?.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/user_profile');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null && _isCameraInitialized) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    }
  }

  Future<void> _takePicture() async {
    // ← ADD CHECK HERE
    if (_isModelLoading) {
      _showError('Please wait, AI model is still loading...');
      return;
    }

    if (_cameraController != null && _isCameraInitialized) {
      try {
        final XFile photo = await _cameraController!.takePicture();
        setState(() {
          _scannedImage = File(photo.path);
          _analysisResult = null;
        });
        _showScanResult();
        _analyzeImage(_scannedImage!);
      } catch (e) {
        debugPrint('Error taking picture: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    // ← ADD CHECK HERE
    if (_isModelLoading) {
      _showError('Please wait, AI model is still loading...');
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _scannedImage = File(image.path);
        _analysisResult = null;
      });
      _showScanResult();
      _analyzeImage(_scannedImage!);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      print('\n🔍 ============ ANALYSIS START ============');
      print('📁 Image path: ${imageFile.path}');

      var result = await _onnxService.predict(imageFile);

      print('📊 Result: $result');
      print('🔍 ============ ANALYSIS END ============\n');

      if (result != null) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });

        if (result['success'] == true) {
          print('✅ Detection successful!');

          // ✅ AUTO-SAVE TO SUPABASE
          await _saveResultToDatabase();
        } else {
          print('⚠️ No detection or low confidence');
        }
      } else {
        setState(() {
          _isAnalyzing = false;
        });
        _showError('Failed to analyze image');
      }
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('❌ Stack: $stackTrace');
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Error analyzing image: $e');
    }
  }

// NEW: Silent background save
  Future<void> _saveResultToDatabase() async {
    if (_analysisResult == null) return;

    try {
      final SupabaseStoreService storeService = SupabaseStoreService();
      final dynamic rawCategory = _analysisResult!['category'] ??
          _analysisResult!['yolo_label'] ??
          _analysisResult!['label'];
      final String yoloLabelStr = rawCategory != null
          ? rawCategory.toString().toLowerCase()
          : 'jewelry';
      final String productName = yoloLabelStr;

      var scanRecord = await storeService.saveScanResult(
        productName: productName,
        category: _analysisResult!['category'] ?? 'Jewelry',
        yoloLabel: yoloLabelStr,
        confidence: _analysisResult!['confidence'] is num
            ? (_analysisResult!['confidence'] as num).toDouble()
            : null,
        estimatedValue: _analysisResult!['estimated_value']?.toString(),
        authenticity: _analysisResult!['authenticity']?.toString(),
        imagePath: _scannedImage?.path,
      );

      if (scanRecord != null && scanRecord['id'] != null) {
        setState(() {
          _lastScanId = scanRecord['id'];
        });
        print('✅ Auto-saved to Supabase with ID: ${scanRecord['id']}');
      }
    } catch (e) {
      print('❌ Auto-save failed: $e');
      // Don't show error to user - silent fail
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showScanResult() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScanResultSheet(),
    );
  }

  Widget _buildScanResultSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Scan Result',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005461),
              fontFamily: 'Syne',
            ),
          ),
          const SizedBox(height: 20),

          // Scanned Image
          if (_scannedImage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0C7779), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C7779).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Image.file(
                  _scannedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          const SizedBox(height: 30),

          // Product Info - YOLO results
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      Icons.diamond_outlined,
                      'Product',
                      _isAnalyzing
                          ? 'Analyzing...'
                          : (_analysisResult?['yolo_label'] ?? 'Unknown')),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                      Icons.category_outlined,
                      'Category',
                      _isAnalyzing
                          ? 'Detecting...'
                          : (_analysisResult?['category'] ?? 'Jewelry')),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                      Icons.verified_outlined,
                      'Authenticity',
                      _isAnalyzing
                          ? 'Checking...'
                          : (_analysisResult?['authenticity'] ?? 'Pending')),
                  const SizedBox(height: 15),
                  _buildInfoRow(
                      Icons.attach_money,
                      'Est. Value',
                      _isAnalyzing
                          ? 'Calculating...'
                          : (_analysisResult?['estimated_value'] ?? 'N/A')),
                  const SizedBox(height: 15),
                  if (_analysisResult != null &&
                      _analysisResult!['confidence'] != null)
                    _buildInfoRow(Icons.analytics_outlined, 'Confidence',
                        '${(_analysisResult!['confidence'] * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _scannedImage = null;
                        _analysisResult = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side:
                          const BorderSide(color: Color(0xFF0C7779), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close, color: Color(0xFF0C7779)),
                    label: const Text(
                      'Retake',
                      style: TextStyle(
                        color: Color(0xFF0C7779),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    // Disable if we're analyzing OR if the result was already auto-saved
                    onPressed: (_isAnalyzing || _lastScanId != null)
                        ? null
                        : () {
                            Navigator.pop(context);
                            // Save result to database or local storage
                            _saveResult();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14A9A8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _lastScanId != null ? 'Saved' : 'Save',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _findNearbyStores,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C7779),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: const Text(
                      'Find Stores',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveResult() async {
    if (_analysisResult == null) {
      _showError('No scan result to save');
      return;
    }

    // Prevent duplicate manual save if auto-save already stored this scan
    if (_lastScanId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This scan was already saved.'),
          backgroundColor: Color(0xFF14A9A8),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // DEBUG: print the full analysis result so we can see which keys exist
    print('🧾 _saveResult - analysisResult: $_analysisResult');

    // Safer extraction: try several common keys that ONNX/YOLO might return
    final dynamic rawCategory = _analysisResult!['category'] ??
        _analysisResult!['yolo_label'] ??
        _analysisResult!['label'];
    final String yoloLabelStr = (rawCategory != null)
        ? rawCategory.toString().toLowerCase()
        : 'jewelry';
    print('🏷️ Resolved yoloLabel: $yoloLabelStr');

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saving scan result...'),
        backgroundColor: Color(0xFF14A9A8),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final SupabaseStoreService storeService = SupabaseStoreService();

      var scanRecord = await storeService.saveScanResult(
        productName: yoloLabelStr,
        category: _analysisResult!['category'] ??
            _analysisResult!['product_category'] ??
            'Jewelry',
        yoloLabel: yoloLabelStr,
        confidence: _analysisResult!['confidence'] is num
            ? (_analysisResult!['confidence'] as num).toDouble()
            : null,
        estimatedValue: _analysisResult!['estimated_value']?.toString(),
        authenticity: _analysisResult!['authenticity']?.toString(),
        imagePath: _scannedImage?.path,
      );

      if (scanRecord != null && scanRecord['id'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Scan result saved successfully!'),
            backgroundColor: Color(0xFF14A9A8),
          ),
        );
      } else {
        _showError('Failed to save scan result');
      }
    } catch (e) {
      print('Error in _saveResult: $e');
      _showError('Error saving result: $e');
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C7779).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0C7779).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0C7779), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF005461),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF14A9A8),
              ),
            ),
          // ← ADD MODEL LOADING OVERLAY
          if (_isModelLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF14A9A8),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading AI Model...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SCAN PRODUCT',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Syne',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scanning Frame with Animation
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF14A9A8),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner Decorations
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  // Animated Scan Line
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value * 280,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF14A9A8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF14A9A8).withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Position the jewelry within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gallery Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: IconButton(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library,
                        color: Colors.white, size: 28),
                    iconSize: 50,
                  ),
                ),

                const SizedBox(width: 40),

                // Capture Button
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14A9A8), Color(0xFF0C7779)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF14A9A8).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 35),
                  ),
                ),

                const SizedBox(width: 40),

                // Switch Camera Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Switch camera logic
                    },
                    icon: const Icon(Icons.flip_camera_ios,
                        color: Colors.white, size: 28),
                    iconSize: 50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Bottom Navigation
  Widget _buildBottomNavigationBar() {
    return SizedBox(
      height: 85,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C7779),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                    Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                const SizedBox(width: 80),
                _buildNavItem(Icons.person_outline_rounded,
                    Icons.person_rounded, 'Profile', 2),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -14,
            child: Center(
              child: GestureDetector(
                onTap: () => _onItemTapped(1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF14A9A8), Color(0xFF0C7779)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0C7779).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData iconInactive, IconData iconActive, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          height: 85,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Icon(
                  isSelected ? iconActive : iconInactive,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  letterSpacing: 1.2,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
