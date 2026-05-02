# Phase 11 — Push Notifications Design Spec

**Date:** 2026-05-03
**Status:** Approved
**Scope:** Native push for hotel staff (Flutter) + Web Push for guests (PWA) via Firebase Cloud Messaging

---

## Overview

Push notifications deliver real-time alerts to two audiences:

1. **Hotel staff (Flutter app)** — when a new guest request or ticket arrives for their department, or when a ticket is assigned directly to them
2. **Hotel guests (PWA)** — when the status of their request changes (e.g., "בטיפול" → "טופל")

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Push infrastructure | Firebase Cloud Messaging (FCM) |
| Flutter push | `firebase_core` + `firebase_messaging` packages |
| PWA Web Push | Firebase JS SDK (`firebase/messaging`) in Service Worker |
| Trigger source | Supabase Database Webhooks |
| Push sender | Supabase Edge Function (`send-push`) — Deno, calls FCM HTTP v1 API |
| Token storage | Supabase table `user_push_tokens` (staff) + `guest_push_tokens` (guests) |

---

## Architecture

```
DB event (INSERT/UPDATE on guest_requests, tickets, ticket_assignments)
        ↓
Supabase Database Webhook (HTTP POST to Edge Function)
        ↓
Edge Function: send-push/index.ts
  ├─ Determine event type
  ├─ Look up recipients (topic or tokens from DB)
  └─ Call FCM HTTP v1 API
        ↓
FCM ──→ Flutter app (Android/iOS native push)
     └→ PWA Service Worker (Web Push)
```

---

## Notification Events

| Event | Trigger | Recipients | Message |
|-------|---------|------------|---------|
| Guest request created | `guest_requests` INSERT | Staff topic for dept | "בקשה חדשה · חדר {room} · {category}" |
| Guest request status → in_progress / resolved | `guest_requests` UPDATE status | Guest PWA token | "הבקשה שלך {status}" |
| Ticket created | `tickets` INSERT | Staff topic for dept | "קריאה חדשה · {title} · {priority}" |
| Ticket assigned to user | `ticket_assignments` INSERT | Specific user token | "קריאה הוקצתה לך · {title}" |

---

## Staff: Topic-Based Push (Flutter)

Each hotel staff member subscribes to **one department topic** when they log in:

- `hotel-{hotelId}-housekeeping`
- `hotel-{hotelId}-maintenance`
- `hotel-{hotelId}-reception`
- `hotel-{hotelId}-managers` (reception_manager + hotel_admin + super_admin)

**Role → Topic mapping:**

| Role | Topic |
|------|-------|
| housekeeping / housekeeping_manager | `hotel-{id}-housekeeping` |
| maintenance / maintenance_manager | `hotel-{id}-maintenance` |
| maintenance_tech | `hotel-{id}-maintenance` |
| receptionist | `hotel-{id}-reception` |
| reception_manager / hotel_admin / super_admin | `hotel-{id}-managers` |

Topics are subscribed via `FirebaseMessaging.instance.subscribeToTopic()` after login and unsubscribed on logout. No token storage in DB needed for topic-based delivery.

For **direct assignment notifications** (ticket assigned to specific user), the FCM token IS stored in `user_push_tokens`.

---

## Staff: Token Storage (for direct assignment)

**Table: `user_push_tokens`**
```sql
CREATE TABLE user_push_tokens (
  user_id   UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token     TEXT        NOT NULL,
  platform  TEXT        NOT NULL CHECK (platform IN ('android','ios','web')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id)
);
```

RLS: users can only upsert their own token. Edge Function uses service_role.

Flutter saves token after login:
```dart
final token = await FirebaseMessaging.instance.getToken();
// upsert into user_push_tokens
```

---

## Guests: Web Push Tokens (PWA)

Guests opt in to push from the PWA HomeScreen. Token stored per session:

**Table: `guest_push_tokens`**
```sql
CREATE TABLE guest_push_tokens (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id   UUID        NOT NULL,
  room_number TEXT       NOT NULL,
  token      TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (hotel_id, room_number)
);
```

When a guest request status changes, the Edge Function queries:
```sql
SELECT token FROM guest_push_tokens WHERE hotel_id = $1 AND room_number = $2
```

---

## Supabase Edge Function: `send-push`

Single function, called by all database webhooks. Receives the full row payload + event type via headers.

**File:** `supabase/functions/send-push/index.ts`

```typescript
// Called by Supabase database webhooks
// Header: x-event-type: guest_request_insert | guest_request_status | ticket_insert | ticket_assigned
// Body: Supabase webhook payload { type, table, record, old_record }

Deno.serve(async (req) => {
  const secret = Deno.env.get('WEBHOOK_SECRET')
  if (req.headers.get('x-webhook-secret') !== secret) {
    return new Response('Unauthorized', { status: 401 })
  }
  const payload = await req.json()
  const eventType = req.headers.get('x-event-type') ?? ''
  // ... route to handler
})
```

**FCM HTTP v1 API** — called via `fetch`:
```
POST https://fcm.googleapis.com/v1/projects/{projectId}/messages:send
Authorization: Bearer {oauth2_token}
```

OAuth2 token is obtained using a Firebase Service Account key (stored as Supabase secret `FIREBASE_SERVICE_ACCOUNT_JSON`).

---

## Database Webhooks Configuration (Supabase Dashboard)

Four webhooks, all pointing to `{supabase-url}/functions/v1/send-push`:

| Name | Table | Event | Header `x-event-type` |
|------|-------|-------|----------------------|
| `push_guest_request_insert` | `guest_requests` | INSERT | `guest_request_insert` |
| `push_guest_request_update` | `guest_requests` | UPDATE | `guest_request_status` |
| `push_ticket_insert` | `tickets` | INSERT | `ticket_insert` |
| `push_ticket_assigned` | `ticket_assignments` | INSERT | `ticket_assigned` |

---

## Flutter Setup (Manual Steps by Developer)

Before code changes, the developer must:

1. Create Firebase project at console.firebase.google.com
2. Add Android + iOS apps → download `google-services.json` + `GoogleService-Info.plist`
3. Place files: `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
4. Run `flutterfire configure` to generate `lib/firebase_options.dart`
5. Add FCM Server Key or Service Account to Supabase secrets

These are **one-time manual steps** — not automated by code.

---

## PWA Setup

The PWA (`hotel_guest_app`) needs:
1. Firebase Web App config (apiKey, projectId, messagingSenderId, appId, vapidKey) — hardcoded in `lib/core/firebase_config.dart`
2. Service Worker file: `hotel_guest_app/web/firebase-messaging-sw.js`
3. Import Firebase scripts in `web/index.html`

---

## Flutter Code Changes

**New files:**
- `lib/core/push/push_service.dart` — init FCM, subscribe topics, save token, handle foreground messages

**Modified files:**
- `pubspec.yaml` — add `firebase_core`, `firebase_messaging`
- `lib/main.dart` — call `PushService.init()` after login
- `lib/features/auth/login_screen.dart` — call `PushService.subscribeToTopics(role, hotelId)` after successful login

**PushService responsibilities:**
- `init()` — request permission, get token, listen to foreground messages (show SnackBar/overlay)
- `subscribeToTopics(role, hotelId)` — subscribe to dept topic + save token to `user_push_tokens`
- `unsubscribeAll(role, hotelId)` — unsubscribe on logout
- Background messages handled by FCM automatically (system tray notification)

---

## PWA Code Changes

**New files:**
- `hotel_guest_app/lib/core/push_service_web.dart` — request permission, get token, save to `guest_push_tokens`
- `hotel_guest_app/web/firebase-messaging-sw.js` — service worker for background push

**Modified files:**
- `hotel_guest_app/pubspec.yaml` — add `firebase_core`, `firebase_messaging` (Flutter Web)
- `hotel_guest_app/lib/presentation/home_screen.dart` — show "הפעל התראות" button, call PushService

---

## Out of Scope

- Silent/data-only push (all notifications are visible)
- Notification history screen
- Push to Admin Panel (admins use the web app, not a mobile app)
- APNS certificate upload (handled automatically by FCM)
- Per-user notification preferences toggle (Phase 12)
