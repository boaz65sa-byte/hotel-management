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
    // If navigating to home but no session exists, redirect to landing
    if (state.matchedLocation == '/home') {
      final session = await GuestSession.load();
      if (session == null) return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        // hotel_id comes from URL query param: /?hotel=<id>
        final hotelId = state.uri.queryParameters['hotel'];
        return LandingScreen(hotelId: hotelId);
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
