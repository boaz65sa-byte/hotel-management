import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme.forHotel', () {
    test('clean_blue returns light theme with blue primary', () {
      final theme = AppTheme.forHotel('clean_blue');
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF1E40AF));
    });

    test('luxury returns dark theme with gold primary', () {
      final theme = AppTheme.forHotel('luxury');
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFE4B800));
    });

    test('unknown value falls back to clean_blue', () {
      final theme = AppTheme.forHotel('unknown');
      expect(theme.brightness, Brightness.light);
    });

    test('clean_blue scaffold background is correct', () {
      final theme = AppTheme.forHotel('clean_blue');
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF0F4FF));
    });

    test('luxury scaffold background is dark', () {
      final theme = AppTheme.forHotel('luxury');
      expect(theme.scaffoldBackgroundColor, const Color(0xFF1A1A2E));
    });
  });
}
