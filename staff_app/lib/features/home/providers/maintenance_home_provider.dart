// lib/features/home/providers/maintenance_home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

final maintenanceTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];

  final data = await supabase
      .from('tickets')
      .select('*, room:rooms(room_number)')
      .eq('hotel_id', hotelId)
      .eq('assigned_dept', 'maintenance')
      .inFilter('status', ['open', 'in_progress'])
      .order('created_at');

  return (data as List).map((j) => Ticket.fromJson(j as Map<String, dynamic>)).toList();
});
