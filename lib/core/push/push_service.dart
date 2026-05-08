// lib/core/push/push_service.dart
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// Maps role → OneSignal dept tag value
const _roleToDept = {
  'housekeeping':          'housekeeping',
  'housekeeping_manager':  'housekeeping',
  'maintenance':           'maintenance',
  'maintenance_manager':   'maintenance',
  'maintenance_tech':      'maintenance',
  'receptionist':          'reception',
  'reception_manager':     'reception',
  'hotel_admin':           'reception',
};

const _managerRoles = {
  'ceo',
  'reception_manager', 'hotel_admin', 'super_admin',
  'housekeeping_manager', 'maintenance_manager', 'security_manager',
};

class PushService {
  PushService._();

  /// Call once in main() after dotenv.load(), before runApp().
  static void initOneSignal(String appId) {
    OneSignal.initialize(appId);
    OneSignal.Notifications.requestPermission(true);
  }

  /// Call after successful login to set identifying tags.
  static Future<void> setupAfterLogin({
    required String role,
    required String hotelId,
    required String userId,
    required BuildContext context,
  }) async {
    try {
      final dept = _roleToDept[role] ?? 'other';
      final isManager = _managerRoles.contains(role);

      await OneSignal.User.addTagWithKey('hotel_id', hotelId);
      await OneSignal.User.addTagWithKey('dept', isManager ? 'managers' : dept);
      await OneSignal.User.addTagWithKey('role', role);
      await OneSignal.User.addTagWithKey('user_id', userId);
      await OneSignal.User.addTagWithKey('type', 'staff');

      OneSignal.login(userId);

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        final notif = event.notification;
        event.preventDefault();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${notif.title ?? ''} — ${notif.body ?? ''}'),
              backgroundColor: const Color(0xFF0F1F3D),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('PushService.setupAfterLogin error: $e');
    }
  }

  /// Call on logout to clear tags.
  static Future<void> clearOnLogout() async {
    try {
      await OneSignal.User.removeTag('hotel_id');
      await OneSignal.User.removeTag('dept');
      await OneSignal.User.removeTag('role');
      await OneSignal.User.removeTag('user_id');
      await OneSignal.User.removeTag('type');
      OneSignal.logout();
    } catch (e) {
      debugPrint('PushService.clearOnLogout error: $e');
    }
  }
}
