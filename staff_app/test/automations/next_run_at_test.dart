import 'package:flutter_test/flutter_test.dart';

// Mirrors the Edge Function recurrence logic in Dart
Duration recurrenceDuration(String recurrence) => switch (recurrence) {
  'daily'     => const Duration(days: 1),
  'weekly'    => const Duration(days: 7),
  'monthly'   => const Duration(days: 30),
  'quarterly' => const Duration(days: 90),
  _           => const Duration(days: 1),
};

void main() {
  test('daily recurrence adds 1 day', () {
    expect(recurrenceDuration('daily'), const Duration(days: 1));
  });

  test('weekly recurrence adds 7 days', () {
    expect(recurrenceDuration('weekly'), const Duration(days: 7));
  });

  test('quarterly recurrence adds 90 days', () {
    expect(recurrenceDuration('quarterly'), const Duration(days: 90));
  });
}
