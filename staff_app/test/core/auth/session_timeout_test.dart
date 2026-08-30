import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/auth/session_timeout.dart';

void main() {
  test('SessionTimeoutService calls onTimeout after duration', () async {
    bool triggered = false;
    final service = SessionTimeoutService(
      timeoutMinutes: 0, // instant for test (Duration(minutes: 0) = immediate)
      onTimeout: () => triggered = true,
    );
    service.resetTimer();
    await Future.delayed(const Duration(milliseconds: 50));
    expect(triggered, true);
    service.dispose();
  });

  test('resetTimer cancels previous timer', () async {
    int count = 0;
    final service = SessionTimeoutService(
      timeoutMinutes: 0,
      onTimeout: () => count++,
    );
    service.resetTimer();
    service.resetTimer(); // should cancel first timer
    await Future.delayed(const Duration(milliseconds: 50));
    expect(count, 1); // only fires once, not twice
    service.dispose();
  });
}
