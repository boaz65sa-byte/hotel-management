// lib/features/tickets/providers/ticket_detail_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket_model.dart';

final ticketDetailProvider = StreamProvider.family<Ticket, String>((ref, ticketId) {
  final repo = TicketRepository(isOnline: () => ref.read(isOnlineProvider));
  return repo.watchTicket(ticketId).map((json) {
    if (json.isEmpty) throw StateError('Ticket not found');
    return Ticket.fromJson(json);
  });
});

final ticketUpdatesProvider = FutureProvider.family<List<TicketUpdate>, String>((ref, ticketId) async {
  return TicketRepository(isOnline: () => ref.read(isOnlineProvider)).fetchUpdates(ticketId);
});

final ticketPhotosProvider = FutureProvider.family<List<TicketPhoto>, String>((ref, ticketId) async {
  return TicketRepository(isOnline: () => ref.read(isOnlineProvider)).fetchPhotos(ticketId);
});
