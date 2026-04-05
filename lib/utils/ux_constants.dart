import 'package:flutter/material.dart';

class UXConstants {
  // Brand Colors (Elite University Palette)
  static const Color primary = Color(0xFF2C2C2C); // Charcoal
  static const Color primaryDark = Color(0xFF111827);
  static const Color primaryLight = Color(0xFFEAECF0);
  
  static const Color secondary = Color(0xFFFFFFFF); // White Surfaces
  static const Color accent = Color(0xFF059669);    // Muted Green
  static const Color warning = Color(0xFFF59E0B);
  static const Color critical = Color(0xFFEF4444);
  
  // Background Colors
  static const Color bgLight = Color(0xFFF5F5F5); // Soft Light Gray
  static const Color surface = Colors.white;
  
  // Text Colors
  static const Color textHigh = Color(0xFF111827); // Dark Gray
  static const Color textMed = Color(0xFF6B7280);  // Muted Gray
  static const Color textLow = Color(0xFF9CA3AF);  // Light Gray

  
  // Design Tokens
  static BorderRadius radius12 = BorderRadius.circular(12);
  static BorderRadius radius16 = BorderRadius.circular(16);
  static BorderRadius radius20 = BorderRadius.circular(20);
  static BorderRadius radius24 = BorderRadius.circular(24);
  
  static List<BoxShadow> shadowSoft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: primary.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static TextStyle heading = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: textHigh,
  );

  static TextStyle subHeading = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textMed,
  );
}
