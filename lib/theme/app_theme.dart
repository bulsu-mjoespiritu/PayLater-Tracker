import 'package:flutter/material.dart';

/// Centralized color palette & theme for the PayLater Tracker app.
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF1652F0);
  static const Color darkBlue = Color(0xFF0F3FC4);
  static const Color lightBlueBg = Color(0xFFEFF3FF);

  static const Color green = Color(0xFF16A34A);
  static const Color lightGreenBg = Color(0xFFE9F9EF);

  static const Color red = Color(0xFFE0342A);
  static const Color lightRedBg = Color(0xFFFDEDEC);

  static const Color orange = Color(0xFFF3701A);
  static const Color lightOrangeBg = Color(0xFFFFF1E6);

  static const Color grey = Color(0xFF8A93A6);
  static const Color lightGreyBg = Color(0xFFF4F5F7);

  static const Color textDark = Color(0xFF14171F);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE7E9EE);

  static const Color scaffoldBg = Color(0xFFF6F7FB);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGreyBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
