// lib/core/theme/theme_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

final hotelThemeProvider = StateProvider<HotelTheme>((ref) {
  return HotelTheme.defaultTheme;
});
