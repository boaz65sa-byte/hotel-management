// lib/features/guest_requests/data/guest_request_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';

class GuestRequestRepository {
  /// Streams all requests for a hotel, newest first.
  /// Filters client-side because .stream() only supports one .eq() filter.
  Stream<List<GuestRequest>> streamAll(String hotelId) {
    return supabase
        .from('guest_requests')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => GuestRequest.fromJson(j))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Streams active requests for a specific department (staff view).
  /// Excludes resolved and cancelled — filtered client-side.
  Stream<List<GuestRequest>> streamMyDept(String hotelId, String dept) {
    return supabase
        .from('guest_requests')
        .stream(primaryKey: ['id'])
        .eq('hotel_id', hotelId)
        .map((data) => data
            .map((j) => GuestRequest.fromJson(j))
            .where((r) =>
                r.assignedDept == dept &&
                r.status != 'resolved' &&
                r.status != 'cancelled')
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Creates a new request. DB trigger auto-sets assigned_dept from category.
  Future<void> create({
    required String hotelId,
    required String roomNumber,
    required String guestName,
    required String category,
    String? description,
    String createdBy = 'reception',
  }) async {
    await supabase.from('guest_requests').insert({
      'hotel_id':    hotelId,
      'room_number': roomNumber,
      'guest_name':  guestName,
      'category':    category,
      if (description != null && description.isNotEmpty)
        'description': description,
      'created_by': createdBy,
    });
  }

  /// Updates the status of a request (e.g., open → in_progress → resolved).
  ///
  /// Push notifications are dispatched automatically by the `send-push` Edge
  /// Function via a Supabase Database Webhook on UPDATE of `guest_requests`
  /// (event: `guest_request_status`). No client-side action needed.
  Future<void> updateStatus(String id, String status) async {
    await supabase.from('guest_requests').update({
      'status':     status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Manager reassigns a request to a different department.
  Future<void> reassign(String id, String dept) async {
    await supabase.from('guest_requests').update({
      'assigned_dept': dept,
      'status':        'assigned',
      'updated_at':    DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Fetches all feedback for a hotel (manager/admin only).
  Future<List<GuestFeedback>> fetchFeedback(String hotelId) async {
    final res = await supabase
        .from('guest_feedback')
        .select()
        .eq('hotel_id', hotelId)
        .order('created_at', ascending: false);
    return res.map((j) => GuestFeedback.fromJson(j)).toList();
  }
}
