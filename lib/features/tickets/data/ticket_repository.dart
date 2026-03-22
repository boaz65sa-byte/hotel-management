// lib/features/tickets/data/ticket_repository.dart
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/core/database/sync_queue.dart';
import '../domain/ticket_model.dart';

class TicketRepository {
  final bool isOnline;
  TicketRepository({required this.isOnline});

  static const _select = '''
    id, hotel_id, room_id, opened_by, assigned_dept, claimed_by,
    title, description, priority, status, resolution_type,
    sla_deadline, created_at, updated_at, resolved_at,
    room:rooms(room_number, floor),
    opener:users!tickets_opened_by_fkey(full_name),
    claimer:users!tickets_claimed_by_fkey(full_name)
  ''';

  Future<List<Ticket>> fetchForDept(String dept) async {
    final res = await supabase
      .from('tickets')
      .select(_select)
      .eq('assigned_dept', dept)
      .order('created_at', ascending: false);
    return (res as List).map((j) => Ticket.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Ticket>> fetchMyTickets(String userId) async {
    final res = await supabase
      .from('tickets')
      .select(_select)
      .or('opened_by.eq.$userId,claimed_by.eq.$userId')
      .order('created_at', ascending: false);
    return (res as List).map((j) => Ticket.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Ticket> fetchById(String id) async {
    final res = await supabase.from('tickets').select(_select).eq('id', id).single();
    return Ticket.fromJson(res);
  }

  /// Open a new ticket. Works offline — queued if no connection.
  Future<void> openTicket({
    required String hotelId,
    required String roomId,
    required String openedBy,
    required String assignedDept,
    required String title,
    String? description,
    String priority = 'normal',
    DateTime? slaDeadline,
  }) async {
    final payload = {
      'hotel_id': hotelId,
      'room_id': roomId,
      'opened_by': openedBy,
      'assigned_dept': assignedDept,
      'title': title,
      'description': description,
      'priority': priority,
      'sla_deadline': slaDeadline?.toIso8601String(),
    };

    if (isOnline) {
      await supabase.from('tickets').insert(payload);
    } else {
      await SyncQueue.enqueue('create_ticket', payload);
    }
  }

  /// Claim a ticket. Requires online connection — uses conditional update.
  Future<bool> claimTicket(String ticketId, String userId) async {
    final res = await supabase.rpc('claim_ticket', params: {
      'p_ticket_id': ticketId,
      'p_user_id': userId,
    });
    return res as bool;
  }

  Future<void> addComment(String ticketId, String hotelId, String userId, String message) async {
    final payload = {
      'hotel_id': hotelId,
      'ticket_id': ticketId,
      'user_id': userId,
      'message': message,
      'update_type': 'comment',
    };
    if (isOnline) {
      await supabase.from('ticket_updates').insert(payload);
    } else {
      await SyncQueue.enqueue('add_comment', payload);
    }
  }

  Future<void> resolveTicket(String ticketId, String hotelId, String userId,
      String resolutionType) async {
    final now = DateTime.now().toIso8601String();
    final payload = {
      'status': resolutionType == 'room_closed' ? 'pending_approval' : 'resolved',
      'resolution_type': resolutionType,
      'resolved_at': now,
      'updated_at': now,
    };
    if (isOnline) {
      await supabase.from('tickets').update(payload).eq('id', ticketId);
      await supabase.from('ticket_updates').insert({
        'hotel_id': hotelId, 'ticket_id': ticketId,
        'user_id': userId, 'update_type': 'status_change',
        'message': 'Resolved as: $resolutionType',
      });
      if (resolutionType == 'room_closed') {
        await supabase.rpc('create_approval_request', params: {'p_ticket_id': ticketId});
      }
    } else {
      await SyncQueue.enqueue('resolve_ticket', {
        'ticket_id': ticketId, 'hotel_id': hotelId,
        'user_id': userId, 'resolution_type': resolutionType,
      });
    }
  }

  Future<List<TicketUpdate>> fetchUpdates(String ticketId) async {
    final res = await supabase
      .from('ticket_updates')
      .select('*, user:users(full_name)')
      .eq('ticket_id', ticketId)
      .order('created_at');
    return (res as List).map((j) => TicketUpdate.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<TicketPhoto>> fetchPhotos(String ticketId) async {
    final res = await supabase
      .from('ticket_photos')
      .select('*, uploader:users(full_name)')
      .eq('ticket_id', ticketId)
      .order('created_at');
    return (res as List).map((j) => TicketPhoto.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Subscribe to realtime updates for a ticket
  Stream<Map<String, dynamic>> watchTicket(String ticketId) {
    return supabase
      .from('tickets')
      .stream(primaryKey: ['id'])
      .eq('id', ticketId)
      .map((rows) => rows.isNotEmpty ? rows.first : <String, dynamic>{});
  }
}
