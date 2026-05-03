# Phase 10 — QR Codes, Reports & Admin Panel Design Spec

**Date:** 2026-05-02
**Status:** Approved
**Scope:** Three independent sub-phases building on the completed Phase 9 Guest Requests system

---

## Overview

Phase 10 extends the guest requests feature with three delivery layers:

1. **10a — QR Codes**: Generate per-room QR codes that link guests to the PWA (`hotel_guest_app`). Available from both the Flutter app (display + share) and the Admin Panel (bulk PDF download per hotel).
2. **10b — Reports/Export**: Excel export of guest requests and feedback, accessible to managers and hotel admins directly from the Flutter app.
3. **10c — Admin Panel**: New Next.js pages for managing guest requests, viewing feedback, and configuring hotel settings (`stay_threshold`).

Push Notifications (Web Push) are explicitly **out of scope for Phase 10** — deferred to Phase 11.

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Flutter QR | `qr_flutter` (render), `screenshot` (capture), `share_plus` (share), `path_provider` (save) |
| Admin QR | `qrcode` npm package (server-side SVG/PNG generation) |
| Flutter Export | `excel` + `share_plus` + `path_provider` (all already in `pubspec.yaml`) |
| Admin Panel | Next.js 16 App Router + Server Actions + `supabaseAdmin` (existing pattern) |

---

## Phase 10a — QR Codes

### Goal

Each hotel room gets a unique QR code encoding:
```
https://<pwa-domain>/?hotel=<hotel_id>&room=<room_number>
```

The PWA's `LandingScreen` already reads `hotel` from URL params. It should also read `room` to pre-fill the room number field, reducing friction for guests.

### Flutter App — QR Display + Share

**Where:** New bottom sheet triggered by a "QR חדר" button on `GuestRequestsListScreen` (reception/manager only — FAB area or AppBar action).

**Behavior:**
- Shows a full-screen bottom sheet with the QR code for the hotel
- Displays the hotel's PWA URL below the QR code
- Two buttons: "שתף" (share as PNG via `share_plus`) and "שמור" (save to gallery)
- QR is generated from: `https://guest.hotel.com/?hotel=<hotel_id>` (hotel-level, not per-room — room is filled in on landing screen by the guest)
- Uses `qr_flutter` widget + `screenshot` package to capture as PNG

**New files:**
- `lib/features/guest_requests/presentation/hotel_qr_screen.dart`

**Modified files:**
- `lib/features/guest_requests/presentation/guest_requests_list.dart` — add "QR" action to AppBar
- `pubspec.yaml` — add `qr_flutter`, `screenshot`

### Admin Panel — Bulk QR per Hotel

**Where:** New page at `/dashboard/hotels/[id]/qr-codes`

**Behavior:**
- Lists all rooms for the hotel (from `rooms` table: `room_number`)
- Each row shows: room number, QR preview (inline SVG), "הורד PNG" button
- "הורד הכול כ-ZIP" — downloads all QR PNGs in a zip (one per room)
- Each QR URL: `https://guest.hotel.com/?hotel=<hotel_id>&room=<room_number>`
- Link added from hotel edit page (`/dashboard/hotels/[id]`)

**New files:**
- `admin/src/app/dashboard/hotels/[id]/qr-codes/page.tsx`
- `admin/src/app/dashboard/hotels/[id]/qr-codes/actions.ts`

**Modified files:**
- `admin/src/app/dashboard/hotels/[id]/page.tsx` — add "QR Codes" link

**PWA change (minor):**
- `hotel_guest_app/lib/presentation/landing_screen.dart` — read `room` from URL params and pre-fill the room field if present

---

## Phase 10b — Reports / Excel Export

### Goal

Managers and hotel admins can export guest requests and feedback to Excel directly from the Flutter app, then share via system share sheet.

### Scope

- **Who:** `manager`, `hotel_admin`, `super_admin` roles only (hidden from staff)
- **From:** Two screens:
  - `GuestRequestsListScreen` — export button in AppBar
  - `GuestFeedbackScreen` — export button in AppBar
- **Format:** Single `.xlsx` file with two sheets: "בקשות אורחים" and "משובי אורחים"

### Excel Structure

**Sheet 1 — בקשות אורחים:**
| עמודה | מקור |
|-------|-------|
| חדר | `room_number` |
| שם אורח | `guest_name` |
| קטגוריה | `category` (מתורגם: housekeeping→חדרניות, maintenance→תחזוקה, reception→קבלה) |
| סטטוס | `status` (מתורגם) |
| נוצר על ידי | `created_by` (guest→אורח, reception→קבלה) |
| תיאור | `description` |
| תאריך יצירה | `created_at` (dd/MM/yyyy HH:mm) |

**Sheet 2 — משובי אורחים:**
| עמודה | מקור |
|-------|-------|
| חדר | `room_number` |
| שם אורח | `guest_name` |
| דירוג | `rating` (1–5 ★) |
| תגובה | `comment` |
| תאריך | `created_at` (dd/MM/yyyy) |

### Architecture

- New file: `lib/features/guest_requests/data/guest_export_service.dart` — pure function `exportGuestData` that accepts lists of requests and feedback, builds the Excel workbook, saves to temp dir, returns file path
- Both screens call `exportGuestData` and pass result to `Share.shareXFiles`
- No new providers needed — export uses data already in `allGuestRequestsProvider` + `guestFeedbackProvider`

---

## Phase 10c — Admin Panel Pages

### Goal

Super admins can monitor guest requests and feedback across all hotels, and configure per-hotel `stay_threshold`.

### New Pages

#### `/dashboard/guest-requests`
- Table: hotel name, room, guest name, category, status, created_at
- Filters: by hotel (dropdown), by status (chips), by date range (from/to)
- Sortable by created_at (newest first default)
- Row click: expand inline to show description + assigned_dept

#### `/dashboard/guest-feedback`
- Table: hotel name, room, guest name, rating (★ stars), comment, created_at
- Summary bar at top: average rating per hotel
- Filter by hotel

#### `/dashboard/hotels/[id]` — Extended
- Add field: `stay_threshold` (number of days, default 3) → stored in `hotels` table (requires DB migration)
- Add link: "QR Codes →" (to `/dashboard/hotels/[id]/qr-codes`)

### DB Migration Required
```sql
ALTER TABLE hotels
  ADD COLUMN IF NOT EXISTS stay_threshold INT NOT NULL DEFAULT 3;
```

### Architecture
- All pages: async Server Components with `supabaseAdmin`
- Sidebar: add "🛎️ בקשות אורחים" and "⭐ משובים" nav items
- No client-side state — filter params via URL searchParams (Next.js pattern)
- Filter forms: native HTML `<form>` with `GET` action (no JS required)

---

## PWA Update (part of 10a)

In `hotel_guest_app/lib/presentation/landing_screen.dart`:
- If URL has `?room=<number>`, pre-fill `_roomCtrl` with that value
- This is a minor 3-line change, included in Phase 10a plan

---

## Out of Scope

- Push Notifications (Phase 11)
- Per-room QR code generation in Flutter (hotel-level QR only; per-room is Admin Panel only)
- Guest request analytics charts (existing Analytics screen is separate)
- CSV export (Excel only)
- Email delivery of reports (share sheet only)
