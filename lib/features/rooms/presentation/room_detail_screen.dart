// lib/features/rooms/presentation/room_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/features/tickets/presentation/ticket_card.dart';
import 'package:hotel_app/features/tickets/providers/tickets_provider.dart';
import '../providers/rooms_provider.dart';

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider);
    final ticketsAsync = ref.watch(roomTicketsProvider(roomId));

    final roomNumber = roomsAsync.maybeWhen(
      data: (rooms) {
        final room = rooms.where((r) => r.id == roomId).firstOrNull;
        return room?.roomNumber ?? roomId;
      },
      orElse: () => roomId,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Room $roomNumber')),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (tickets) => tickets.isEmpty
          ? const Center(child: Text('No tickets for this room'))
          : ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (_, i) => TicketCard(
                ticket: tickets[i],
                onTap: () => context.push('/tickets/${tickets[i].id}'),
              ),
            ),
      ),
    );
  }
}
