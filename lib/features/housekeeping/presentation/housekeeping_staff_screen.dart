// lib/features/housekeeping/presentation/housekeeping_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/housekeeping/providers/housekeeping_providers.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

class HousekeepingStaffScreen extends ConsumerStatefulWidget {
  const HousekeepingStaffScreen({super.key});
  @override
  ConsumerState<HousekeepingStaffScreen> createState() =>
      _HousekeepingStaffScreenState();
}

class _HousekeepingStaffScreenState
    extends ConsumerState<HousekeepingStaffScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (icon: Icons.cleaning_services, label: 'החדרים שלי', screen: const _StaffRoomList()),
      (icon: Icons.person, label: 'פרופיל', screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _StaffRoomList extends ConsumerWidget {
  const _StaffRoomList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.userMetadata?['full_name'] as String? ?? 'עובד';
    final roomsAsync = ref.watch(myAssignedRoomsProvider);

    return roomsAsync.when(
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
      data: (rooms) => Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'שלום $userName',
                      style: const TextStyle(
                        color: Color(0xFFC9A84C),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'יש לך ${rooms.length} חדרים לניקוי',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: rooms.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Color(0xFF4ADE80), size: 48),
                            SizedBox(height: 12),
                            Text('אין חדרים להיום ✅',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: rooms.length,
                        itemBuilder: (_, i) => _StaffRoomCard(room: rooms[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffRoomCard extends ConsumerStatefulWidget {
  final Room room;
  const _StaffRoomCard({required this.room});

  @override
  ConsumerState<_StaffRoomCard> createState() => _StaffRoomCardState();
}

class _StaffRoomCardState extends ConsumerState<_StaffRoomCard> {
  bool _loading = false;

  Future<void> _openChecklist(String instanceId) async {
    if (!mounted) return;
    await context.push('/checklists/$instanceId');
    if (!mounted) return;
    final completed = await ref
        .read(housekeepingRepositoryProvider)
        .isInstanceCompleted(instanceId);
    if (completed && mounted) {
      await ref.read(housekeepingRepositoryProvider).markClean(widget.room.id);
    }
  }

  Future<void> _handleTap() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(housekeepingRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final hotelId = user?.appMetadata['hotel_id'] as String?;
      final staffId = user?.id;
      if (hotelId == null || staffId == null) throw Exception('לא מחובר');

      if (widget.room.housekeepingStatus == 'dirty') {
        await repo.startCleaning(widget.room.id);
        final instanceId = await repo.createHousekeepingInstance(
          roomId: widget.room.id,
          hotelId: hotelId,
          staffId: staffId,
        );
        await _openChecklist(instanceId);
      } else {
        // 'cleaning' — find existing active instance for this room
        final instances = await supabase
            .from('checklist_instances')
            .select('id')
            .eq('room_id', widget.room.id)
            .filter('completed_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(1);

        if ((instances as List).isNotEmpty) {
          await _openChecklist(instances.first['id'] as String);
        } else {
          final instanceId = await repo.createHousekeepingInstance(
            roomId: widget.room.id,
            hotelId: hotelId,
            staffId: staffId,
          );
          await _openChecklist(instanceId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCleaning = widget.room.housekeepingStatus == 'cleaning';
    return Container(
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
            height: 56,
            decoration: BoxDecoration(
              color: isCleaning
                  ? const Color(0xFFFB923C)
                  : const Color(0xFFF87171),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'חדר ${widget.room.roomNumber}${widget.room.floor != null ? " · קומה ${widget.room.floor}" : ""}',
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCleaning ? 'בניקיון' : 'ממתין לניקוי',
                  style: TextStyle(
                    color: isCleaning
                        ? const Color(0xFFFB923C)
                        : const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton(
                  onPressed: _handleTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: isCleaning
                        ? const Color(0xFFFB923C)
                        : const Color(0xFFC9A84C),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: Text(isCleaning ? 'המשך' : 'התחל'),
                ),
        ],
      ),
    );
  }
}
