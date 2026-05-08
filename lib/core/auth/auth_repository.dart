// lib/core/auth/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';
import '../push/push_service.dart';

class AuthRepository {
  Future<AuthResponse> signIn(String email, String password) async {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    // Clear OneSignal tags first so this device stops receiving notifications
    // for the previous user. Push errors are swallowed inside clearOnLogout.
    await PushService.clearOnLogout();
    await supabase.auth.signOut();
  }

  Session? get currentSession => supabase.auth.currentSession;
  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// Extract hotel_id from JWT custom claims (app_metadata)
  String? get hotelId {
    final claims = currentSession?.user.appMetadata;
    return claims?['hotel_id'] as String?;
  }

  /// Extract role from JWT custom claims (app_metadata)
  String? get role {
    final claims = currentSession?.user.appMetadata;
    return claims?['role'] as String?;
  }
}
