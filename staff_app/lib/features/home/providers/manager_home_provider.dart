// lib/features/home/providers/manager_home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';

class ManagerKpis {
  final int openTickets;
  final int inProgressTickets;
  final int overdueTickets;
  final int activeAutomations;
  final int openGuestRequests;
  final int inProgressGuestRequests;
  const ManagerKpis({
    required this.openTickets,
    required this.inProgressTickets,
    required this.overdueTickets,
    required this.activeAutomations,
    required this.openGuestRequests,
    required this.inProgressGuestRequests,
  });
}

final managerKpisProvider = FutureProvider<ManagerKpis>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;

  final List ticketData;
  if (hotelId != null) {
    ticketData = await supabase
        .from('tickets')
        .select('status, sla_deadline')
        .eq('hotel_id', hotelId)
        .inFilter('status', ['open', 'in_progress']) as List;
  } else {
    ticketData = await supabase
        .from('tickets')
        .select('status, sla_deadline')
        .inFilter('status', ['open', 'in_progress']) as List;
  }
  final now = DateTime.now();

  final automationsList = await supabase
      .from('scheduled_tasks')
      .select('id')
      .eq('is_active', true);

  final List guestReqs;
  if (hotelId != null) {
    guestReqs = await supabase
        .from('guest_requests')
        .select('status')
        .eq('hotel_id', hotelId)
        .inFilter('status', ['open', 'assigned', 'in_progress']) as List;
  } else {
    guestReqs = [];
  }

  return ManagerKpis(
    openTickets: ticketData.where((t) => t['status'] == 'open').length,
    inProgressTickets: ticketData.where((t) => t['status'] == 'in_progress').length,
    overdueTickets: ticketData.where((t) {
      final sla = t['sla_deadline'];
      return sla != null && DateTime.parse(sla as String).isBefore(now);
    }).length,
    activeAutomations: (automationsList as List).length,
    openGuestRequests: guestReqs.where((r) =>
        r['status'] == 'open' || r['status'] == 'assigned').length,
    inProgressGuestRequests: guestReqs.where((r) =>
        r['status'] == 'in_progress').length,
  );
});
