import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecureAttendApp());
}

class SecureAttendApp extends StatelessWidget {
  const SecureAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureAttend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2347D4),
        ),
        useMaterial3: true,
      ),
      // App always starts at SplashScreen
      // SplashScreen handles routing to Dashboard or Landing
      home: const SplashScreen(),
    );
  }
}
