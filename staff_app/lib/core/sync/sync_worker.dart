// lib/core/sync/sync_worker.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import '../connectivity/connectivity_service.dart';
import '../database/sync_queue.dart';

const _maxAttempts = 3;

/// Watches connectivity. When coming back online, flushes the sync queue.
class SyncWorker {
  final Ref _ref;
  ProviderSubscription<AsyncValue<bool>>? _sub;

  SyncWorker(this._ref);

  void start() {
    _sub = _ref.listen(connectivityProvider, (prev, next) {
      final wasOffline = prev?.valueOrNull == false;
      final isNowOnline = next.valueOrNull == true;
      if (wasOffline && isNowOnline) {
        flush();
      }
    });
  }

  void dispose() => _sub?.close();

  Future<void> flush() async {
    final items = await SyncQueue.pending();
    for (final item in items) {
      final id = item['id'] as int;
      final action = item['action'] as String;
      final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
      final attempts = item['attempts'] as int;

      if (attempts >= _maxAttempts) continue; // give up after 3 tries

      try {
        await _process(action, payload);
        await SyncQueue.remove(id);
      } catch (_) {
        await SyncQueue.incrementAttempts(id);
      }
    }
  }

  Future<void> _process(String action, Map<String, dynamic> payload) async {
    switch (action) {
      case 'create_ticket':
        await supabase.from('tickets').insert(payload);

      case 'add_comment':
        await supabase.from('ticket_updates').insert(payload);

      case 'resolve_ticket':
        final ticketId = payload['ticket_id'] as String;
        final hotelId = payload['hotel_id'] as String;
        final userId = payload['user_id'] as String;
        final resolutionType = payload['resolution_type'] as String;
        final now = DateTime.now().toIso8601String();

        await supabase.from('tickets').update({
          'status': resolutionType == 'room_closed' ? 'pending_approval' : 'resolved',
          'resolution_type': resolutionType,
          'resolved_at': now,
          'updated_at': now,
        }).eq('id', ticketId);

        await supabase.from('ticket_updates').insert({
          'hotel_id': hotelId,
          'ticket_id': ticketId,
          'user_id': userId,
          'update_type': 'status_change',
          'message': 'Resolved as: $resolutionType',
        });

        if (resolutionType == 'room_closed') {
          await supabase.rpc('create_approval_request', params: {'p_ticket_id': ticketId});
        }

      default:
        throw UnsupportedError('Unknown sync action: $action');
    }
  }
}

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final worker = SyncWorker(ref);
  worker.start();
  ref.onDispose(worker.dispose);
  return worker;
});
