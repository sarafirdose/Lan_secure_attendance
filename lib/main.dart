import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/migration_service.dart';
import 'services/app_state_service.dart';
import 'services/notification_service.dart';
import 'services/teacher_service.dart';
import 'services/background_sync_service.dart';

void main() async {
  // Ensure Flutter engine is ready for plugin calls
  WidgetsFlutterBinding.ensureInitialized();
  
  // Custom Error Boundary to show helpful message instead of black screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.blue, size: 64),
                const SizedBox(height: 16),
                const Text('System Encountered an Issue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(details.exceptionAsString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
                  child: const Text('Retry Launch', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Run app immediately with Splash as the first frame
  runApp(const SecureAttendApp());

  // Non-blocking initialization of heavy services
  try {
    _initializeServices();
  } catch (e) {
    debugPrint('Service Initialization Error: $e');
  }
}

Future<void> _initializeServices() async {
  // Initialize Notifications
  final notifications = NotificationService();
  await notifications.init().catchError((e) => debugPrint('Notification Init Error: $e'));
  
  // Database Migrations
  await MigrationService.runMigrationOnFirstLaunch().catchError((e) => debugPrint('Migration Error: $e'));
  
  // Sync reminders in the background
  TeacherService.syncNotificationReminders().catchError((e) => debugPrint('Sync Reminders Error: $e'));
  
  // Background Workers - Use try-catch specifically for Workmanager on Android
  try {
    await BackgroundSyncService.initialize();
    BackgroundSyncService.registerPeriodicRiskAssessment();
  } catch (e) {
    debugPrint('Workmanager Initialization Error (Possibly APK/Hardware limitation): $e');
  }
}

class SecureAttendApp extends StatelessWidget {
  const SecureAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureAttend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Premium Institutional Slate & Sapphire Palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A), 
          primary: const Color(0xFF0F172A), // Midnight Navy
          secondary: const Color(0xFF1E293B), // Slate Slate
          surface: Colors.white,
          error: const Color(0xFFE11D48), // Rose Red
          outline: const Color(0xFFE2E8F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Modern off-white background
        
        // Elite Tiered Typography (Outfit for Display, Inter for Body)
        textTheme: GoogleFonts.interTextTheme(ThemeData().textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
          displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          displaySmall: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
          titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF475569)),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
        ),
        
        // Modern Floating Action Button (Glass-Navy)
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),

        // Premium AppBar Design (Clean & Flat)
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false, // Professional left-aligned titles
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
        ),
        
        // Professional Card Design (High Radius)
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
          ),
        ),
        
        // Premium ElevatedButton Style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0, // Flat design
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
          ),
        ),
        
        // Modern Input Field Design (Clean Borders)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
          ),
          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          prefixIconColor: const Color(0xFF64748B),
        ),
      ),
      scaffoldMessengerKey: AppStateService().scaffoldMessengerKey,
      home: const SplashScreen(),
    );
  }
}
