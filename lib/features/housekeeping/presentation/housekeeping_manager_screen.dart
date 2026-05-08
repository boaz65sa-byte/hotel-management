// lib/features/housekeeping/presentation/housekeeping_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/features/housekeeping/data/housekeeping_repository.dart';
import 'package:hotel_app/features/housekeeping/providers/housekeeping_providers.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';
import 'package:hotel_app/features/guest_requests/presentation/staff_requests_screen.dart';

class HousekeepingManagerScreen extends ConsumerStatefulWidget {
  const HousekeepingManagerScreen({super.key});
  @override
  ConsumerState<HousekeepingManagerScreen> createState() =>
      _HousekeepingManagerScreenState();
}

class _HousekeepingManagerScreenState
    extends ConsumerState<HousekeepingManagerScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (icon: Icons.cleaning_services, label: 'ניהול חדרים', screen: const _ManagerRoomList()),
      (icon: Icons.room_service,      label: 'בקשות',       screen: const StaffRequestsScreen()),
      (icon: Icons.person,            label: 'פרופיל',      screen: const ProfileScreen()),
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

class _ManagerRoomList extends ConsumerStatefulWidget {
  const _ManagerRoomList();
  @override
  ConsumerState<_ManagerRoomList> createState() => _ManagerRoomListState();
}

class _ManagerRoomListState extends ConsumerState<_ManagerRoomList> {
  String _filter = 'הכול';

  static const _filters = ['הכול', 'מלוכלך', 'בניקיון', 'נקי'];
  static const _filterToStatus = {
    'מלוכלך': 'dirty',
    'בניקיון': 'cleaning',
    'נקי': 'clean',
  };

  List<Room> _applyFilter(List<Room> rooms) {
    if (_filter == 'הכול') return rooms;
    final status = _filterToStatus[_filter];
    return rooms.where((r) => r.housekeepingStatus == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(allHousekeepingRoomsProvider);

    return roomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('שגיאה: $e',
              style: const TextStyle(color: Colors.white))),
      data: (rooms) {
        final dirty = rooms.where((r) => r.housekeepingStatus == 'dirty').length;
        final cleaning = rooms.where((r) => r.housekeepingStatus == 'cleaning').length;
        final clean = rooms.where((r) => r.housekeepingStatus == 'clean').length;
        final filtered = _applyFilter(rooms);

        return Scaffold(
          backgroundColor: const Color(0xFF0A1628),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services, color: Color(0xFFC9A84C)),
                      SizedBox(width: 8),
                      Text(
                        'ניהול ניקיון',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Summary bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _SummaryChip(label: '$dirty מלוכלכים', color: const Color(0xFFF87171)),
                      const SizedBox(width: 8),
                      _SummaryChip(label: '$cleaning בניקיון', color: const Color(0xFFFB923C)),
                      const SizedBox(width: 8),
                      _SummaryChip(label: '$clean נקיים', color: const Color(0xFF4ADE80)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _filters.map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: const Color(0xFFC9A84C),
                          backgroundColor: const Color(0xFF0F1F3D),
                          labelStyle: TextStyle(
                            color: selected ? Colors.black : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Room list
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'אין חדרים להצגה',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _RoomCard(
                            room: filtered[i],
                            onTap: () => _showAssignSheet(context, filtered[i]),
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

  void _showAssignSheet(BuildContext context, Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1F3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => _AssignSheet(room: room),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  const _RoomCard({required this.room, required this.onTap});

  static const _statusLabel = {
    'dirty': 'מלוכלך',
    'cleaning': 'בניקיון',
    'clean': 'נקי',
  };
  static const _statusColor = {
    'dirty': Color(0xFFF87171),
    'cleaning': Color(0xFFFB923C),
    'clean': Color(0xFF4ADE80),
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor[room.housekeepingStatus] ?? const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E3A5F)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hotel, color: Color(0xFF7C9DC4), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'חדר ${room.roomNumber}${room.floor != null ? " · קומה ${room.floor}" : ""}',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    room.assignedToName ?? 'לא מוקצה',
                    style: TextStyle(
                      color: room.assignedToName != null
                          ? const Color(0xFF7C9DC4)
                          : const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(
                _statusLabel[room.housekeepingStatus] ?? room.housekeepingStatus,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF7C9DC4), size: 18),
          ],
        ),
      ),
    );
  }
}

class _AssignSheet extends ConsumerStatefulWidget {
  final Room room;
  const _AssignSheet({required this.room});

  @override
  ConsumerState<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends ConsumerState<_AssignSheet> {
  bool _loading = false;

  Future<void> _assign(StaffMember staff) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(housekeepingRepositoryProvider)
          .assignRoom(widget.room.id, staff.id, staff.name);
      ref.invalidate(housekeepingStaffProvider);
      if (mounted) Navigator.pop(context);
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

  Future<void> _unassign() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(housekeepingRepositoryProvider)
          .unassignRoom(widget.room.id);
      ref.invalidate(housekeepingStaffProvider);
      if (mounted) Navigator.pop(context);
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
    final staffAsync = ref.watch(housekeepingStaffProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'הקצה לחדר ${widget.room.roomNumber}',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('שגיאה: $e', style: const TextStyle(color: Colors.red)),
              data: (staff) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...staff.map((s) => ListTile(
                        leading: const Icon(Icons.person, color: Color(0xFF7C9DC4)),
                        title: Text(s.name,
                            style: const TextStyle(color: Color(0xFFE2E8F0))),
                        subtitle: Text('${s.assignedCount} חדרים',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 12)),
                        trailing: widget.room.assignedTo == s.id
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFFC9A84C))
                            : null,
                        onTap: () => _assign(s),
                      )),
                  if (widget.room.assignedTo != null) ...[
                    const Divider(color: Color(0xFF1E3A5F)),
                    ListTile(
                      leading: const Icon(Icons.remove_circle_outline,
                          color: Color(0xFFF87171)),
                      title: const Text('הסר הקצאה',
                          style: TextStyle(color: Color(0xFFF87171))),
                      onTap: _unassign,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
