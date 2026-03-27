// lib/features/home/providers/manager_home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';

class ManagerKpis {
  final int openTickets;
  final int inProgressTickets;
  final int overdueTickets;
  const ManagerKpis({
    required this.openTickets,
    required this.inProgressTickets,
    required this.overdueTickets,
  });
}

final managerKpisProvider = FutureProvider<ManagerKpis>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;

  var query = supabase.from('tickets').select('status, sla_deadline');
  if (hotelId != null) {
    final data = await query.eq('hotel_id', hotelId).inFilter('status', ['open', 'in_progress']);
    final list = data as List;
    final now = DateTime.now();
    return ManagerKpis(
      openTickets: list.where((t) => t['status'] == 'open').length,
      inProgressTickets: list.where((t) => t['status'] == 'in_progress').length,
      overdueTickets: list.where((t) {
        final sla = t['sla_deadline'];
        return sla != null && DateTime.parse(sla as String).isBefore(now);
      }).length,
    );
  } else {
    // superAdmin — all hotels
    final data = await query.inFilter('status', ['open', 'in_progress']);
    final list = data as List;
    final now = DateTime.now();
    return ManagerKpis(
      openTickets: list.where((t) => t['status'] == 'open').length,
      inProgressTickets: list.where((t) => t['status'] == 'in_progress').length,
      overdueTickets: list.where((t) {
        final sla = t['sla_deadline'];
        return sla != null && DateTime.parse(sla as String).isBefore(now);
      }).length,
    );
  }
});
