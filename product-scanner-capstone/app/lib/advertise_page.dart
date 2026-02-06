import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AdvertisePage extends StatefulWidget {
  const AdvertisePage({super.key});

  static const Color primaryDark = Color(0xFF005461);
  static const Color primaryMedium = Color(0xFF0C7779);
  static const Color primaryLight = Color(0xFF249E94);

  @override
  State<AdvertisePage> createState() => _AdvertisePageState();
}

class _AdvertisePageState extends State<AdvertisePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;

  late AnimationController _spinnerController;
  late Animation<double> _fadeText;

  @override
  void initState() {
    super.initState();

    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _fadeText = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _spinnerController,
        curve: Curves.easeInOut,
      ),
    );

    // Show loader first
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _spinnerController.stop();
      }
    });
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Terms & Conditions",
            style: TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w400,
            ),
          ),
          content: const SingleChildScrollView(
            child: Text(
              "By continuing, you agree to ProductScan’s Terms & Conditions.\n\n"
              "• Your data is securely handled\n"
              "• You agree to our privacy policy\n"
              "• Content is for personal use only\n\n"
              "Thank you for choosing ProductScan.",
              style: TextStyle(fontSize: 18, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "DECLINE",
                style: TextStyle(color: AdvertisePage.primaryDark),
              ),
            ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdvertisePage.primaryMedium,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  // Save that user accepted terms
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('accepted_terms', true);

                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/register');
                },
                child: const Text(
                  "ACCEPT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdvertisePage.primaryMedium,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Flexible(
                    flex: 5,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: MediaQuery.of(context).size.width * 1.05,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 4), 

                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: const Text(
                      "ProductScan",
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                
                    const SizedBox(height: 4),

                    Text(
                      "Luxury that speaks for you",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _showTermsDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "GET STARTED",
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AdvertisePage.primaryDark,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      "By continuing, you agree to our Terms & Conditions",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= LOADING OVERLAY =================
          if (_isLoading)
            Container(
              color: AdvertisePage.primaryMedium,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      turns: _spinnerController,
                      child: const SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _fadeText,
                      child: const Text(
                        "Loading...",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please wait",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
