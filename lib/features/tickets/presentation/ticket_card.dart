// lib/features/tickets/presentation/ticket_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/features/tickets/providers/tickets_provider.dart';
import '../domain/ticket_model.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              onTap: onTap,
              leading: Icon(_statusIcon, color: _statusColor),
              title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Room ${ticket.roomNumber ?? "?"} • ${ticket.assignedDept}'),
              trailing: ticket.slaDeadline != null
                  ? _SlaBadge(
                      slaDeadline: ticket.slaDeadline!,
                      isResolved: ticket.resolvedAt != null,
                    )
                  : null,
            ),
            // Quick actions — only for roles that can claim/update
            Consumer(builder: (context, ref, _) {
              final user = ref.watch(currentUserProvider);
              final roleStr = (user?.appMetadata['role'] as String?) ?? 'receptionist';
              final role = UserRole.fromString(roleStr);
              if (!role.canClaimAndUpdate) return const SizedBox.shrink();
              if (ticket.status == 'resolved' || ticket.status == 'closed') {
                return const SizedBox.shrink();
              }

              final userId = user?.id ?? '';
              final repo = ref.read(ticketRepoProvider);

              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 16),
                    label: const Text('לפני'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('העלאת תמונה לפני — בקרוב')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  if (ticket.status == 'open')
                    FilledButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('קח אחריות'),
                      onPressed: () async {
                        await repo.acceptTicket(ticket.id, userId);
                        ref.invalidate(myTicketsProvider);
                        ref.invalidate(deptTicketsProvider);
                      },
                    ),
                  if (ticket.status == 'in_progress') ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: ticket.canResolve ? '' : 'נדרשת תמונה אחרי',
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('סגור'),
                        style: ticket.canResolve
                            ? null
                            : FilledButton.styleFrom(backgroundColor: Colors.grey),
                        onPressed: ticket.canResolve
                            ? () async {
                                await repo.quickResolveTicket(ticket.id);
                                ref.invalidate(myTicketsProvider);
                                ref.invalidate(deptTicketsProvider);
                              }
                            : null,
                      ),
                    ),
                  ],
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SlaBadge extends StatelessWidget {
  final DateTime slaDeadline;
  final bool isResolved;
  const _SlaBadge({required this.slaDeadline, required this.isResolved});

  @override
  Widget build(BuildContext context) {
    if (isResolved) return const SizedBox.shrink();
    final remaining = slaDeadline.difference(DateTime.now());
    final Color color;
    final String label;
    if (remaining.isNegative) {
      color = Colors.red;
      label = 'חריגת SLA';
    } else if (remaining.inMinutes < 30) {
      color = Colors.orange;
      label = '${remaining.inMinutes}ד';
    } else {
      color = Colors.green;
      label = '${remaining.inHours}ש';
    }
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
