// lib/features/tickets/presentation/ticket_card.dart
import 'package:flutter/material.dart';
import '../domain/ticket_model.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const TicketCard({super.key, required this.ticket, required this.onTap});

  Color get _statusColor => switch (ticket.status) {
    'open'             => Colors.orange,
    'in_progress'      => Colors.blue,
    'pending_approval' => Colors.red,
    'resolved'         => Colors.green,
    'closed'           => Colors.grey,
    _                  => Colors.grey,
  };

  IconData get _statusIcon => switch (ticket.status) {
    'resolved'         => Icons.check_circle,
    'closed'           => Icons.lock,
    'pending_approval' => Icons.pending,
    _                  => Icons.radio_button_unchecked,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(_statusIcon, color: _statusColor),
        title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Room ${ticket.roomNumber ?? "?"} • ${ticket.assignedDept}'),
        trailing: ticket.isOverSla
          ? const Icon(Icons.warning, color: Colors.red, size: 18)
          : null,
      ),
    );
  }
}
