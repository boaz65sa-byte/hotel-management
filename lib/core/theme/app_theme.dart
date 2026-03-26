// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData forHotel(String theme) {
    switch (theme) {
      case 'luxury':
        return _luxuryTheme;
      default:
        return _cleanBlueTheme;
    }
  }

  static final ThemeData _cleanBlueTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F4FF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E40AF),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF1E40AF),
      secondary: const Color(0xFF3B82F6),
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E40AF),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFDBEAFE),
    ),
  );

  static final ThemeData _luxuryTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE4B800),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFE4B800),
      secondary: const Color(0xFFFFD700),
      surface: const Color(0xFF16213E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A2E),
      foregroundColor: Color(0xFFE4B800),
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF16213E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x40E4B800)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF16213E),
      indicatorColor: Color(0x30E4B800),
    ),
  );
}
