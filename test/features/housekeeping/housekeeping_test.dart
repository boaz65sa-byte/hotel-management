// test/features/housekeeping/housekeeping_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

void main() {
  group('Room model', () {
    test('fromJson parses assignedTo and assignedToName', () {
      final json = {
        'id': 'r1',
        'hotel_id': 'h1',
        'room_number': '101',
        'floor': 1,
        'room_type': 'standard',
        'status': 'available',
        'notes': null,
        'housekeeping_status': 'dirty',
        'assigned_to': 'user-uuid-123',
        'assigned_to_name': 'Dana Cohen',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final room = Room.fromJson(json);
      expect(room.assignedTo, 'user-uuid-123');
      expect(room.assignedToName, 'Dana Cohen');
    });

    test('fromJson defaults assignedTo to null when absent', () {
      final json = {
        'id': 'r2',
        'hotel_id': 'h1',
        'room_number': '102',
        'status': 'available',
        'housekeeping_status': 'clean',
        'created_at': '2026-01-01T00:00:00.000Z',
      };
      final room = Room.fromJson(json);
      expect(room.assignedTo, isNull);
      expect(room.assignedToName, isNull);
    });
  });
}
