import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/locale_provider.dart';

void main() {
  test('default locale is Hebrew', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(localeProvider).languageCode, 'he');
  });

  test('locale can be changed to Arabic', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(localeProvider.notifier).state = const Locale('ar');
    expect(container.read(localeProvider).languageCode, 'ar');
  });
}
