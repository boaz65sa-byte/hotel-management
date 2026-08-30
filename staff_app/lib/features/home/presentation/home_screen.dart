// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/tickets/domain/ticket_status.dart';
import 'package:hotel_app/features/home/presentation/reception_home.dart';
import 'package:hotel_app/features/home/presentation/maintenance_home.dart';
import 'package:hotel_app/features/home/presentation/manager_home.dart';
import 'package:hotel_app/features/housekeeping/presentation/housekeeping_manager_screen.dart';
import 'package:hotel_app/features/housekeeping/presentation/housekeeping_staff_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final roleStr = (user?.appMetadata['role'] as String?) ?? 'receptionist';
    final role = UserRole.fromString(roleStr);

    return switch (role.homeScreen) {
      'housekeeping_manager' => const HousekeepingManagerScreen(),
      'housekeeping_staff'   => const HousekeepingStaffScreen(),
      'maintenance'          => const MaintenanceHomeScreen(),
      'manager'              => const ManagerHomeScreen(),
      _                      => const ReceptionHomeScreen(),
    };
  }
}
