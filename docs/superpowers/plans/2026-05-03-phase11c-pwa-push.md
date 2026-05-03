# Phase 11c — PWA Web Push Notifications (OneSignal) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Web Push to the guest PWA so guests receive a notification when their request status changes.

**Architecture:** OneSignal Web SDK is loaded via CDN in `index.html`. Flutter Web uses `dart:js_interop` to call the JS SDK. When the guest taps "הפעל התראות", OneSignal requests permission and registers the device. Tags `hotel_id`, `room_number`, and `type=guest` are set so the Edge Function can target this device.

**Tech Stack:** Flutter Web + OneSignal JS SDK (CDN) + `dart:js_interop`

---

## ⚠️ Prerequisites (Manual — Before This Plan)

1. OneSignal Dashboard → Platforms → Web Push → add your PWA domain (e.g., `https://guest.hotel.com`)
2. OneSignal App ID must be in the OneSignal Dashboard → Settings → Keys & IDs
3. The same App ID used for Flutter (Plan 11b) is reused here

---

## File Map

| Action | File |
|--------|------|
| Modify | `hotel_guest_app/web/index.html` — add OneSignal Web SDK |
| Create | `hotel_guest_app/lib/core/push_service_web.dart` |
| Modify | `hotel_guest_app/lib/presentation/home_screen.dart` — add opt-in button |

---

### Task 1: Add OneSignal Web SDK to index.html

**Files:**
- Modify: `hotel_guest_app/web/index.html`

- [ ] **Step 1: Read the current index.html**

Read `hotel_guest_app/web/index.html` to find the `<head>` closing tag.

- [ ] **Step 2: Add OneSignal SDK before `</head>`**

Add the following snippet (replace `YOUR_ONESIGNAL_APP_ID` with the actual App ID from OneSignal Dashboard):

```html
  <!-- OneSignal Web Push SDK -->
  <script src="https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.page.js" defer></script>
  <script>
    window.OneSignalDeferred = window.OneSignalDeferred || [];
    OneSignalDeferred.push(async function(OneSignal) {
      await OneSignal.init({
        appId: "YOUR_ONESIGNAL_APP_ID",
        notifyButton: { enable: false },
        allowLocalhostAsSecureOrigin: true,
      });
    });
  </script>
```

- [ ] **Step 3: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/web/index.html && git commit -m "feat: add OneSignal Web SDK to guest PWA"
```

---

### Task 2: Create PushServiceWeb (Dart → JS interop)

**Files:**
- Create: `hotel_guest_app/lib/core/push_service_web.dart`

The OneSignal Web SDK is already loaded in JS (step 1). We call it from Dart via `dart:js_interop`.

- [ ] **Step 1: Create the file**

```dart
// hotel_guest_app/lib/core/push_service_web.dart
// Calls the OneSignal JS SDK (loaded in index.html) via dart:js_interop.
// Only works on Web — guards are in place.

import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class PushServiceWeb {
  PushServiceWeb._();

  /// Request push permission and set tags for this guest.
  /// Returns true if permission was granted.
  static Future<bool> requestAndSetTags({
    required String hotelId,
    required String roomNumber,
  }) async {
    if (!kIsWeb) return false;
    try {
      // Request permission via OneSignal JS SDK
      final context = js.context;
      final oneSignal = context['OneSignal'];
      if (oneSignal == null) {
        debugPrint('PushServiceWeb: OneSignal JS not loaded');
        return false;
      }

      // Request notification permission
      final permResult = await _promiseToFuture(
        oneSignal.callMethod('Notifications', [])
      );

      // Set tags for targeting
      final tags = js.JsObject.jsify({
        'hotel_id':    hotelId,
        'room_number': roomNumber,
        'type':        'guest',
      });
      oneSignal.callMethod('User', [])
        ..callMethod('addTags', [tags]);

      return true;
    } catch (e) {
      debugPrint('PushServiceWeb error: $e');
      return false;
    }
  }

  /// Simpler approach: use OneSignal's built-in opt-in prompt.
  static void showNativePrompt() {
    if (!kIsWeb) return;
    try {
      final oneSignal = js.context['OneSignal'];
      if (oneSignal == null) return;
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

  /// Set hotel and room tags after permission is granted.
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

  static Future<dynamic> _promiseToFuture(dynamic jsPromise) {
    // Convert a JS Promise to a Dart Future
    final completer = Completer<dynamic>();
    jsPromise.callMethod('then', [
      js.allowInterop((value) => completer.complete(value)),
    ]);
    jsPromise.callMethod('catch', [
      js.allowInterop((error) => completer.completeError(error)),
    ]);
    return completer.future;
  }
}
```

> **Note on dart:js:** `dart:js` is available in Flutter Web and is simpler than `dart:js_interop` for calling arbitrary JS. The `// ignore: avoid_web_libraries_in_flutter` suppresses the lint for this intentional web-only file.

- [ ] **Step 2: Add missing import**

Add at the top (after existing imports):
```dart
import 'dart:async';
```

- [ ] **Step 3: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon/hotel_guest_app" && flutter analyze lib/core/push_service_web.dart 2>&1 | tail -5
```

Expected: no errors (info warnings about dart:js are OK).

- [ ] **Step 4: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/lib/core/push_service_web.dart && git commit -m "feat: add web push service using OneSignal JS interop"
```

---

### Task 3: Add push opt-in to HomeScreen

**Files:**
- Modify: `hotel_guest_app/lib/presentation/home_screen.dart`

The `HomeScreen` is currently a `ConsumerWidget`. Convert to `ConsumerStatefulWidget` to hold `_pushEnabled` state.

- [ ] **Step 1: Read the current file**

Read `hotel_guest_app/lib/presentation/home_screen.dart` lines 1–35.

- [ ] **Step 2: Convert to ConsumerStatefulWidget**

Replace:
```dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
```

With:
```dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _pushEnabled = false;

  void _enablePush(String hotelId, String roomNumber) {
    PushServiceWeb.showNativePrompt();
    PushServiceWeb.setGuestTags(hotelId: hotelId, roomNumber: roomNumber);
    setState(() => _pushEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
```

- [ ] **Step 3: Add import**

```dart
import 'package:flutter/foundation.dart';
import 'package:hotel_guest_app/core/push_service_web.dart';
```

- [ ] **Step 4: Add push opt-in banner**

In the `data: (session)` block, after the feedback banner (`if (session.shouldShowFeedback) ...`), add:

```dart
                // Web Push opt-in banner (Web only, shown until enabled)
                if (kIsWeb && !_pushEnabled)
                  GestureDetector(
                    onTap: () => _enablePush(
                        session.hotelId, session.roomNumber),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1F3D),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFF1E3A5F)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_outlined,
                              color: Color(0xFFC9A84C), size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'הפעל התראות ועקוב אחר הבקשות שלך',
                              style: TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _enablePush(
                                session.hotelId, session.roomNumber),
                            child: const Text('הפעל',
                                style:
                                    TextStyle(color: Color(0xFFC9A84C))),
                          ),
                        ],
                      ),
                    ),
                  ),
```

- [ ] **Step 5: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon/hotel_guest_app" && flutter analyze lib/presentation/home_screen.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/lib/presentation/home_screen.dart && git commit -m "feat: add push notification opt-in banner to PWA home screen"
```

---

## After All Tasks: Update App ID in index.html

Replace `YOUR_ONESIGNAL_APP_ID` in `hotel_guest_app/web/index.html` with the real value from OneSignal Dashboard, then rebuild:

```bash
cd "/Users/boazsaada/manegmant resapceon/hotel_guest_app" && flutter build web --release
```
