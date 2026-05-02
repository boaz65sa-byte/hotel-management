import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/data/guest_repository.dart';
import 'package:hotel_guest_app/domain/guest_request.dart';

final guestRepositoryProvider =
    Provider<GuestRepository>((_) => GuestRepository());

/// Current session — loaded once at startup.
final sessionProvider = FutureProvider<GuestSession?>((ref) async {
  return GuestSession.load();
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
