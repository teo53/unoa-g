import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Pretendard font family (loaded via web/index.html)
  static const String fontFamily = 'Pretendard';

  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w900, color: color),
      displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700, color: color),
      displaySmall: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, color: color),
      headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.w700, color: color),
      headlineMedium: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: color),
      headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: color),
      titleLarge: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleMedium: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleSmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: color),
      bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w400, color: color),
      bodySmall: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: color),
      labelLarge: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: color),
      labelMedium: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: color),
      labelSmall: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: color),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primarySoft,
        surface: AppColors.surfaceLight,
        error: Colors.red,
      ),
      textTheme: _buildTextTheme(AppColors.textMainLight),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMainLight),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textMainLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
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
      fontFamily: fontFamily,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.surfaceDark,
        error: Colors.red,
      ),
      textTheme: _buildTextTheme(AppColors.textMainDark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMainDark),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textMainDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.grey[500],
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      extensions: const [AppColorsExtension.dark],
    );
  }
}
