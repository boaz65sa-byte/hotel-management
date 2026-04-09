// lib/core/theme/theme_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Holds the active ThemeData for the current hotel.
/// Set after login using the hotel's theme string from Supabase.
/// Defaults to clean_blue until login completes.
final hotelThemeProvider = StateProvider<ThemeData>((ref) {
  return AppTheme.forHotel('warm');
});
