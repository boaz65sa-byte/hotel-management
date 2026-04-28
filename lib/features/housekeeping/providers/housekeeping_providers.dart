// lib/features/housekeeping/providers/housekeeping_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/housekeeping/data/housekeeping_repository.dart';
import 'package:hotel_app/features/rooms/domain/room_model.dart';

final housekeepingRepositoryProvider =
    Provider<HousekeepingRepository>((_) => HousekeepingRepository());

/// All dirty/cleaning rooms for the hotel (manager view).
final allHousekeepingRoomsProvider = StreamProvider<List<Room>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return const Stream.empty();
  return ref
      .read(housekeepingRepositoryProvider)
      .streamAllRooms(hotelId);
});

/// Rooms assigned to the current user (staff view).
final myAssignedRoomsProvider = StreamProvider<List<Room>>((ref) {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  final staffId = user?.id;
  if (hotelId == null || staffId == null) return const Stream.empty();
  return ref
      .read(housekeepingRepositoryProvider)
      .streamMyRooms(hotelId, staffId);
});

/// All active housekeeping staff members with room counts.
final housekeepingStaffProvider =
    FutureProvider<List<StaffMember>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final hotelId = user?.appMetadata['hotel_id'] as String?;
  if (hotelId == null) return [];
  return ref
      .read(housekeepingRepositoryProvider)
      .fetchStaffList(hotelId);
});
