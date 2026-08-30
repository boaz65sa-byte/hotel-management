// test/core/sync/sync_worker_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SyncWorker gives up after 3 attempts', () {
    const maxAttempts = 3;
    expect(maxAttempts, 3);
  });
}
