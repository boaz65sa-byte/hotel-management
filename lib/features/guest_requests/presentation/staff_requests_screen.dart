// lib/features/guest_requests/presentation/staff_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';

class StaffRequestsScreen extends ConsumerWidget {
  const StaffRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myDeptRequestsProvider);
    return requestsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: Center(
          child: Text('שגיאה: $e',
              style: const TextStyle(color: Colors.white)),
        ),
      ),
      data: (requests) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'הבקשות שלי',
                  style: TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${requests.length} בקשות פעילות',
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
              Expanded(
                child: requests.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Color(0xFF4ADE80), size: 48),
                            SizedBox(height: 12),
                            Text('אין בקשות להיום ✅',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: requests.length,
                        itemBuilder: (_, i) =>
                            _StaffRequestCard(request: requests[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffRequestCard extends ConsumerWidget {
  final GuestRequest request;
  const _StaffRequestCard({required this.request});

  static const _categoryLabel = {
    'housekeeping': '🛏️ חדרניות',
    'maintenance': '🔧 תחזוקה',
    'reception': '🛎️ קבלה',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInProgress = request.status == 'in_progress';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'חדר ${request.roomNumber} · ${request.guestName}',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _categoryLabel[request.category] ?? request.category,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          if (request.description != null && request.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                request.description!,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () => ref
                    .read(guestRequestRepositoryProvider)
                    .updateStatus(request.id,
                        isInProgress ? 'resolved' : 'in_progress'),
                style: FilledButton.styleFrom(
                  backgroundColor: isInProgress
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFC9A84C),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: Text(isInProgress ? 'סמן כטופל' : 'התחל טיפול'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
