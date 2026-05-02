# Phase 11b — Flutter Push Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Firebase Cloud Messaging to the Flutter hotel app so staff receive push notifications for new requests and assigned tickets.

**Architecture:** `PushService` encapsulates all FCM logic: request permission, get token, subscribe to department topics, save token to `user_push_tokens`, and display foreground alerts via SnackBar. Called from `LoginScreen` after successful login, and cleaned up on logout.

**Tech Stack:** Flutter + `firebase_core` + `firebase_messaging` + Riverpod

---

## ⚠️ Prerequisites (Manual — Developer Must Do Before This Plan)

1. Create Firebase project → Add Android + iOS apps
2. Download `google-services.json` → place at `android/app/google-services.json`
3. Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`
4. Run: `dart pub global activate flutterfire_cli && flutterfire configure`
   - This generates `lib/firebase_options.dart`
5. Confirm `android/build.gradle` has `classpath 'com.google.gms:google-services:...'`
6. Confirm `android/app/build.gradle` has `apply plugin: 'com.google.gms.google-services'`

**These steps cannot be automated — the plan assumes they are complete.**

---

## File Map

| Action | File |
|--------|------|
| Modify | `pubspec.yaml` — add `firebase_core`, `firebase_messaging` |
| Modify | `lib/main.dart` — call `Firebase.initializeApp()` |
| Create | `lib/core/push/push_service.dart` |
| Modify | `lib/features/auth/login_screen.dart` — call `PushService` after login |

---

### Task 1: Add Firebase dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dependencies**

In `pubspec.yaml`, under `# Backend` or `# Utilities`:
```yaml
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
```

- [ ] **Step 2: Install**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter pub get
```

Expected: `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add firebase_core and firebase_messaging dependencies"
```

---

### Task 2: Initialize Firebase in main.dart

**Files:**
- Modify: `lib/main.dart`

Current content:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  await dotenv.load();
  await initSupabase();
  await LocalDb.instance; // pre-warm SQLite
  runApp(const ProviderScope(child: HotelApp()));
}
```

- [ ] **Step 1: Add Firebase import and init**

Add import:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:hotel_app/firebase_options.dart';
```

Modify `main()` to initialize Firebase before Supabase:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  await dotenv.load();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initSupabase();
  await LocalDb.instance;
  runApp(const ProviderScope(child: HotelApp()));
}
```

- [ ] **Step 2: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter analyze lib/main.dart 2>&1 | tail -5
```

Expected: no errors (will fail if `firebase_options.dart` doesn't exist yet — that's the prerequisite).

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart && git commit -m "feat: initialize Firebase in main.dart"
```

---

### Task 3: Create PushService

**Files:**
- Create: `lib/core/push/push_service.dart`

- [ ] **Step 1: Create the file**

```dart
// lib/core/push/push_service.dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level handler for background/terminated-state messages.
/// Must be a top-level function (not a method).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // FCM displays the notification automatically in the system tray.
  // Nothing to do here unless you need data processing.
}

class PushService {
  PushService._();

  static final _messaging = FirebaseMessaging.instance;

  /// Call once at app startup (after Firebase.initializeApp).
  static Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission (Android 13+ and iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set foreground notification presentation (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Call after successful login to subscribe to the right topic and save token.
  static Future<void> subscribeAfterLogin({
    required String role,
    required String hotelId,
    required BuildContext context,
  }) async {
    try {
      // Subscribe to department topic
      final topic = _topicForRole(role, hotelId);
      if (topic != null) {
        await _messaging.subscribeToTopic(topic);
      }

      // Always subscribe managers to the managers topic
      if (_isManager(role)) {
        await _messaging.subscribeToTopic('hotel-$hotelId-managers');
      }

      // Save individual token for direct assignment notifications
      final token = await _messaging.getToken();
      if (token != null) {
        final platform = Platform.isAndroid ? 'android' : 'ios';
        await Supabase.instance.client.from('user_push_tokens').upsert({
          'user_id':    Supabase.instance.client.auth.currentUser!.id,
          'token':      token,
          'platform':   platform,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Listen for foreground messages and show SnackBar
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification == null) return;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${notification.title ?? ''} — ${notification.body ?? ''}'),
              backgroundColor: const Color(0xFF0F1F3D),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } catch (e) {
      // Push is non-critical — log and continue
      debugPrint('PushService.subscribeAfterLogin error: $e');
    }
  }

  /// Call on logout to unsubscribe from all topics.
  static Future<void> unsubscribeOnLogout({
    required String role,
    required String hotelId,
  }) async {
    try {
      final topic = _topicForRole(role, hotelId);
      if (topic != null) await _messaging.unsubscribeFromTopic(topic);
      if (_isManager(role)) {
        await _messaging.unsubscribeFromTopic('hotel-$hotelId-managers');
      }
    } catch (e) {
      debugPrint('PushService.unsubscribeOnLogout error: $e');
    }
  }

  static String? _topicForRole(String role, String hotelId) => switch (role) {
    'housekeeping' || 'housekeeping_manager' => 'hotel-$hotelId-housekeeping',
    'maintenance' || 'maintenance_manager' || 'maintenance_tech'
                                             => 'hotel-$hotelId-maintenance',
    'receptionist'                           => 'hotel-$hotelId-reception',
    'reception_manager' || 'hotel_admin'     => 'hotel-$hotelId-reception',
    _                                        => null,
  };

  static bool _isManager(String role) => const {
    'reception_manager', 'hotel_admin', 'super_admin',
    'housekeeping_manager', 'maintenance_manager',
  }.contains(role);
}
```

- [ ] **Step 2: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter analyze lib/core/push/push_service.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/push/push_service.dart && git commit -m "feat: add PushService for FCM topic subscriptions and token management"
```

---

### Task 4: Wire PushService into LoginScreen

**Files:**
- Modify: `lib/features/auth/login_screen.dart`

The `_login()` method currently:
1. Calls `signIn`
2. Reads hotel theme
3. Router redirects

Add PushService call **after** successful login (after `ref.read(hotelThemeProvider.notifier).state = ...`).

- [ ] **Step 1: Add import**

```dart
import 'package:hotel_app/core/push/push_service.dart';
```

- [ ] **Step 2: Add PushService call in `_login()`**

Find the end of the hotel theme loading block (after `ref.read(hotelThemeProvider.notifier).state = ...`) and add:

```dart
        // Register for push notifications
        final role = supabase.auth.currentUser?.appMetadata['role'] as String? ?? '';
        if (mounted && hotelId != null) {
          await PushService.subscribeAfterLogin(
            role: role,
            hotelId: hotelId,
            context: context,
          );
        }
```

Also add `PushService.init()` call at the very start of `_login()`, before the try block:

Actually, `PushService.init()` should be called once, not per login. Add it to the `initState` of `_LoginScreenState`:

```dart
  @override
  void initState() {
    super.initState();
    PushService.init();
  }
```

- [ ] **Step 3: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter analyze lib/features/auth/login_screen.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 4: Run existing tests**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter test test/features/guest_requests/guest_request_test.dart 2>&1 | tail -5
```

Expected: 13/13 pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/login_screen.dart && git commit -m "feat: subscribe to FCM push notifications after login"
```
