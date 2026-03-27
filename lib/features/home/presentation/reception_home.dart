// lib/features/home/presentation/reception_home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/i18n/app_localizations.dart';
import 'package:hotel_app/features/rooms/presentation/rooms_grid_screen.dart';
import 'package:hotel_app/features/tickets/presentation/tickets_list_screen.dart';
import 'package:hotel_app/features/profile/presentation/profile_screen.dart';

class ReceptionHomeScreen extends ConsumerStatefulWidget {
  const ReceptionHomeScreen({super.key});
  @override
  ConsumerState<ReceptionHomeScreen> createState() => _ReceptionHomeScreenState();
}

class _ReceptionHomeScreenState extends ConsumerState<ReceptionHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabs = [
      (icon: Icons.hotel,            label: l.rooms,     screen: const RoomsGridScreen()),
      (icon: Icons.confirmation_num, label: l.myTickets, screen: const TicketsListScreen()),
      (icon: Icons.person,           label: l.profile,   screen: const ProfileScreen()),
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
