// lib/features/home/presentation/housekeeping_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/home/providers/housekeeping_home_provider.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class HousekeepingHomeScreen extends ConsumerStatefulWidget {
  const HousekeepingHomeScreen({super.key});
  @override
  ConsumerState<HousekeepingHomeScreen> createState() => _HousekeepingHomeScreenState();
}

class _HousekeepingHomeScreenState extends ConsumerState<HousekeepingHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.cleaning_services, label: 'חדרים לניקוי', screen: const _DirtyRoomsList()),
      (icon: Icons.person,             label: l.profile,      screen: const ProfileScreen()),
    ];
    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon), label: t.label,
        )).toList(),
      ),
    );
  }
}

class _DirtyRoomsList extends ConsumerWidget {
  const _DirtyRoomsList();

  Color _statusColor(String s) => switch (s) {
    'dirty'    => const Color(0xFFFFCDD2),
    'cleaning' => const Color(0xFFFFE0B2),
    _          => const Color(0xFFC8E6C9),
  };

  String _statusLabel(String s) => switch (s) {
    'dirty'    => 'מלוכלך',
    'cleaning' => 'בניקוי',
    _          => 'נקי',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(dirtyRoomsProvider);
    return rooms.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (list) => list.isEmpty
          ? const Center(child: Text('אין חדרים לניקוי היום ✅'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final room = list[i];
                return Card(
                  color: _statusColor(room.housekeepingStatus),
                  child: ListTile(
                    leading: const Icon(Icons.hotel),
                    title: Text('חדר ${room.roomNumber}'),
                    subtitle: Text('קומה ${room.floor ?? '-'}'),
                    trailing: Chip(label: Text(_statusLabel(room.housekeepingStatus))),
                  ),
                );
              },
            ),
    );
  }
}
