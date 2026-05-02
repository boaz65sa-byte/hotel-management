// hotel_guest_app/lib/core/session.dart
import 'package:shared_preferences/shared_preferences.dart';

class GuestSession {
  static const _keyName        = 'guest_name';
  static const _keyRoom        = 'room_number';
  static const _keyHotel       = 'hotel_id';
  static const _keyLoginTime   = 'login_time';
  static const _keyFeedbackDone = 'feedback_done';

  final String guestName;
  final String roomNumber;
  final String hotelId;
  final DateTime loginTime;
  final bool feedbackDone;

  const GuestSession({
    required this.guestName,
    required this.roomNumber,
    required this.hotelId,
    required this.loginTime,
    this.feedbackDone = false,
  });

  bool get shouldShowFeedback {
    const threshold = Duration(days: 3);
    return !feedbackDone &&
        DateTime.now().difference(loginTime) >= threshold;
  }

  static Future<GuestSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name  = prefs.getString(_keyName);
    final room  = prefs.getString(_keyRoom);
    final hotel = prefs.getString(_keyHotel);
    final time  = prefs.getString(_keyLoginTime);
    if (name == null || room == null || hotel == null || time == null) {
      return null;
    }
    return GuestSession(
      guestName:    name,
      roomNumber:   room,
      hotelId:      hotel,
      loginTime:    DateTime.parse(time),
      feedbackDone: prefs.getBool(_keyFeedbackDone) ?? false,
    );
  }

  static Future<void> save({
    required String guestName,
    required String roomNumber,
    required String hotelId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName,      guestName);
    await prefs.setString(_keyRoom,      roomNumber);
    await prefs.setString(_keyHotel,     hotelId);
    await prefs.setString(_keyLoginTime, DateTime.now().toIso8601String());
    await prefs.setBool(_keyFeedbackDone, false);
  }

  static Future<void> markFeedbackDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFeedbackDone, true);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
