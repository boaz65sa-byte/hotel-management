// hotel_guest_app/lib/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/domain/guest_request.dart';
import 'package:hotel_guest_app/providers/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    final requestsAsync = ref.watch(myRequestsProvider);

    return sessionAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
            child: Text('שגיאה: $e',
                style: const TextStyle(color: Colors.white))),
      ),
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/'));
          return const Scaffold(backgroundColor: Color(0xFF0A1628));
        }
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'שלום ${session.guestName} 👋',
                        style: const TextStyle(
                          color: Color(0xFFC9A84C),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'חדר ${session.roomNumber}',
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Feedback banner
                if (session.shouldShowFeedback)
                  GestureDetector(
                    onTap: () => context.push('/feedback'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2F1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF4ADE80)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, color: Color(0xFFC9A84C)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('איך הייתה השהייה?',
                                    style: TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontWeight: FontWeight.w700)),
                                Text('השאירו לנו משוב קצר',
                                    style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push('/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('בקשה חדשה',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC9A84C),
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('הבקשות שלי',
                      style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: requestsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text('$e',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8)))),
                    data: (requests) => requests.isEmpty
                        ? const Center(
                            child: Text('אין בקשות עדיין',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: requests.length,
                            itemBuilder: (_, i) =>
                                _RequestTile(request: requests[i]),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final GuestRequest request;
  const _RequestTile({required this.request});

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
    'assigned':    'בטיפול',
    'in_progress': 'בטיפול',
    'resolved':    'טופלה ✓',
    'cancelled':   'בוטלה',
  };

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColor[request.status] ?? const Color(0xFF64748B);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: statusColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryLabel[request.category] ?? request.category,
                  style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                if (request.description != null &&
                    request.description!.isNotEmpty)
                  Text(
                    request.description!,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel[request.status] ?? request.status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
