import 'package:flutter/material.dart';

class AppTheme {
  static const primaryAction = Color(0xFF5F33FF);
  static const lightCanvas = Color(0xFFF5F5FA);
  static const darkCanvas = Color(0xFF0F0F1A);
  static const darkCard = Color(0xFF1C1C2E);
  static const textMain = Color(0xFF1A1A37);
  static const textMuted = Color(0xFF8A8A9E);
  static const success = Color(0xFF2ED47A);
  static const danger = Color(0xFFFF5B86);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryAction,
      brightness: Brightness.light,
      surface: lightCanvas,
    );
    return _theme(scheme).copyWith(
      scaffoldBackgroundColor: lightCanvas,
      textTheme: _textTheme(Brightness.light),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B6CFF),
      brightness: Brightness.dark,
      surface: darkCanvas,
    );
    return _theme(scheme).copyWith(
      scaffoldBackgroundColor: darkCanvas,
      textTheme: _textTheme(Brightness.dark),
    );
  }

  static ThemeData _theme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor:
            colorScheme.brightness == Brightness.dark ? Colors.white : textMain,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        filled: true,
        fillColor: colorScheme.brightness == Brightness.dark
            ? darkCard
            : Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.brightness == Brightness.dark ? darkCard : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        shadowColor: primaryAction.withValues(alpha: 0.08),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryAction,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final main = brightness == Brightness.dark ? const Color(0xFFEAEAF2) : textMain;
    final muted = brightness == Brightness.dark ? const Color(0xFFB8B8C8) : textMuted;
    return TextTheme(
      headlineMedium: TextStyle(color: main, fontWeight: FontWeight.w800),
      headlineSmall: TextStyle(color: main, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(color: main, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(color: main, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: main),
      bodySmall: TextStyle(color: muted),
      labelMedium: TextStyle(color: muted, fontWeight: FontWeight.w600),
    );
  }
}
