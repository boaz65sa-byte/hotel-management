// lib/features/home/presentation/maintenance_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/home/providers/maintenance_home_provider.dart';
import 'package:hotel_app/features/tickets/presentation/ticket_card.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class MaintenanceHomeScreen extends ConsumerStatefulWidget {
  const MaintenanceHomeScreen({super.key});
  @override
  ConsumerState<MaintenanceHomeScreen> createState() => _MaintenanceHomeScreenState();
}

class _MaintenanceHomeScreenState extends ConsumerState<MaintenanceHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.queue,  label: 'תור קריאות', screen: const _MaintenanceQueue()),
      (icon: Icons.person, label: l.profile,    screen: const ProfileScreen()),
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

class _MaintenanceQueue extends ConsumerWidget {
  const _MaintenanceQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(maintenanceTicketsProvider);
    return tickets.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (list) => list.isEmpty
          ? const Center(child: Text('אין קריאות פתוחות'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) => TicketCard(ticket: list[i]),
            ),
    );
  }
}
