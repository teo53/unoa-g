import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

class AppTheme {
  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: GoogleFonts.notoSansKr(fontSize: 32, fontWeight: FontWeight.w900, color: color, height: 1.5),
      displayMedium: GoogleFonts.notoSansKr(fontSize: 28, fontWeight: FontWeight.w700, color: color, height: 1.5),
      displaySmall: GoogleFonts.notoSansKr(fontSize: 24, fontWeight: FontWeight.w700, color: color, height: 1.5),
      headlineLarge: GoogleFonts.notoSansKr(fontSize: 24, fontWeight: FontWeight.w700, color: color, height: 1.5),
      headlineMedium: GoogleFonts.notoSansKr(fontSize: 20, fontWeight: FontWeight.w700, color: color, height: 1.5),
      headlineSmall: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.w700, color: color, height: 1.5),
      titleLarge: GoogleFonts.notoSansKr(fontSize: 18, fontWeight: FontWeight.w600, color: color, height: 1.5),
      titleMedium: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w600, color: color, height: 1.5),
      titleSmall: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.w600, color: color, height: 1.5),
      bodyLarge: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w400, color: color, height: 1.5),
      bodyMedium: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w400, color: color, height: 1.5),
      bodySmall: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.5),
      labelLarge: GoogleFonts.notoSansKr(fontSize: 14, fontWeight: FontWeight.w500, color: color, height: 1.5),
      labelMedium: GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w500, color: color, height: 1.5),
      labelSmall: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.w500, color: color, height: 1.5),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primarySoft,
        surface: AppColors.surfaceLight,
        error: Colors.red,
      ),
      textTheme: _buildTextTheme(AppColors.textMainLight),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMainLight),
        titleTextStyle: GoogleFonts.notoSansKr(
          color: AppColors.textMainLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        hintStyle: GoogleFonts.notoSansKr(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      extensions: const [AppColorsExtension.light],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.surfaceDark,
        error: Colors.red,
      ),
      textTheme: _buildTextTheme(AppColors.textMainDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMainDark),
        titleTextStyle: GoogleFonts.notoSansKr(
          color: AppColors.textMainDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        hintStyle: GoogleFonts.notoSansKr(
          color: Colors.grey[500],
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      extensions: const [AppColorsExtension.dark],
    );
  }
}
