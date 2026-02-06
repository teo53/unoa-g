import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle get _baseStyle => GoogleFonts.notoSansKr();

  // Display
  static TextStyle displayLarge(Color color) => _baseStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -0.5,
        height: 1.5,
      );

  static TextStyle displayMedium(Color color) => _baseStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
        height: 1.5,
      );

  // Headings
  static TextStyle headlineLarge(Color color) => _baseStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.5,
      );

  static TextStyle headlineMedium(Color color) => _baseStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.5,
      );

  static TextStyle headlineSmall(Color color) => _baseStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.5,
      );

  // Body
  static TextStyle bodyLarge(Color color) => _baseStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium(Color color) => _baseStyle.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodySmall(Color color) => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  // Labels
  static TextStyle labelLarge(Color color) => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      );

  static TextStyle labelMedium(Color color) => _baseStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      );

  static TextStyle labelSmall(Color color) => _baseStyle.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      );

  // Caption
  static TextStyle caption(Color color) => _baseStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      );

  // Button
  static TextStyle button(Color color) => _baseStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.5,
      );
}
