// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/features/tickets/presentation/tickets_list_screen.dart';
import 'package:hotel_app/features/rooms/presentation/rooms_grid_screen.dart';
import 'package:hotel_app/features/analytics/presentation/analytics_screen.dart';
import 'package:hotel_app/features/users/presentation/users_screen.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final role = UserRole.fromString(
        (user?.appMetadata['role'] as String?) ?? 'receptionist');

    final tabs = [
      (icon: Icons.confirmation_num, label: l.myTickets, screen: const TicketsListScreen()),
      (icon: Icons.hotel, label: l.rooms, screen: const RoomsGridScreen()),
      if (role.isManager) (icon: Icons.bar_chart, label: l.analytics, screen: const AnalyticsScreen()),
      if (role.isManager) (icon: Icons.people, label: l.users, screen: const UsersScreen()),
      (icon: Icons.person, label: l.profile, screen: const ProfileScreen()),
    ];

    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
