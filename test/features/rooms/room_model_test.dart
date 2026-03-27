import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

void main() {
  test('RoomModel.fromJson parses housekeepingStatus', () {
    final json = {
      'id': 'r1', 'hotel_id': 'h1', 'room_number': '101',
      'floor': 1, 'room_type': 'standard', 'status': 'available',
      'housekeeping_status': 'dirty',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };
    final room = RoomModel.fromJson(json);
    expect(room.housekeepingStatus, 'dirty');
  });

  test('RoomModel.fromJson defaults housekeepingStatus to clean', () {
    final json = {
      'id': 'r1', 'hotel_id': 'h1', 'room_number': '101',
      'floor': 1, 'room_type': 'standard', 'status': 'available',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };
    final room = RoomModel.fromJson(json);
    expect(room.housekeepingStatus, 'clean');
  });
}
