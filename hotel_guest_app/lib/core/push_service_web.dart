// hotel_guest_app/lib/core/push_service_web.dart
// Calls the OneSignal JS SDK (loaded in index.html) via dart:js.
// Only works on Web — guards are in place.

import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class PushServiceWeb {
  PushServiceWeb._();

  /// Show the browser's native push permission prompt via OneSignal.
  static void showNativePrompt() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        '''
        if (window.OneSignalDeferred) {
          window.OneSignalDeferred.push(async function(os) {
            const granted = await os.Notifications.requestPermission();
            if (granted) {
              await os.User.addTag("type", "guest");
            }
          });
        }
        '''
      ]);
    } catch (e) {
      debugPrint('PushServiceWeb.showNativePrompt error: $e');
    }
  }

  /// Set hotel and room tags so the Edge Function can target this guest.
  static void setGuestTags({
    required String hotelId,
    required String roomNumber,
  }) {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('eval', [
        '''
        if (window.OneSignalDeferred) {
          window.OneSignalDeferred.push(async function(os) {
            await os.User.addTags({
              hotel_id:    "$hotelId",
              room_number: "$roomNumber",
              type:        "guest"
            });
          });
        }
        '''
      ]);
    } catch (e) {
      debugPrint('PushServiceWeb.setGuestTags error: $e');
    }
  }
}
