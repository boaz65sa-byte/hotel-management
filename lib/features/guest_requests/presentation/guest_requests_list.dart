import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_request_card.dart';
import 'package:hotel_app/features/guest_requests/presentation/new_guest_request_screen.dart';
import 'package:hotel_app/features/guest_requests/providers/guest_request_providers.dart';

const _filters = ['הכול', 'פתוחות', 'בטיפול', 'טופלו'];

bool _matchesFilter(GuestRequest r, String filter) => switch (filter) {
  'פתוחות' => r.status == 'open' || r.status == 'assigned',
  'בטיפול'  => r.status == 'in_progress',
  'טופלו'   => r.status == 'resolved',
  _         => true,
};

class GuestRequestsListScreen extends ConsumerStatefulWidget {
  const GuestRequestsListScreen({super.key});
  @override
  ConsumerState<GuestRequestsListScreen> createState() =>
      _GuestRequestsListScreenState();
}

class _GuestRequestsListScreenState
    extends ConsumerState<GuestRequestsListScreen> {
  String _filter = 'הכול';

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(allGuestRequestsProvider);
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
      data: (all) {
        final requests =
            all.where((r) => _matchesFilter(r, _filter)).toList();
        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'בקשות אורחים',
                    style: TextStyle(
                      color: Color(0xFFC9A84C),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _filters
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f),
                                selected: _filter == f,
                                onSelected: (_) =>
                                    setState(() => _filter = f),
                                selectedColor: const Color(0xFFC9A84C),
                                labelStyle: TextStyle(
                                  color: _filter == f
                                      ? Colors.black
                                      : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                backgroundColor: const Color(0xFF0F1F3D),
                                checkmarkColor: Colors.black,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: requests.isEmpty
                      ? const Center(
                          child: Text('אין בקשות',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 16)),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: requests.length,
                          itemBuilder: (_, i) => GuestRequestCard(
                            request: requests[i],
                            onTap: () => _showActions(requests[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const NewGuestRequestScreen()),
            ),
            backgroundColor: const Color(0xFFC9A84C),
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text('בקשה ידנית',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }

  void _showActions(GuestRequest request) {
    final repo = ref.read(guestRequestRepositoryProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'חדר ${request.roomNumber} · ${request.guestName}',
              style: const TextStyle(
                color: Color(0xFFC9A84C),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (request.status == 'open' || request.status == 'assigned')
              ListTile(
                leading: const Icon(Icons.play_arrow,
                    color: Color(0xFFFB923C)),
                title: const Text('התחל טיפול',
                    style: TextStyle(color: Color(0xFFE2E8F0))),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await repo.updateStatus(request.id, 'in_progress');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
            if (request.status == 'in_progress')
              ListTile(
                leading: const Icon(Icons.check_circle,
                    color: Color(0xFF4ADE80)),
                title: const Text('סמן כטופל',
                    style: TextStyle(color: Color(0xFFE2E8F0))),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await repo.updateStatus(request.id, 'resolved');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz,
                  color: Color(0xFF94A3B8)),
              title: const Text('שנה מחלקה',
                  style: TextStyle(color: Color(0xFFE2E8F0))),
              onTap: () => _showReassignSheet(request),
            ),
          ],
        ),
      ),
    );
  }

  void _showReassignSheet(GuestRequest request) {
    Navigator.pop(context);
    if (!mounted) return;
    final repo = ref.read(guestRequestRepositoryProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('שנה הקצאה',
                style: TextStyle(
                    color: Color(0xFFC9A84C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final entry in const [
              ('housekeeping', '🛏️ חדרניות'),
              ('maintenance', '🔧 תחזוקה'),
              ('reception', '🛎️ קבלה'),
            ])
              ListTile(
                title: Text(entry.$2,
                    style: const TextStyle(color: Color(0xFFE2E8F0))),
                trailing: request.assignedDept == entry.$1
                    ? const Icon(Icons.check, color: Color(0xFFC9A84C))
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await repo.reassign(request.id, entry.$1);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
