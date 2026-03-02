import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Modern Turquoise/Cyan Palette (inspired by travel app design)
  static const Color primary = Color(0xFF5CC6BA);
  static const Color primaryDark = Color(0xFF4AB5A9);
  static const Color primaryLight = Color(0xFFE8F6F5);
  static const Color secondary = Color(0xFF6DD5C8);

  // Backgrounds - Clean and Minimal
  static const Color scaffoldBackground = Color(0xFFE8F6F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1D1E);
  static const Color textSecondary = Color(0xFF3A3F41);
  static const Color textTertiary = Color(0xFF6D767D);
  static const Color textSoft = Color(0xFF9CA4AB);

  // Status Colors
  static const Color success = Color(0xFF28C2A0);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Chip Colors
  static const Color chipGreen = Color(0xFFE7FAF6);
  static const Color chipGreenText = Color(0xFF22A889);
  static const Color chipBlue = Color(0xFFE3F2FD);
  static const Color chipBlueText = Color(0xFF1976D2);
  static const Color chipOrange = Color(0xFFFFF3E0);
  static const Color chipOrangeText = Color(0xFFF57C00);
  static const Color chipPurple = Color(0xFFF3E5F5);
  static const Color chipPurpleText = Color(0xFF7B1FA2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF28C2A0), Color(0xFF21D6B4)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF21D6B4), Color(0xFF1AC9A8)],
  );

  // Shadows - Premium Soft Shadows
  static List<BoxShadow> get shadowSoft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowStrong => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // Hover Colors
  static Color get hoverPrimary => primary.withValues(alpha: 0.9);
  static Color get hoverSecondary => secondary.withValues(alpha: 0.9);
}
