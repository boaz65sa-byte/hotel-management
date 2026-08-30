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
  final hotelId = user?.appMetadata['hotel_id']?.toString();
  if (hotelId == null) return const Stream.empty();
  return ref.watch(guestRequestRepositoryProvider).streamAll(hotelId);
});

/// Requests for current user's department — housekeeping and maintenance staff.
final myDeptRequestsProvider = StreamProvider<List<GuestRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id']?.toString();
  // Auth hasn't resolved yet — Stream.empty() keeps the UI in its loading
  // state, and this provider re-runs once currentUserProvider emits the user.
  if (hotelId == null) return const Stream.empty();

  final role = (user?.appMetadata['role']?.toString()) ?? '';
  final dept = _roleToDept(role);
  // Role claim missing or unrecognised. This is terminal — currentUserProvider
  // won't change again, so the provider never re-runs. Returning Stream.empty()
  // here closed the stream without ever emitting, which leaves a StreamProvider
  // in AsyncLoading forever: the "Requests tab spins and never loads" bug.
  // Surface it as an error so the screen can say something instead of hanging.
  if (dept == null) {
    return Stream.error(
      StateError('לא ניתן לזהות מחלקה עבור התפקיד "$role"'),
      StackTrace.current,
    );
  }

  return ref.watch(guestRequestRepositoryProvider).streamMyDept(hotelId, dept);
});

String? _roleToDept(String role) => switch (role) {
  'housekeeping' || 'housekeeping_manager'                        => 'housekeeping',
  'maintenance' || 'maintenance_tech' || 'maintenance_manager'   => 'maintenance',
  'receptionist' || 'reception_manager' || 'hotel_admin' ||
  'ceo' || 'software_manager' || 'super_admin'                   => 'reception',
  _ => null,
};

/// Guest feedback list — manager/admin only.
final guestFeedbackProvider = FutureProvider<List<GuestFeedback>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id']?.toString();
  if (hotelId == null) return [];
  return ref.watch(guestRequestRepositoryProvider).fetchFeedback(hotelId);
});
