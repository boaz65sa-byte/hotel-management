// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class HotelTheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final String? logoUrl;

  const HotelTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    this.logoUrl,
  });

  static const HotelTheme defaultTheme = HotelTheme(
    primary: Color(0xFF1976D2),
    secondary: Color(0xFF424242),
    accent: Color(0xFFFF6F00),
  );

  factory HotelTheme.fromJson(Map<String, dynamic> json, {String? logoUrl}) {
    return HotelTheme(
      primary: Color(int.parse((json['primary'] as String).replaceFirst('#', '0xFF'))),
      secondary: Color(int.parse((json['secondary'] as String).replaceFirst('#', '0xFF'))),
      accent: Color(int.parse((json['accent'] as String).replaceFirst('#', '0xFF'))),
      logoUrl: logoUrl,
    );
  }

  ThemeData toThemeData({bool isRtl = false}) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        tertiary: accent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
