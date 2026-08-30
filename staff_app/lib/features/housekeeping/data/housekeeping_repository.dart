// lib/features/housekeeping/data/housekeeping_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

class StaffMember {
  final String id;
  final String name;
  final int assignedCount;
  const StaffMember({required this.id, required this.name, required this.assignedCount});
}

class HousekeepingRepository {
  /// Streams all dirty/cleaning rooms for the hotel (manager view).
  Stream<List<Room>> streamAllRooms(String hotelId) {
    return supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => Room.fromJson(j))
            .where((r) =>
                r.housekeepingStatus == 'dirty' ||
                r.housekeepingStatus == 'cleaning')
            .toList()
          ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber)));
  }

  /// Streams rooms assigned to a specific staff member (staff view).
  Stream<List<Room>> streamMyRooms(String hotelId, String staffId) {
    return supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => Room.fromJson(j))
            .where((r) =>
                r.assignedTo == staffId &&
                (r.housekeepingStatus == 'dirty' ||
                    r.housekeepingStatus == 'cleaning'))
            .toList()
          ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber)));
  }

  /// Fetches all active housekeeping staff with their current room assignment count.
  Future<List<StaffMember>> fetchStaffList(String hotelId) async {
    final rooms = await supabase
        .from('rooms')
        .select('assigned_to')
        .eq('hotel_id', hotelId)
        .inFilter('housekeeping_status', ['dirty', 'cleaning']);

    final countMap = <String, int>{};
    for (final r in rooms as List) {
      final id = r['assigned_to'] as String?;
      if (id != null) countMap[id] = (countMap[id] ?? 0) + 1;
    }

    final users = await supabase
        .from('users')
        .select('id, full_name')
        .inFilter('role', ['housekeeping', 'housekeeping_manager'])
        .eq('is_active', true);

    return (users as List).map((u) {
      final id = u['id'] as String;
      return StaffMember(
        id: id,
        name: u['full_name'] as String,
        assignedCount: countMap[id] ?? 0,
      );
    }).toList();
  }

  /// Assigns a room to a staff member.
  ///
  /// Push notification is dispatched by the `send-push` Edge Function via a
  /// Supabase Database Webhook on UPDATE of `rooms` when `assigned_to`
  /// changes (event: `room_assigned`). See `supabase/functions/send-push`.
  Future<void> assignRoom(String roomId, String staffId, String staffName) async {
    await supabase.from('rooms').update({
      'assigned_to': staffId,
      'assigned_to_name': staffName,
    }).eq('id', roomId);
  }

  /// Clears assignment from a room.
  Future<void> unassignRoom(String roomId) async {
    await supabase.from('rooms').update({
      'assigned_to': null,
      'assigned_to_name': null,
    }).eq('id', roomId);
  }

  /// Updates room housekeeping status to 'cleaning'.
  Future<void> startCleaning(String roomId) async {
    await supabase.from('rooms').update({
      'housekeeping_status': 'cleaning',
    }).eq('id', roomId);
  }

  /// Updates room housekeeping status to 'clean' and clears assignment.
  Future<void> markClean(String roomId) async {
    await supabase.from('rooms').update({
      'housekeeping_status': 'clean',
      'assigned_to': null,
      'assigned_to_name': null,
    }).eq('id', roomId);
  }

  /// Creates a housekeeping checklist instance for a room.
  /// Returns the new instance ID.
  Future<String> createHousekeepingInstance({
    required String roomId,
    required String hotelId,
    required String staffId,
  }) async {
    final templates = await supabase
        .from('checklist_templates')
        .select('id')
        .eq('type', 'housekeeping')
        .limit(1);

    if ((templates as List).isEmpty) {
      throw Exception('לא נמצאה תבנית צ׳קליסט לניקיון. צור תבנית מסוג housekeeping בלוח הניהול.');
    }

    final templateId = templates.first['id'] as String;

    final instance = await supabase
        .from('checklist_instances')
        .insert({
          'template_id': templateId,
          'hotel_id': hotelId,
          'room_id': roomId,
          'assigned_to': staffId,
        })
        .select()
        .single();

    final instanceId = instance['id'] as String;

    final items = await supabase
        .from('checklist_items')
        .select()
        .eq('template_id', templateId)
        .order('order_index');

    await supabase.from('checklist_instance_items').insert(
      (items as List)
          .map((item) => {'instance_id': instanceId, 'item_id': item['id']})
          .toList(),
    );

    return instanceId;
  }

  /// Returns true if the checklist instance has been completed.
  Future<bool> isInstanceCompleted(String instanceId) async {
    final result = await supabase
        .from('checklist_instances')
        .select('completed_at')
        .eq('id', instanceId)
        .single();
    return result['completed_at'] != null;
  }
}
