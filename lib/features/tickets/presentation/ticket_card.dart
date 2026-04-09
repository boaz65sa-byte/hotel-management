// lib/features/tickets/presentation/ticket_card.dart
import 'package:flutter/material.dart';
import '../domain/ticket_model.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.onTap});

  // ── Priority ─────────────────────────────────────────────────────────────
  static const _priorityColors = {
    'urgent':   Color(0xFFF87171),
    'high':     Color(0xFFFB923C),
    'normal':   Color(0xFF4ADE80),
    'low':      Color(0xFF94A3B8),
  };
  static const _priorityLabels = {
    'urgent': 'חרום',
    'high':   'דחוף',
    'normal': 'רגיל',
    'low':    'נמוך',
  };

  // ── Status ────────────────────────────────────────────────────────────────
  static const _statusLabels = {
    'open':             'פתוח',
    'in_progress':      'בטיפול',
    'pending_approval': 'ממתין אישור',
    'resolved':         'נפתר',
    'closed':           'סגור',
  };
  static const _statusColors = {
    'open':             Color(0xFF60A5FA),
    'in_progress':      Color(0xFFC9A84C),
    'pending_approval': Color(0xFFF87171),
    'resolved':         Color(0xFF4ADE80),
    'closed':           Color(0xFF94A3B8),
  };

  Color get _priorityColor =>
      _priorityColors[ticket.priority] ?? const Color(0xFF94A3B8);

  String get _timeAgo {
    final diff = DateTime.now().difference(ticket.createdAt);
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24)   return 'לפני ${diff.inHours} ש׳';
    return 'לפני ${diff.inDays} ימים';
  }

  String? get _slaLabel {
    if (ticket.slaDeadline == null || ticket.resolvedAt != null) return null;
    final remaining = ticket.slaDeadline!.difference(DateTime.now());
    if (remaining.isNegative) return 'חריגת SLA';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes} דק׳ SLA';
    return '${remaining.inHours} ש׳ SLA';
  }

  Color get _slaColor {
    if (ticket.slaDeadline == null) return const Color(0xFF94A3B8);
    final remaining = ticket.slaDeadline!.difference(DateTime.now());
    if (remaining.isNegative)       return const Color(0xFFF87171);
    if (remaining.inMinutes < 30)   return const Color(0xFFFB923C);
    return const Color(0xFF4ADE80);
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F3D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E3A5F), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Colored left border ───────────────────────────────────
                Container(width: 4, color: priorityColor),

                // ── Card content ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: ticket# + room + time
                        Row(
                          children: [
                            Icon(Icons.meeting_room_outlined,
                                size: 13, color: const Color(0xFF7C9DC4)),
                            const SizedBox(width: 4),
                            Text(
                              '#${ticket.id.substring(0, 6).toUpperCase()} · חדר ${ticket.roomNumber ?? "?"}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7C9DC4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _timeAgo,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF5A7A9F)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Row 2: title
                        Text(
                          ticket.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE2E8F0),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Row 3: priority chip + status chip
                        Row(
                          children: [
                            _Chip(
                              label: _priorityLabels[ticket.priority] ?? ticket.priority,
                              color: priorityColor,
                              filled: true,
                            ),
                            const SizedBox(width: 6),
                            _Chip(
                              label: _statusLabels[ticket.status] ?? ticket.status,
                              color: _statusColors[ticket.status] ?? const Color(0xFF94A3B8),
                              filled: false,
                            ),
                            const SizedBox(width: 6),
                            _Chip(
                              label: ticket.assignedDept,
                              color: const Color(0xFF2563EB),
                              filled: false,
                            ),
                          ],
                        ),

                        // Row 4: SLA + assignee
                        if (_slaLabel != null || ticket.assigneeName != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_slaLabel != null) ...[
                                Icon(Icons.timer_outlined,
                                    size: 12, color: _slaColor),
                                const SizedBox(width: 3),
                                Text(
                                  _slaLabel!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _slaColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (ticket.assigneeName != null)
                                Row(children: [
                                  const Icon(Icons.person_pin_outlined,
                                      size: 12, color: Color(0xFF7C9DC4)),
                                  const SizedBox(width: 3),
                                  Text(
                                    ticket.assigneeName!,
                                    style: const TextStyle(
                                        fontSize: 10, color: Color(0xFF7C9DC4)),
                                  ),
                                ]),
                              if (ticket.pendingClose)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ממתין סגירה',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.teal,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const _Chip({required this.label, required this.color, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
