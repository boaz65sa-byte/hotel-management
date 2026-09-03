// lib/features/home/providers/custom_department_home_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';
import 'package:hotel_app/features/tickets/domain/ticket_model.dart';

class CustomDepartment {
  final String id;
  final String key;
  final String label;
  final String icon;
  const CustomDepartment({
    required this.id,
    required this.key,
    required this.label,
    required this.icon,
  });
}

/// The custom department (hotel_departments row) the current user belongs
/// to. department_id isn't in the JWT (see the migration's own comment on
/// why — the custom_jwt_claims hook is out-of-band and too fragile to
/// extend blind), so this reads the user's own `users` row live.
final myCustomDepartmentProvider = FutureProvider<CustomDepartment?>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;

  final userRow = await supabase
      .from('users')
      .select('department_id')
      .eq('id', userId)
      .maybeSingle();
  final departmentId = userRow?['department_id'] as String?;
  if (departmentId == null) return null;

  final deptRow = await supabase
      .from('hotel_departments')
      .select('id, key, label, icon')
      .eq('id', departmentId)
      .maybeSingle();
  if (deptRow == null) return null;

  return CustomDepartment(
    id:    deptRow['id'] as String,
    key:   deptRow['key'] as String,
    label: deptRow['label'] as String,
    icon:  deptRow['icon'] as String? ?? '🏷️',
  );
});

/// Every active custom department for the current hotel — used by the
/// "new ticket" screen's department picker.
final hotelCustomDepartmentsProvider = FutureProvider<List<CustomDepartment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];

  final data = await supabase
      .from('hotel_departments')
      .select('id, key, label, icon')
      .eq('hotel_id', hotelId)
      .eq('is_active', true)
      .order('label');

  return (data as List)
      .map((j) => CustomDepartment(
            id:    j['id'] as String,
            key:   j['key'] as String,
            label: j['label'] as String,
            icon:  j['icon'] as String? ?? '🏷️',
          ))
      .toList();
});

/// Open tickets routed to the current user's custom department.
final customDepartmentTicketsProvider = FutureProvider<List<Ticket>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  final dept = await ref.watch(myCustomDepartmentProvider.future);
  if (hotelId == null || dept == null) return [];

  final data = await supabase
      .from('tickets')
      .select('*, room:rooms(room_number)')
      .eq('hotel_id', hotelId)
      .eq('custom_department_id', dept.id)
      .inFilter('status', ['open', 'in_progress'])
      .order('created_at');

  return (data as List).map((j) => Ticket.fromJson(j as Map<String, dynamic>)).toList();
});
