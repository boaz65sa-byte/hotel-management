import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme.forHotel', () {
    test('clean_blue returns warm light theme with orange primary', () {
      final theme = AppTheme.forHotel('clean_blue');
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFFEA580C));
    });

    test('luxury returns navy dark theme with gold primary', () {
      final theme = AppTheme.forHotel('luxury');
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFFC9A84C));
    });

    test('unknown value falls back to warm light theme', () {
      final theme = AppTheme.forHotel('unknown');
      expect(theme.brightness, Brightness.light);
    });

    test('clean_blue scaffold background is warm cream', () {
      final theme = AppTheme.forHotel('clean_blue');
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFDF6F0));
    });

    test('luxury scaffold background is navy dark', () {
      final theme = AppTheme.forHotel('luxury');
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0A1628));
    });
  });
}
