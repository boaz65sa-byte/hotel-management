import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../domain/room_model.dart';

class RoomRepository {
  Future<List<Room>> fetchAll() async {
    final res = await supabase
      .from('rooms')
      .select()
      .order('floor', ascending: true)
      .order('room_number', ascending: true);
    return (res as List).map((j) => Room.fromJson(j)).toList();
  }

  Future<void> addRoom({
    required String hotelId,
    required String roomNumber,
    int? floor,
    String? roomType,
  }) async {
    await supabase.from('rooms').insert({
      'hotel_id': hotelId,
      'room_number': roomNumber,
      'floor': floor,
      'room_type': roomType,
    });
  }

  Future<void> resetRoomStatus({
    required String roomId,
    required String userId,
    required String reason,
  }) async {
    await supabase.from('rooms').update({
      'status': 'available',
      'notes': reason,
      'status_changed_by': userId,
      'status_changed_at': DateTime.now().toIso8601String(),
    }).eq('id', roomId);
  }

  /// Import from CSV rows: [{room_number, floor, room_type}, ...]
  /// Returns: {imported: n, skipped: n, errors: [...]}
  Future<Map<String, dynamic>> importFromCsv({
    required String hotelId,
    required List<Map<String, dynamic>> rows,
  }) async {
    int imported = 0, skipped = 0;
    final errors = <String>[];

    for (final row in rows.take(500)) { // max 500
      final roomNumber = row['room_number']?.toString().trim();
      if (roomNumber == null || roomNumber.isEmpty) {
        errors.add('Empty room_number in row: $row');
        continue;
      }
      try {
        await supabase.from('rooms').insert({
          'hotel_id': hotelId,
          'room_number': roomNumber,
          'floor': int.tryParse(row['floor']?.toString() ?? ''),
          'room_type': row['room_type']?.toString().trim(),
        });
        imported++;
      } catch (e) {
        if (e.toString().contains('unique')) {
          skipped++;
        } else {
          errors.add('Row $roomNumber: $e');
        }
      }
    }
    return {'imported': imported, 'skipped': skipped, 'errors': errors};
  }
}
