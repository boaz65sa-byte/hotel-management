// lib/navigation/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/features/auth/login_screen.dart';

// Placeholder home screen — replaced in Plans 3 and 4
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Home')));
}

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
    ],
  );
});
