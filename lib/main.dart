import 'package:flutter/material.dart';
import 'package:fresh_car/pages/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fresh_car/config/supabase_config.dart';
import 'package:fresh_car/pages/login.dart';
import 'package:fresh_car/pages/notification_service.dart'; // Import the notification service
import 'package:fresh_car/pages/terms_conditions_screen.dart'; // Import the new terms screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  // Initialize notification service
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkTermsAcceptance();
  }

  Future<void> _checkTermsAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final termsAccepted = prefs.getBool('termsAccepted') ?? false;
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  !termsAccepted
                      ? const TermsConditionsScreen()
                      : isLoggedIn
                      ? const HomePage()
                      : const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F3),
      body: Center(
        child: Image.asset(
          'assets/icons/trademaxlg.png',
          width: 100,
          height: 80,
        ),
      ),
    );
  }
}
