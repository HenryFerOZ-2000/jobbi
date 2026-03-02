import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Base font family
  static TextStyle get _baseStyle => GoogleFonts.inter(
        color: AppColors.textPrimary,
      );

  // Headings - Large and Bold
  static TextStyle get h1 => _baseStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get h2 => _baseStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.3,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => _baseStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get h4 => _baseStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get h5 => _baseStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get h6 => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // Body Text
  static TextStyle get bodyLarge => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 1.6,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyMedium => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.6,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => _baseStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  // Labels - For buttons and chips
  static TextStyle get labelLarge => _baseStyle.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => _baseStyle.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => _baseStyle.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );

  // Caption - Small text
  static TextStyle get caption => _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  static TextStyle get captionSmall => _baseStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        color: AppColors.textSoft,
      );

  // Special - Price text
  static TextStyle get priceSmall => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      );

  static TextStyle get priceLarge => _baseStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      );

  // Special - Title for cards
  static TextStyle get cardTitle => _baseStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardSubtitle => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: AppColors.textSecondary,
      );
}
