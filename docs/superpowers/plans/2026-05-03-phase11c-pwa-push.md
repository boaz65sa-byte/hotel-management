# Phase 11c — PWA Web Push Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Web Push to the guest PWA (`hotel_guest_app`) so guests receive notifications when their request status changes.

**Architecture:** Firebase JS SDK runs in a Service Worker. Guests tap "הפעל התראות" on the HomeScreen to grant permission. The PWA token is saved to `guest_push_tokens` in Supabase. The Edge Function (`send-push`, built in Phase 11a) sends the notification when status changes.

**Tech Stack:** Flutter Web + `firebase_core` + `firebase_messaging` + Firebase JS Service Worker

---

## ⚠️ Prerequisites

1. Firebase project must exist (done in Phase 11a prerequisites)
2. In Firebase Console → Project Settings → General → **Your apps** → Web app:
   - Create a Web app (if not already)
   - Copy: `apiKey`, `projectId`, `messagingSenderId`, `appId`
3. Firebase Console → Cloud Messaging → **Web Push certificates** → Generate key pair → copy **VAPID public key**
4. All 4 values go into `hotel_guest_app/lib/core/firebase_config.dart` (created in Task 2)

---

## File Map

| Action | File |
|--------|------|
| Modify | `hotel_guest_app/pubspec.yaml` — add `firebase_core`, `firebase_messaging` |
| Create | `hotel_guest_app/lib/core/firebase_config.dart` |
| Create | `hotel_guest_app/lib/core/push_service_web.dart` |
| Create | `hotel_guest_app/web/firebase-messaging-sw.js` |
| Modify | `hotel_guest_app/web/index.html` — import Firebase scripts |
| Modify | `hotel_guest_app/lib/presentation/home_screen.dart` — add "הפעל התראות" button |
| Modify | `hotel_guest_app/lib/main.dart` — init Firebase |

---

### Task 1: Add Firebase dependencies to PWA pubspec

**Files:**
- Modify: `hotel_guest_app/pubspec.yaml`

- [ ] **Step 1: Add dependencies**

```yaml
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
```

- [ ] **Step 2: Install**

```bash
cd "/Users/boazsaada/manegmant resapceon/hotel_guest_app" && flutter pub get
```

Expected: `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/pubspec.yaml && git commit -m "chore: add firebase deps to guest PWA"
```

---

### Task 2: Create Firebase config file

**Files:**
- Create: `hotel_guest_app/lib/core/firebase_config.dart`

This file holds the Web app credentials. The developer must fill in the real values (from Firebase Console) after the plan runs.

- [ ] **Step 1: Create the file**

```dart
// hotel_guest_app/lib/core/firebase_config.dart
// Fill in values from Firebase Console → Project Settings → Your apps → Web app
// and Cloud Messaging → Web Push certificates (VAPID key)

const firebaseApiKey           = 'YOUR_API_KEY';
const firebaseProjectId        = 'YOUR_PROJECT_ID';
const firebaseMessagingSenderId = 'YOUR_MESSAGING_SENDER_ID';
const firebaseAppId            = 'YOUR_APP_ID';
const firebaseVapidKey         = 'YOUR_VAPID_PUBLIC_KEY';
```

- [ ] **Step 2: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/lib/core/firebase_config.dart && git commit -m "feat: add Firebase config placeholder for guest PWA"
```

---

### Task 3: Create PWA Push Service

**Files:**
- Create: `hotel_guest_app/lib/core/push_service_web.dart`

- [ ] **Step 1: Create the file**

```dart
// hotel_guest_app/lib/core/push_service_web.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hotel_guest_app/core/firebase_config.dart';
import 'package:hotel_guest_app/core/supabase_init.dart';

class PushServiceWeb {
  PushServiceWeb._();

  /// Call once after Firebase.initializeApp() in main.dart (Web only).
  static Future<void> init() async {
    if (!kIsWeb) return;
    // Nothing to init beyond firebase_messaging on web
  }

  /// Request permission and register the token for this guest session.
  /// [hotelId] and [roomNumber] come from GuestSession.
  static Future<bool> requestAndRegister({
    required String hotelId,
    required String roomNumber,
  }) async {
    if (!kIsWeb) return false;
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: false,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return false;
      }

      final token = await messaging.getToken(vapidKey: firebaseVapidKey);
      if (token == null) return false;

      // Upsert into guest_push_tokens
      await supabase.from('guest_push_tokens').upsert({
        'hotel_id':    hotelId,
        'room_number': roomNumber,
        'token':       token,
      }, onConflict: 'hotel_id, room_number');

      return true;
    } catch (e) {
      debugPrint('PushServiceWeb error: $e');
      return false;
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/lib/core/push_service_web.dart && git commit -m "feat: add PWA web push service"
```

---

### Task 4: Create Firebase Service Worker

**Files:**
- Create: `hotel_guest_app/web/firebase-messaging-sw.js`

- [ ] **Step 1: Create the file**

```javascript
// hotel_guest_app/web/firebase-messaging-sw.js
// This service worker handles background push notifications for the guest PWA.
// The Firebase config values must match firebase_config.dart.
// Replace YOUR_* values with real credentials after Firebase setup.

importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            'YOUR_API_KEY',
  projectId:         'YOUR_PROJECT_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  appId:             'YOUR_APP_ID',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification ?? {};
  self.registration.showNotification(title ?? 'עדכון', {
    body:  body ?? '',
    icon:  '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    dir:   'rtl',
    lang:  'he',
  });
});
```

- [ ] **Step 2: Update `hotel_guest_app/web/index.html`**

Add the Firebase app script import inside `<head>`, just before the closing `</head>` tag:

```html
  <!-- Firebase Messaging Service Worker registration -->
  <script>
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/firebase-messaging-sw.js')
        .catch(err => console.error('SW registration failed:', err));
    }
  </script>
```

- [ ] **Step 3: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/web/firebase-messaging-sw.js hotel_guest_app/web/index.html && git commit -m "feat: add Firebase messaging service worker for PWA"
```

---

### Task 5: Initialize Firebase in PWA main.dart

**Files:**
- Modify: `hotel_guest_app/lib/main.dart`

Current content of `main()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(ProviderScope(child: MaterialApp.router(...)));
}
```

- [ ] **Step 1: Add Firebase init**

Add import:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hotel_guest_app/core/firebase_config.dart';
```

Modify `main()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey:            firebaseApiKey,
        projectId:         firebaseProjectId,
        messagingSenderId: firebaseMessagingSenderId,
        appId:             firebaseAppId,
      ),
    );
  }
  await initSupabase();
  runApp(ProviderScope(child: MaterialApp.router(...)));
}
```

- [ ] **Step 2: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon/hotel_guest_app" && flutter analyze lib/main.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/lib/main.dart && git commit -m "feat: initialize Firebase in PWA main.dart"
```

---

### Task 6: Add push permission button to HomeScreen

**Files:**
- Modify: `hotel_guest_app/lib/presentation/home_screen.dart`

The `HomeScreen` is currently a `ConsumerWidget`. Convert to `ConsumerStatefulWidget` to hold `_pushEnabled` state.

- [ ] **Step 1: Read the current HomeScreen structure**

Read `hotel_guest_app/lib/presentation/home_screen.dart` lines 1–60 to understand the current layout.

- [ ] **Step 2: Convert to ConsumerStatefulWidget**

Replace the class declaration:
```dart
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _pushEnabled = false;

  Future<void> _enablePush(String hotelId, String roomNumber) async {
    final enabled = await PushServiceWeb.requestAndRegister(
      hotelId: hotelId,
      roomNumber: roomNumber,
    );
    if (mounted) setState(() => _pushEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    // existing build content, replacing `WidgetRef ref` → use `ref` field
```

- [ ] **Step 3: Add push opt-in banner**

In the `data: (session)` section, after the feedback banner (look for `shouldShowFeedback` logic), add:

```dart
                // Push opt-in banner
                if (!_pushEnabled)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1F3D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1E3A5F)),
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
                                color: Color(0xFFE2E8F0), fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              _enablePush(session.hotelId, session.roomNumber),
                          child: const Text('הפעל',
                              style: TextStyle(color: Color(0xFFC9A84C))),
                        ),
                      ],
                    ),
                  ),
```

- [ ] **Step 4: Add import**

At the top of the file:
```dart
import 'package:hotel_guest_app/core/push_service_web.dart';
```

- [ ] **Step 5: Analyze**

```bash
cd "/Users/boazsaada/manegmant resapceon/hotel_guest_app" && flutter analyze lib/presentation/home_screen.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add hotel_guest_app/lib/presentation/home_screen.dart && git commit -m "feat: add push notification opt-in to PWA home screen"
```

---

## After All Tasks: Fill In Real Firebase Values

Once the code is committed, the developer must replace `YOUR_*` placeholders in:
1. `hotel_guest_app/lib/core/firebase_config.dart`
2. `hotel_guest_app/web/firebase-messaging-sw.js`

With the real values from Firebase Console, then rebuild the PWA:
```bash
cd "/Users/boazsaada/manegmant resapceon/hotel_guest_app" && flutter build web --release
```
