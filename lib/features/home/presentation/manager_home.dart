// lib/features/home/presentation/manager_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/home/providers/manager_home_provider.dart';
import 'package:hotel_app/features/analytics/presentation/analytics_screen.dart';
import 'package:hotel_app/features/users/presentation/users_screen.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_requests_list.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_feedback_screen.dart';

class ManagerHomeScreen extends ConsumerStatefulWidget {
  const ManagerHomeScreen({super.key});
  @override
  ConsumerState<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends ConsumerState<ManagerHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.dashboard,    label: 'דשבורד',    screen: const _ManagerDashboard()),
      (icon: Icons.room_service, label: 'בקשות',     screen: const GuestRequestsListScreen()),
      (icon: Icons.star,         label: 'משובים',    screen: const GuestFeedbackScreen()),
      (icon: Icons.bar_chart,    label: l.analytics, screen: const AnalyticsScreen()),
      (icon: Icons.people,       label: l.users,     screen: const UsersScreen()),
      (icon: Icons.person,       label: l.profile,   screen: const ProfileScreen()),
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

class _ManagerDashboard extends ConsumerWidget {
  const _ManagerDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(managerKpisProvider);
    return kpis.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('שגיאה: $e')),
      data: (k) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 52),
            Text('דשבורד מנהל', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _KpiCard(label: 'קריאות פתוחות',    value: k.openTickets,        color: Colors.blue),
                _KpiCard(label: 'בטיפול',            value: k.inProgressTickets,  color: Colors.orange),
                _KpiCard(label: 'חריגות SLA',        value: k.overdueTickets,     color: Colors.red),
                _KpiCard(label: 'אוטומציות פעילות', value: k.activeAutomations,  color: Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Card(
      color: color.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('$value', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
}
