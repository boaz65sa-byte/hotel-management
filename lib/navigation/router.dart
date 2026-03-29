// lib/navigation/router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/auth/login_screen.dart';
import 'package:hotel_app/features/home/presentation/home_screen.dart';
import 'package:hotel_app/features/tickets/presentation/ticket_detail_screen.dart';
import 'package:hotel_app/features/tickets/presentation/new_ticket_screen.dart';
import 'package:hotel_app/features/rooms/presentation/room_detail_screen.dart';
import 'package:hotel_app/features/rooms/presentation/room_management_screen.dart';
import 'package:hotel_app/features/users/presentation/new_user_screen.dart';
import 'package:hotel_app/features/checklists/presentation/checklist_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    redirect: (context, state) {
      final loggedIn = authState.maybeWhen(
        data: (s) => s.session != null,
        orElse: () => false,
      );
      final isLoginRoute = state.matchedLocation == '/login';
      if (!loggedIn && !isLoginRoute) return '/login';
      if (loggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/tickets/new', builder: (_, __) => const NewTicketScreen()),
      GoRoute(
        path: '/tickets/:id',
        builder: (_, state) => TicketDetailScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/rooms/manage', builder: (_, __) => const RoomManagementScreen()),
      GoRoute(
        path: '/rooms/:id',
        builder: (_, state) => RoomDetailScreen(roomId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/users/new', builder: (_, __) => const NewUserScreen()),
      GoRoute(
        path: '/checklists/:instanceId',
        builder: (_, state) => ChecklistScreen(
          instanceId: state.pathParameters['instanceId']!,
        ),
      ),
    ],
  );
});
