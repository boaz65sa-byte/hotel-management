// lib/features/guest_requests/providers/guest_request_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/guest_requests/data/guest_request_repository.dart';
import 'package:hotel_app/features/guest_requests/domain/guest_request_model.dart';

final guestRequestRepositoryProvider =
    Provider<GuestRequestRepository>((_) => GuestRequestRepository());

/// All requests for the hotel — reception and manager view.
final allGuestRequestsProvider = StreamProvider<List<GuestRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return const Stream.empty();
  return ref.read(guestRequestRepositoryProvider).streamAll(hotelId);
});

/// Requests for current user's department — housekeeping and maintenance staff.
final myDeptRequestsProvider = StreamProvider<List<GuestRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  final role = (user?.appMetadata['role'] as String?) ?? '';
  final dept = _roleToDept(role);
  if (hotelId == null || dept == null) return const Stream.empty();
  return ref.read(guestRequestRepositoryProvider).streamMyDept(hotelId, dept);
});

String? _roleToDept(String role) => switch (role) {
  'housekeeping' || 'housekeeping_manager' => 'housekeeping',
  'maintenance'                             => 'maintenance',
  'receptionist' || 'hotel_admin' || 'super_admin' => 'reception',
  _ => null,
};

/// Guest feedback list — manager/admin only.
final guestFeedbackProvider = FutureProvider<List<GuestFeedback>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];
  return ref.read(guestRequestRepositoryProvider).fetchFeedback(hotelId);
});
