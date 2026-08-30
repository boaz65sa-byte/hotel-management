// lib/core/auth/auth_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );
});

/// Role from the JWT's app_metadata — same source as `AuthRepository.role`,
/// but derived through Riverpod so widgets don't have to reach into the
/// `Supabase.instance` singleton from inside `build()`. Reading the singleton
/// directly made those widgets untestable: a widget test that overrides its
/// providers still blew up with "You must initialize the supabase instance".
final currentRoleProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.appMetadata['role'] as String?;
});
