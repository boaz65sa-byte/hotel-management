import 'package:flutter/material.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';

class GuestRequestCard extends StatelessWidget {
  final GuestRequest request;
  final VoidCallback? onTap;

  const GuestRequestCard({super.key, required this.request, this.onTap});

  static const _categoryLabel = {
    'housekeeping': '🛏️ חדרניות',
    'maintenance':  '🔧 תחזוקה',
    'reception':    '🛎️ קבלה',
  };

  static const _statusColor = {
    'open':        Color(0xFFF87171),
    'assigned':    Color(0xFFFB923C),
    'in_progress': Color(0xFFFB923C),
    'resolved':    Color(0xFF4ADE80),
    'cancelled':   Color(0xFF64748B),
  };

  static const _statusLabel = {
    'open':        'פתוחה',
    'assigned':    'הוקצתה',
    'in_progress': 'בטיפול',
    'resolved':    'טופלה',
    'cancelled':   'בוטלה',
  };

  String _elapsed() {
    final diff = DateTime.now().difference(request.createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} דק\'';
    if (diff.inHours < 24)   return '${diff.inHours} שע\'';
    return '${diff.inDays} ימים';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor[request.status] ?? const Color(0xFF64748B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E3A5F)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'חדר ${request.roomNumber} · ${request.guestName}',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _categoryLabel[request.category] ?? request.category,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  if (request.description != null && request.description!.isNotEmpty)
                    Text(
                      request.description!,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel[request.status] ?? request.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _elapsed(),
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
