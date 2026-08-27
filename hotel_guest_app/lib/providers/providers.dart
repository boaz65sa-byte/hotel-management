import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/data/guest_repository.dart';
import 'package:hotel_guest_app/domain/guest_request.dart';
import 'package:hotel_guest_app/domain/amenity_item.dart';

final guestRepositoryProvider =
    Provider<GuestRepository>((_) => GuestRepository());

/// Current session — loaded once at startup.
final sessionProvider = FutureProvider<GuestSession?>((ref) async {
  return GuestSession.load();
});

/// This hotel's branding + feature toggles, keyed off the current session.
/// Used post-login (e.g. Home screen) to decide which optional modules to
/// show — separate from LandingScreen's own branding fetch, which runs
/// before a session exists.
final hotelBrandingProvider = FutureProvider<HotelBranding?>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null) return null;
  return ref.read(guestRepositoryProvider).getHotelBranding(session.hotelId);
});

/// Active amenities catalog for the current hotel, all categories.
final amenitiesProvider = FutureProvider<List<AmenityItem>>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  if (session == null) return const [];
  return ref.read(guestRepositoryProvider).getAmenities(session.hotelId);
});

/// Stream of this guest's requests.
/// Returns empty stream if no session loaded yet.
final myRequestsProvider = StreamProvider<List<GuestRequest>>((ref) {
  final sessionAsync = ref.watch(sessionProvider);
  return sessionAsync.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (session) {
      if (session == null) return const Stream.empty();
      return ref.read(guestRepositoryProvider).streamMyRequests(
            session.hotelId,
            session.roomNumber,
            session.guestName,
          );
    },
  );
});
