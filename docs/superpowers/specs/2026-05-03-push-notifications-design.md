# Phase 11 — Push Notifications Design Spec

**Date:** 2026-05-03
**Status:** Approved
**Scope:** Native push for hotel staff (Flutter) + Web Push for guests (PWA) via OneSignal

---

## Overview

Push notifications alert two audiences in real time:

1. **Hotel staff (Flutter app)** — when a new guest request or ticket arrives for their department, or a ticket is assigned directly to them
2. **Hotel guests (PWA)** — when their request status changes (e.g., "בטיפול" → "טופל")

---

## Why OneSignal (not Firebase directly)

| Concern | Firebase | OneSignal |
|---------|----------|-----------|
| SDK in Flutter code | `firebase_core` + `firebase_messaging` | `onesignal_flutter` only |
| `firebase_options.dart` generation | Required (`flutterfire configure`) | Not needed |
| Token management | Manual (store in DB) | OneSignal manages automatically |
| Web Push (PWA) | Firebase JS SDK + Service Worker code | OneSignal JS snippet (1 line) |
| Targeting by dept/hotel | Manual topics | Tags + filter API |
| REST API for sending | FCM HTTP v1 (OAuth2 JWT) | Simple `Authorization: Basic` |

OneSignal still uses FCM internally for Android and APNs for iOS, but abstracts all of that away from the developer.

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Push infrastructure | OneSignal (onesignal.com) |
| Flutter push | `onesignal_flutter` package |
| PWA Web Push | OneSignal Web SDK (JS — injected via CDN) |
| Trigger source | Supabase Database Webhooks |
| Push sender | Supabase Edge Function (`send-push`) — calls OneSignal REST API |
| Targeting | OneSignal Tags (hotel_id, dept, role, room_number) |

---

## Architecture

```
DB event (INSERT/UPDATE on guest_requests, tickets, ticket_assignments)
        ↓
Supabase Database Webhook (HTTP POST)
        ↓
Edge Function: supabase/functions/send-push/index.ts
  ├─ Determine event type + recipients (via tags/filters)
  └─ POST to OneSignal REST API
        ↓
OneSignal ──→ Flutter app (Android native via FCM / iOS via APNs)
           └→ PWA browser (Web Push via VAPID — handled by OneSignal)
```

---

## Notification Events

| Event | Trigger | Recipients (OneSignal filter) | Message |
|-------|---------|-------------------------------|---------|
| Guest request created | `guest_requests` INSERT | `hotel_id = X AND dept = Y` | "בקשה חדשה · חדר {room} · {category}" |
| Guest request status updated | `guest_requests` UPDATE | `hotel_id = X AND room_number = Y` (guest) | "הבקשה שלך {status}" |
| Ticket created | `tickets` INSERT | `hotel_id = X AND dept = Y` | "קריאה חדשה · {priority} · {title}" |
| Ticket assigned | `ticket_assignments` INSERT | `user_id = Z` (specific user) | "קריאה הוקצתה לך · {title}" |

---

## OneSignal Tags

Tags are key-value pairs set on each device. Used for filtering.

**Staff (Flutter)** — set after login:
```
hotel_id:    "00000000-..."
dept:        "housekeeping"  | "maintenance" | "reception"
role:        "receptionist"  | "reception_manager" | etc.
user_id:     "<supabase-user-uuid>"
```

**Guests (PWA)** — set after opt-in:
```
hotel_id:    "00000000-..."
room_number: "101"
type:        "guest"
```

---

## OneSignal REST API (Edge Function)

**Send to segment by filters:**
```
POST https://onesignal.com/api/v1/notifications
Authorization: Basic <REST_API_KEY>
{
  "app_id": "<ONESIGNAL_APP_ID>",
  "filters": [
    { "field": "tag", "key": "hotel_id", "relation": "=", "value": "xxx" },
    { "operator": "AND" },
    { "field": "tag", "key": "dept",     "relation": "=", "value": "housekeeping" }
  ],
  "headings": { "en": "...", "he": "..." },
  "contents": { "en": "...", "he": "..." }
}
```

**Required Supabase secrets:**
- `ONESIGNAL_APP_ID` — from OneSignal Dashboard → Settings → Keys & IDs
- `ONESIGNAL_REST_API_KEY` — same location
- `WEBHOOK_SECRET` — random string to authenticate webhook calls

---

## Manual Setup (Developer — Before Code)

### OneSignal (5 minutes)
1. Create account at [onesignal.com](https://onesignal.com)
2. New App → name it (e.g., "Hotel Manager")
3. Select platforms: **Google Android** + **Apple iOS** + **Web Push**
4. For Android: paste Firebase Server Key (from Firebase Console → Cloud Messaging)  
   *(Note: a Firebase project is still needed for Android native push — but no Firebase SDK in code)*
5. For iOS: upload APNs .p8 key (from Apple Developer portal)
6. For Web: set your PWA domain
7. Copy **App ID** and **REST API Key** → add to Supabase secrets

### Supabase Secrets
```
ONESIGNAL_APP_ID       = <from OneSignal>
ONESIGNAL_REST_API_KEY = <from OneSignal>
WEBHOOK_SECRET         = <random string, e.g. openssl rand -hex 32>
```

---

## Flutter Changes

**New files:**
- `lib/core/push/push_service.dart` — init OneSignal, set tags after login, remove tags on logout

**Modified files:**
- `pubspec.yaml` — add `onesignal_flutter: ^5.2.6`
- `lib/features/auth/login_screen.dart` — call `PushService.setupAfterLogin(role, hotelId, userId)`

No `google-services.json` handling needed in Flutter code (OneSignal SDK handles it via native layer, but the file still needs to be in `android/app/`).

---

## PWA Changes

**Modified files:**
- `hotel_guest_app/web/index.html` — add OneSignal Web SDK snippet (CDN)
- `hotel_guest_app/lib/core/push_service_web.dart` — JS interop to call OneSignal SDK
- `hotel_guest_app/lib/presentation/home_screen.dart` — "הפעל התראות" button

OneSignal provides its own Service Worker — no manual `firebase-messaging-sw.js` needed.

---

## Out of Scope

- Notification history screen
- Per-user notification preferences toggle
- Silent/data-only push
- Admin Panel push (web app, not mobile)
