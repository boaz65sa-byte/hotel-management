// lib/core/auth/session_timeout.dart
import 'dart:async';
import 'package:flutter/material.dart';
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
