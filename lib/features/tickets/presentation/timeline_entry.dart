// lib/features/tickets/presentation/timeline_entry.dart
import 'package:flutter/material.dart';
import '../domain/ticket_model.dart';

class TimelineEntry extends StatelessWidget {
  final TicketUpdate update;
  const TimelineEntry({super.key, required this.update});

  IconData get _icon => switch (update.updateType) {
    'claim'            => Icons.person_add,
    'status_change'    => Icons.sync,
    'photo_added'      => Icons.photo_camera,
    'approval_request' => Icons.approval,
    _                  => Icons.comment,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Icon(_icon, size: 20, color: Theme.of(context).colorScheme.primary),
          Container(width: 2, height: 40, color: Colors.grey.shade300),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(update.userName ?? 'System', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (update.message != null) Text(update.message!),
              Text(
                update.createdAt.toLocal().toString().substring(0, 16),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
