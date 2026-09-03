// lib/features/home/presentation/manager_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/home/providers/manager_home_provider.dart';
import 'package:hotel_app/features/analytics/presentation/analytics_screen.dart';
import 'package:hotel_app/features/users/presentation/users_screen.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_requests_list.dart';
import 'package:hotel_app/features/guest_requests/presentation/guest_feedback_screen.dart';
import 'package:hotel_app/features/amenity_orders/presentation/amenity_orders_list_screen.dart';

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
      (icon: Icons.dashboard,    label: 'דשבורד',    screen: _ManagerDashboard(onNavigateToTab: (i) => setState(() => _tab = i))),
      (icon: Icons.room_service, label: 'בקשות',     screen: const GuestRequestsListScreen()),
      (icon: Icons.shopping_bag, label: 'הזמנות',    screen: const AmenityOrdersListScreen()),
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
  final ValueChanged<int> onNavigateToTab;
  const _ManagerDashboard({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(managerKpisProvider);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DashboardHeader(),
        Expanded(
          child: kpis.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('שגיאה: $e')),
            data: (k) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _KpiCard(
                    label: 'קריאות פתוחות', value: k.openTickets, color: cs.secondary,
                    onTap: () => context.push('/tickets?filter=open'),
                  ),
                  _KpiCard(
                    label: 'בטיפול', value: k.inProgressTickets, color: const Color(0xFFFB923C),
                    onTap: () => context.push('/tickets?filter=in_progress'),
                  ),
                  _KpiCard(
                    label: 'חריגות SLA', value: k.overdueTickets, color: cs.error,
                    onTap: () => context.push('/tickets?overdue=true'),
                  ),
                  _KpiCard(
                    label: 'אוטומציות פעילות', value: k.activeAutomations, color: const Color(0xFFA78BFA),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ניהול אוטומציות זמין בפאנל הניהול (אדמין)')),
                    ),
                  ),
                  _KpiCard(
                    label: 'בקשות אורחים', value: k.openGuestRequests, color: cs.primary,
                    onTap: () => onNavigateToTab(1),
                  ),
                  _KpiCard(
                    label: 'בקשות בטיפול', value: k.inProgressGuestRequests, color: const Color(0xFF4ADE80),
                    onTap: () => onNavigateToTab(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.surface, cs.primaryContainer],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.dashboard_rounded, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'לוח בקרה',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final VoidCallback onTap;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: color.withValues(alpha: 0.12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$value', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
