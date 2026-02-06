import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'advertise_page.dart';
import 'register_page.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'forgotpassword_page.dart';
import 'user_profile.dart';
import 'jewel_scan_page_yolo.dart';
import 'scan_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProductScan',
      theme: ThemeData(
        fontFamily: 'Syne',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C7779),
        ),
        useMaterial3: true,
      ),

      home: FutureBuilder<bool>(
        future: _getInitialPage(supabase),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final bool showAdvertise = snapshot.data ?? true;
          return showAdvertise ? const AdvertisePage() : const LoginPage();
        },
      ),
      routes: {
        '/advertise': (context) => const AdvertisePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/user_profile': (context) => UserProfilePage(),
        '/scan': (context) => const JewelScanPage(),
        '/history': (context) => const ScanHistoryPage(),
      },
    );
  }

  /// Determines whether to show AdvertisePage
  Future<bool> _getInitialPage(SupabaseClient supabase) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user already accepted terms
    final acceptedTerms = prefs.getBool('accepted_terms') ?? false;

    if (!acceptedTerms) {
      // User has not accepted terms (show AdvertisePage)
      return true;
    }

    // User already accepted terms (check if logged in)
    final session = supabase.auth.currentSession;
    if (session != null) {
      // Logged in (go to HomePage)
      return false;
    }

    // Not logged in (go to LoginPage)
    return false;
  }
}
