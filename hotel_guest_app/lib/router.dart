// hotel_guest_app/lib/router.dart
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/core/session.dart';
import 'package:hotel_guest_app/presentation/landing_screen.dart';
import 'package:hotel_guest_app/presentation/home_screen.dart';
import 'package:hotel_guest_app/presentation/new_request_screen.dart';
import 'package:hotel_guest_app/presentation/feedback_screen.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final loc = state.matchedLocation;
    final session = await GuestSession.load();

    // Routes that require an active guest session
    const requiresSession = {'/home', '/new', '/feedback'};
    if (requiresSession.contains(loc) && session == null) {
      return '/';
    }

    // Already-logged-in guest landing on '/' → send straight to /home,
    // unless they explicitly arrived with new ?hotel= / ?room= URL params
    // (which means they re-scanned a QR — in that case we let them re-enter).
    if (loc == '/' && session != null) {
      final hasOverride = state.uri.queryParameters.containsKey('hotel') ||
                          state.uri.queryParameters.containsKey('room');
      if (!hasOverride) return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        // hotel_id and room come from URL query params: /?hotel=<id>&room=<number>
        final hotelId    = state.uri.queryParameters['hotel'];
        final roomNumber = state.uri.queryParameters['room'];
        return LandingScreen(hotelId: hotelId, roomNumber: roomNumber);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/new',
      builder: (context, state) => const NewRequestScreen(),
    ),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
  ],
);
