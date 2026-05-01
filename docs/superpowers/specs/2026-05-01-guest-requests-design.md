# Guest Requests & Feedback — Design Spec

## Goal

Enable guests to submit service requests directly via a PWA (installable via QR code), and hotel staff to receive, route, and resolve them in real time. Includes end-of-stay guest feedback visible to management.

## Architecture

Two apps share a single Supabase backend:

1. **Guest PWA** — Flutter Web, installable via QR code in room (no App Store)
2. **Hotel App** — existing Flutter app, extended with guest requests feature

Real-time sync via Supabase Realtime (`StreamProvider`) on both sides. Requests are auto-routed by category via a Supabase DB trigger, with optional manual override by manager.

## Tech Stack

Flutter (hotel app) + Flutter Web (guest PWA) + Riverpod (StreamProvider/FutureProvider) + Supabase (RLS, Realtime, DB trigger for routing)

---

## Database

### `guest_requests` table

```sql
CREATE TABLE guest_requests (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id      uuid NOT NULL REFERENCES hotels(id),
  room_number   text NOT NULL,
  guest_name    text NOT NULL,
  category      text NOT NULL, -- 'housekeeping' | 'maintenance' | 'reception'
  description   text,
  status        text NOT NULL DEFAULT 'open',
    -- 'open' | 'assigned' | 'in_progress' | 'resolved' | 'cancelled'
  assigned_dept text,          -- auto-set by trigger
  assigned_to   uuid REFERENCES auth.users(id), -- optional manual override
  created_by    text NOT NULL DEFAULT 'guest',  -- 'guest' | 'reception'
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
```

### `guest_feedback` table

```sql
CREATE TABLE guest_feedback (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id    uuid NOT NULL REFERENCES hotels(id),
  room_number text NOT NULL,
  guest_name  text NOT NULL,
  rating      int  NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
```

### Auto-routing trigger

```sql
CREATE OR REPLACE FUNCTION route_guest_request()
RETURNS TRIGGER AS $$
BEGIN
  NEW.assigned_dept := CASE NEW.category
    WHEN 'housekeeping' THEN 'housekeeping'
    WHEN 'maintenance'  THEN 'maintenance'
    ELSE 'reception'
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_route_request
  BEFORE INSERT ON guest_requests
  FOR EACH ROW EXECUTE FUNCTION route_guest_request();
```

### RLS

- Hotel staff can SELECT/UPDATE requests where `hotel_id = their hotel`
- Guests (anonymous or session-based) can INSERT and SELECT their own requests (by `room_number` + `guest_name`)
- Only manager/admin can view `guest_feedback`

### Status flow

```
open → assigned → in_progress → resolved
         ↘                    ↗
              cancelled
```

---

## Guest PWA — `hotel_guest_app/` (new Flutter Web project)

### Screen 1: Landing

- Fields: Full name + room number
- Button: "כניסה"
- PWA install prompt shown below ("+ הוסף למסך הבית")
- Stores session locally (SharedPreferences): `guest_name`, `room_number`, `hotel_id`
- `hotel_id` comes from URL param: `https://guest.hotel.com/?hotel=<hotel_id>`
  (QR code in room encodes the hotel-specific URL)

### Screen 2: Home

- Header: "שלום [name] · חדר [number]"
- Primary button: "+ בקשה חדשה"
- List of guest's own requests (StreamProvider filtered by room_number + guest_name)
- Status badge colors: פתוחה=red, בטיפול=amber, טופלה=green
- Feedback banner appears after `stay_threshold` days (default: 3) from first login timestamp stored in SharedPreferences, if feedback not yet submitted for this session

### Screen 3: New Request

- Category chips (single select): 🛏️ חדרניות · 🔧 תחזוקה · 🛎️ קבלה
- Optional free-text description field
- "שלח בקשה" button → INSERT to `guest_requests`

### Screen 4: Feedback (end of stay)

- Shown when `now() - session_start >= stay_threshold` (session_start stored in SharedPreferences on first login)
- Star rating (1–5, required)
- Free text comment (optional)
- "שלח משוב" → INSERT to `guest_feedback`
- After submit: "תודה שבחרתם בנו 🙏" confirmation

### Providers (Guest PWA)

```dart
final myRequestsProvider = StreamProvider<List<GuestRequest>>(...);
// streams guest_requests filtered by room_number + guest_name

final submitRequestProvider = ...;  // FutureProvider.family or simple async method
final submitFeedbackProvider = ...; // same
```

---

## Hotel App — Extensions

### New model: `GuestRequest`

```dart
class GuestRequest {
  final String id;
  final String hotelId;
  final String roomNumber;
  final String guestName;
  final String category;       // 'housekeeping' | 'maintenance' | 'reception'
  final String? description;
  final String status;         // 'open' | 'assigned' | 'in_progress' | 'resolved' | 'cancelled'
  final String? assignedDept;
  final String? assignedTo;
  final String createdBy;      // 'guest' | 'reception'
  final DateTime createdAt;
}
```

### New model: `GuestFeedback`

```dart
class GuestFeedback {
  final String id;
  final String hotelId;
  final String roomNumber;
  final String guestName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
}
```

### Providers (Hotel App)

```dart
final guestRequestsProvider   = StreamProvider<List<GuestRequest>>(...);
// all requests for hotel, ordered by created_at desc

final myDeptRequestsProvider  = StreamProvider<List<GuestRequest>>(...);
// filtered by assigned_dept matching current user's role

final guestFeedbackProvider   = FutureProvider<List<GuestFeedback>>(...);
// for manager/admin only
```

### Reception screen additions

- New tab "בקשות אורחים" added to `ReceptionHomeScreen` bottom nav
- Filter chips: הכול | פתוחות | בטיפול | טופלו
- Request cards: room number, guest name, category, status badge, time elapsed
- FAB "+ בקשה ידנית" → opens new request form (same fields as guest PWA, `created_by = 'reception'`)

### Manager screen additions

- New tab "בקשות אורחים" in `ManagerHomeScreen`
- Summary bar: count of open / in_progress / resolved
- Request list with "שנה הקצאה" option (bottom sheet with staff list)
- Separate "משובים" tab showing `guest_feedback` list with star ratings

### Staff screen additions (housekeeping + maintenance)

- New tab "בקשות" in their home screens
- Shows only requests where `assigned_dept` matches their role
- Each card: room number, guest name, description
- Button: "התחל טיפול" (open → in_progress) · "סמן כטופל" (in_progress → resolved)
- On resolve: update `status = 'resolved'`, `updated_at = now()`

---

## Navigation / Routing

No new routes needed in the hotel app — guest requests are tabs within existing role screens.

Guest PWA is a separate Flutter Web project with its own router:
- `/` → Landing (if no session) or Home (if session exists)
- `/new` → New Request
- `/feedback` → Feedback form

---

## Notifications

- **In-app**: Realtime stream means new requests appear instantly for all relevant staff
- **Push**: Deferred to Module 4. Placeholder comment: `// TODO(Module 4): send push to assigned dept`

---

## Out of Scope

- PMS integration (Opera/Optima) — future module
- Full PWA install flow customization (manifest, service worker hardening) — basic PWA metadata included
- Per-staff assignment within a department (manager can manually assign to specific person if needed)
- Request history beyond current session for guests
- Photo attachments on requests
