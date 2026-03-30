// lib/features/home/providers/manager_home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';

class ManagerKpis {
  final int openTickets;
  final int inProgressTickets;
  final int overdueTickets;
  final int activeAutomations;
  const ManagerKpis({
    required this.openTickets,
    required this.inProgressTickets,
    required this.overdueTickets,
    required this.activeAutomations,
  });
}

final managerKpisProvider = FutureProvider<ManagerKpis>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;

  final List data;
  if (hotelId != null) {
    data = await supabase
        .from('tickets')
        .select('status, sla_deadline')
        .eq('hotel_id', hotelId)
        .inFilter('status', ['open', 'in_progress']) as List;
  } else {
    data = await supabase
        .from('tickets')
        .select('status, sla_deadline')
        .inFilter('status', ['open', 'in_progress']) as List;
  }
  final now = DateTime.now();

  final automationsList = await supabase
      .from('scheduled_tasks')
      .select('id')
      .eq('is_active', true);

  return ManagerKpis(
    openTickets: data.where((t) => t['status'] == 'open').length,
    inProgressTickets: data.where((t) => t['status'] == 'in_progress').length,
    overdueTickets: data.where((t) {
      final sla = t['sla_deadline'];
      return sla != null && DateTime.parse(sla as String).isBefore(now);
    }).length,
    activeAutomations: (automationsList as List).length,
  );
});
