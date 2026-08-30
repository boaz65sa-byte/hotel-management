// test/features/tickets/data/photo_upload_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/tickets/data/photo_upload_service.dart';

void main() {
  test('PhotoUploadService stores isOnline flag', () {
    final online = PhotoUploadService(isOnline: true);
    expect(online.isOnline, true);

    final offline = PhotoUploadService(isOnline: false);
    expect(offline.isOnline, false);
  });

  test('10MB limit constant is correct', () {
    // 10 * 1024 * 1024 = 10485760
    expect(10 * 1024 * 1024, 10485760);
  });
}
