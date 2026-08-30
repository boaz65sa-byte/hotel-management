// lib/core/auth/session_timeout.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/core/auth/auth_state.dart';
import 'package:hotel_app/core/supabase/supabase_client.dart';

/// Monitors inactivity and signs out the user after hotel.session_timeout_min
class SessionTimeoutService {
  Timer? _timer;
  final int timeoutMinutes;
  final VoidCallback onTimeout;

  SessionTimeoutService({
    required this.timeoutMinutes,
    required this.onTimeout,
  });

  void resetTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(minutes: timeoutMinutes), onTimeout);
  }

  void dispose() => _timer?.cancel();
}

/// Fetch the session timeout for current user's hotel (defaults to 480 min = 8 hours)
Future<int> fetchSessionTimeoutMinutes() async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return 480;
  final res = await supabase
      .from('users')
      .select('hotel:hotels(session_timeout_min)')
      .eq('id', userId)
      .single();
  return (res['hotel']?['session_timeout_min'] as int?) ?? 480;
}

/// Manages [SessionTimeoutService] lifecycle based on auth state.
/// Watch [sessionTimeoutManagerProvider] in the app root alongside syncWorkerProvider.
class SessionTimeoutManager {
  SessionTimeoutService? _service;

  Future<void> start() async {
    if (_service != null) return;
    final minutes = await fetchSessionTimeoutMinutes();
    _service = SessionTimeoutService(
      timeoutMinutes: minutes,
      onTimeout: () async {
        _service = null;
        await supabase.auth.signOut();
      },
    );
    _service!.resetTimer();
  }

  void stop() {
    _service?.dispose();
    _service = null;
  }

  void recordActivity() => _service?.resetTimer();
}

/// Riverpod provider that starts/stops the timeout service with the auth state.
final sessionTimeoutManagerProvider = Provider<SessionTimeoutManager>((ref) {
  final manager = SessionTimeoutManager();
  final authAsync = ref.watch(authStateProvider);
  authAsync.whenData((state) {
    if (state.session != null) {
      manager.start();
    } else {
      manager.stop();
    }
  });
  ref.onDispose(manager.stop);
  return manager;
});
