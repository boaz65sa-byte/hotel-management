import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hotel_app/core/theme/app_theme.dart';

void main() {
  test('HotelTheme parses hex colors from JSON', () {
    final theme = HotelTheme.fromJson({
      'primary': '#1976D2',
      'secondary': '#424242',
      'accent': '#FF6F00',
    });
    expect(theme.primary, const Color(0xFF1976D2));
    expect(theme.secondary, const Color(0xFF424242));
    expect(theme.accent, const Color(0xFFFF6F00));
  });

  test('defaultTheme is valid', () {
    final td = HotelTheme.defaultTheme.toThemeData();
    expect(td, isA<ThemeData>());
  });
}
