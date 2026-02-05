import 'package:flutter/material.dart';

class AdvertisePage extends StatelessWidget {
  const AdvertisePage({super.key});

  static const Color primaryDark = Color(0xFF005461);
  static const Color primaryMedium = Color(0xFF0C7779);
  static const Color primaryLight = Color(0xFF249E94);

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
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "DECLINE",
                style: const TextStyle(color: Color(0xFF005461)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
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
      backgroundColor: primaryMedium,
      body: SafeArea(
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
                    width: MediaQuery.of(context).size.width * 0.95,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 1),

                // App Name
                const Text(
                  "ProductScan",
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 6,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Luxury that speaks for you",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1,
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
                      elevation: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "GET STARTED",
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF005461),
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF005461),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Terms hint
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
    );
  }
}
