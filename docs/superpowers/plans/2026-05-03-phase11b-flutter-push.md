# Phase 11b — Flutter Push Notifications (OneSignal) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add OneSignal push notifications to the Flutter hotel app so staff receive alerts for new requests and assigned tickets.

**Architecture:** `PushService` uses `onesignal_flutter` to initialize, request permission, set identifying tags (hotel_id, dept, role, user_id), and display foreground SnackBar alerts. Called from `LoginScreen` after successful login.

**Tech Stack:** Flutter + `onesignal_flutter: ^5.2.6`

---

## ⚠️ Prerequisites (Manual — Before This Plan)

### Android
1. OneSignal dashboard → Platforms → Google Android → enter Firebase Server Key
   *(Get from Firebase Console → Project Settings → Cloud Messaging → Server key)*
2. Ensure `android/app/google-services.json` exists (still needed for OneSignal internally)
3. Add to `android/build.gradle` classpath (if not already):
   ```
   classpath 'com.google.gms:google-services:4.4.2'
   ```
4. Add to `android/app/build.gradle` (if not already):
   ```
   apply plugin: 'com.google.gms.google-services'
   ```

### iOS
1. OneSignal dashboard → Platforms → Apple iOS → upload APNs .p8 key
   *(Get from [developer.apple.com](https://developer.apple.com) → Certificates → Keys)*
2. Enable Push Notifications capability in Xcode (ios/Runner.xcworkspace)

### OneSignal App ID
- Get from OneSignal Dashboard → Settings → Keys & IDs → **App ID**
- Add to `.env` file: `ONESIGNAL_APP_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

---

## File Map

| Action | File |
|--------|------|
| Modify | `pubspec.yaml` — add `onesignal_flutter` |
| Modify | `.env` — add `ONESIGNAL_APP_ID` |
| Create | `lib/core/push/push_service.dart` |
| Modify | `lib/features/auth/login_screen.dart` — call PushService after login |
| Modify | `lib/main.dart` — init OneSignal |

---

### Task 1: Add `onesignal_flutter` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dependency**

Under `# Backend` in `pubspec.yaml`:
```yaml
  onesignal_flutter: ^5.2.6
```

- [ ] **Step 2: Install**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter pub get
```

Expected: `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml && git commit -m "chore: add onesignal_flutter dependency"
```

---

### Task 2: Add OneSignal App ID to .env

**Files:**
- Modify: `.env`

- [ ] **Step 1: Add to .env**

Add this line to `.env` (developer fills in the real value):
```
ONESIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID_HERE
```

- [ ] **Step 2: Add to .env.example (if it exists)**

If `.env.example` exists, add the same key with a placeholder value.

- [ ] **Step 3: Commit**

```bash
git add .env.example && git commit -m "chore: add ONESIGNAL_APP_ID to env config"
```

Note: `.env` itself is gitignored — do NOT commit it.

---

### Task 3: Create PushService

**Files:**
- Create: `lib/core/push/push_service.dart`

- [ ] **Step 1: Create the file**

```dart
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
  'reception_manager', 'hotel_admin', 'super_admin',
  'housekeeping_manager', 'maintenance_manager',
};

class PushService {
  PushService._();

  /// Call once in main() after dotenv.load(), before runApp().
  static void initOneSignal(String appId) {
    OneSignal.initialize(appId);
    OneSignal.notifications.requestPermission(true);
  }

  /// Call after successful login to set identifying tags.
  /// Tags are used by the Edge Function to target the right users.
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

      // Associate device with user for direct (assigned) notifications
      OneSignal.login(userId);

      // Show foreground messages as SnackBar
      OneSignal.notifications.addForegroundWillDisplayListener((event) {
        final notif = event.notification;
        event.preventDefault(); // prevent system notification when app is open
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${notif.title ?? ''} — ${notif.body ?? ''}',
              ),
              backgroundColor: const Color(0xFF0F1F3D),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } catch (e) {
      // Push is non-critical — log and continue
      debugPrint('PushService.setupAfterLogin error: $e');
    }
  }

  /// Call on logout to clear tags so this device stops receiving notifications.
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
```

- [ ] **Step 2: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter analyze lib/core/push/push_service.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/push/push_service.dart && git commit -m "feat: add PushService using OneSignal for staff push notifications"
```

---

### Task 4: Initialize OneSignal in main.dart

**Files:**
- Modify: `lib/main.dart`

Current `main()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) { databaseFactory = databaseFactoryFfiWeb; }
  await dotenv.load();
  await initSupabase();
  await LocalDb.instance;
  runApp(const ProviderScope(child: HotelApp()));
}
```

- [ ] **Step 1: Add import and init call**

Add import:
```dart
import 'package:hotel_app/core/push/push_service.dart';
```

Add after `await dotenv.load()`:
```dart
  final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
  if (oneSignalAppId.isNotEmpty) {
    PushService.initOneSignal(oneSignalAppId);
  }
```

- [ ] **Step 2: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter analyze lib/main.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart && git commit -m "feat: initialize OneSignal in main.dart"
```

---

### Task 5: Wire PushService into LoginScreen

**Files:**
- Modify: `lib/features/auth/login_screen.dart`

The `_login()` method currently ends with the hotel theme loading and then the router redirects.

- [ ] **Step 1: Read the current file**

Read `lib/features/auth/login_screen.dart` lines 25–58 to see the current `_login()` method.

- [ ] **Step 2: Add import**

```dart
import 'package:hotel_app/core/push/push_service.dart';
```

- [ ] **Step 3: Add PushService call after theme loading**

In `_login()`, after `ref.read(hotelThemeProvider.notifier).state = AppTheme.forHotel(themeStr);`, add:

```dart
        // Set up push notification tags for this user
        final role   = supabase.auth.currentUser?.appMetadata['role'] as String? ?? '';
        final userId = supabase.auth.currentUser?.id ?? '';
        if (mounted && hotelId != null && role.isNotEmpty) {
          await PushService.setupAfterLogin(
            role:    role,
            hotelId: hotelId,
            userId:  userId,
            context: context,
          );
        }
```

- [ ] **Step 4: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter analyze lib/features/auth/login_screen.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 5: Run tests**

```bash
cd "/Users/boazsaada/manegmant resapceon" && flutter test test/features/guest_requests/guest_request_test.dart 2>&1 | tail -5
```

Expected: 13/13 pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/login_screen.dart && git commit -m "feat: setup OneSignal tags and foreground listener after login"
```
