// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData forHotel(String theme) {
    switch (theme) {
      case 'navy':
      case 'luxury':
        return _navyTheme;
      case 'warm':
      case 'clean_blue':
      default:
        return _warmTheme;
    }
  }

  // ── יום — Warm Hospitality (D) ──────────────────────────────────────────
  static final ThemeData _warmTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFDF6F0),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary:          Color(0xFFEA580C),
      onPrimary:        Colors.white,
      primaryContainer: Color(0xFFFFEDD5),
      onPrimaryContainer: Color(0xFF7C2D12),
      secondary:        Color(0xFFC2410C),
      onSecondary:      Colors.white,
      secondaryContainer: Color(0xFFFED7AA),
      onSecondaryContainer: Color(0xFF7C2D12),
      surface:          Color(0xFFFFFFFF),
      onSurface:        Color(0xFF1F2937),
      surfaceContainerHighest: Color(0xFFFEF3E8),
      onSurfaceVariant: Color(0xFF6B7280),
      outline:          Color(0xFFFED7AA),
      outlineVariant:   Color(0xFFFBBF94),
      error:            Color(0xFFDC2626),
      onError:          Colors.white,
      errorContainer:   Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
      shadow:           Color(0xFF000000),
      scrim:            Color(0xFF000000),
      inverseSurface:   Color(0xFF1F2937),
      onInverseSurface: Color(0xFFFDF6F0),
      inversePrimary:   Color(0xFFFBBF94),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFEA580C),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 1,
      shadowColor: const Color(0x1FEA580C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFFED7AA), width: 1),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFFFEDD5),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: Color(0xFFFFEDD5),
      side: BorderSide(color: Color(0xFFFED7AA)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFEA580C),
      foregroundColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFEA580C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFEF3E8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFED7AA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFED7AA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEA580C), width: 2),
      ),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
          color: Color(0xFF1F2937), fontWeight: FontWeight.w800),
      titleMedium: TextStyle(
          color: Color(0xFF1F2937), fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: Color(0xFF374151)),
      bodySmall: TextStyle(color: Color(0xFF6B7280)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFFED7AA)),
  );

  // ── לילה — Navy Professional (A) ───────────────────────────────────────
  static final ThemeData _navyTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A1628),
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary:          Color(0xFFC9A84C),
      onPrimary:        Color(0xFF0A1628),
      primaryContainer: Color(0xFF1A3160),
      onPrimaryContainer: Color(0xFFC9A84C),
      secondary:        Color(0xFF2563EB),
      onSecondary:      Colors.white,
      secondaryContainer: Color(0xFF1E3A8A),
      onSecondaryContainer: Color(0xFF93C5FD),
      surface:          Color(0xFF0F1F3D),
      onSurface:        Color(0xFFE2E8F0),
      surfaceContainerHighest: Color(0xFF1A3160),
      onSurfaceVariant: Color(0xFF7C9DC4),
      outline:          Color(0xFF2D4A7A),
      outlineVariant:   Color(0xFF1E3A6A),
      error:            Color(0xFFF87171),
      onError:          Color(0xFF7F1D1D),
      errorContainer:   Color(0xFF450A0A),
      onErrorContainer: Color(0xFFFCA5A5),
      shadow:           Color(0xFF000000),
      scrim:            Color(0xFF000000),
      inverseSurface:   Color(0xFFE2E8F0),
      onInverseSurface: Color(0xFF0A1628),
      inversePrimary:   Color(0xFF92400E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F1F3D),
      foregroundColor: Color(0xFFC9A84C),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF0F1F3D),
      elevation: 4,
      shadowColor: const Color(0x40C9A84C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2D4A7A), width: 1),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF0F1F3D),
      indicatorColor: Color(0xFF1A3160),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: const ChipThemeData(
      selectedColor: Color(0xFF1A3160),
      side: BorderSide(color: Color(0xFF2D4A7A)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFC9A84C),
      foregroundColor: Color(0xFF0A1628),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFC9A84C),
        foregroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A3160),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D4A7A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D4A7A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC9A84C), width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF7C9DC4)),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
          color: Color(0xFFE2E8F0), fontWeight: FontWeight.w800),
      titleMedium: TextStyle(
          color: Color(0xFFE2E8F0), fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
      bodySmall: TextStyle(color: Color(0xFF7C9DC4)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF2D4A7A)),
  );
}
