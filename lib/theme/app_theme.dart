import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Accent colors that stay the same in light and dark mode.
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF1652F0);
  static const Color darkBlue = Color(0xFF0F3FC4);
  static const Color grey = Color(0xFF8A93A6);
}

/// Every color that changes between light and dark mode lives here.
/// Read it anywhere with `context.pal`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.scaffold,
    required this.surface,
    required this.text,
    required this.textMuted,
    required this.divider,
    required this.fieldBg,
    required this.blue,
    required this.blueBg,
    required this.green,
    required this.greenBg,
    required this.red,
    required this.redBg,
    required this.orange,
    required this.orangeBg,
    required this.greyBg,
  });

  final bool isDark;
  final Color scaffold;
  final Color surface;
  final Color text;
  final Color textMuted;
  final Color divider;
  final Color fieldBg;
  final Color blue;
  final Color blueBg;
  final Color green;
  final Color greenBg;
  final Color red;
  final Color redBg;
  final Color orange;
  final Color orangeBg;
  final Color greyBg;

  static const AppPalette light = AppPalette(
    isDark: false,
    scaffold: Color(0xFFF6F7FB),
    surface: Colors.white,
    text: Color(0xFF14171F),
    textMuted: Color(0xFF6B7280),
    divider: Color(0xFFE7E9EE),
    fieldBg: Color(0xFFF4F5F7),
    blue: Color(0xFF1652F0),
    blueBg: Color(0xFFEFF3FF),
    green: Color(0xFF16A34A),
    greenBg: Color(0xFFE9F9EF),
    red: Color(0xFFE0342A),
    redBg: Color(0xFFFDEDEC),
    orange: Color(0xFFF3701A),
    orangeBg: Color(0xFFFFF1E6),
    greyBg: Color(0xFFF4F5F7),
  );

  static const AppPalette dark = AppPalette(
    isDark: true,
    scaffold: Color(0xFF0E1117),
    surface: Color(0xFF181C25),
    text: Color(0xFFF1F3F8),
    textMuted: Color(0xFF9AA3B5),
    divider: Color(0xFF2A3040),
    fieldBg: Color(0xFF232837),
    blue: Color(0xFF6C93FF),
    blueBg: Color(0xFF1B2A52),
    green: Color(0xFF34D07A),
    greenBg: Color(0xFF143324),
    red: Color(0xFFFF6B5E),
    redBg: Color(0xFF3A1B1B),
    orange: Color(0xFFFF9552),
    orangeBg: Color(0xFF3A2614),
    greyBg: Color(0xFF232837),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final p = isDark ? AppPalette.dark : AppPalette.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: brightness,
    ).copyWith(primary: p.blue, surface: p.surface);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: p.scaffold,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.text,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: p.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.blue,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.blue,
        linearTrackColor: p.greyBg,
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
        fillColor: p.fieldBg,
        hintStyle: TextStyle(color: p.textMuted),
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
          borderSide: BorderSide(color: p.blue, width: 1.5),
        ),
      ),
    );
  }
}
