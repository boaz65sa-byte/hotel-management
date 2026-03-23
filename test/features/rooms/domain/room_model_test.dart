import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

void main() {
  final json = {
    'id': 'r1', 'hotel_id': 'h1', 'room_number': '101',
    'floor': 1, 'room_type': 'standard', 'status': 'available',
    'notes': null, 'created_at': '2026-03-22T10:00:00Z',
  };

  test('Room.fromJson parses correctly', () {
    final room = Room.fromJson(json);
    expect(room.roomNumber, '101');
    expect(room.isAvailable, true);
    expect(room.isClosed, false);
  });
}
