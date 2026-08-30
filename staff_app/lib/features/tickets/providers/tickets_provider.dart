// lib/features/tickets/providers/tickets_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/connectivity/connectivity_service.dart';
import '../data/ticket_repository.dart';
import '../domain/ticket_model.dart';

final ticketRepoProvider = Provider<TicketRepository>((ref) {
  return TicketRepository(isOnline: () => ref.read(isOnlineProvider));
});

final myTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(ticketRepoProvider).fetchMyTickets(user.id);
});

final deptTicketsProvider = FutureProvider.family<List<Ticket>, String>((ref, dept) async {
  return ref.watch(ticketRepoProvider).fetchForDept(dept);
});

final roomTicketsProvider = FutureProvider.family<List<Ticket>, String>((ref, roomId) async {
  return ref.watch(ticketRepoProvider).fetchForRoom(roomId);
});
