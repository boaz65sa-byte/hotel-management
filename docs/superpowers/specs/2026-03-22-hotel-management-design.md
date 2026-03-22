# Hotel Management App - Design Spec
**Date**: 2026-03-22
**Status**: Approved by user
**Version**: 1.1 (post spec-review fixes)

---

## 1. Overview

A multi-tenant hotel service ticket management platform. Staff open service tickets for room issues, the relevant department handles and documents them with photos, and the resolution flows back to the opener with clear status indicators. Built as a Flutter mobile app (iOS + Android) and web app, with full offline capability.

The product is designed to be sold to individual hotels and hotel chains, with white-label theming per organization.

---

## 2. Goals

- Streamline service request flow between hotel departments
- Provide full ticket lifecycle visibility with photo documentation
- Work reliably offline in areas with poor connectivity
- Support multiple hotels under one platform (multi-tenant)
- Provide a Super Admin panel for the app owner to manage all tenants

---

## 3. Non-Goals (V1)

- Integration with Optima (deferred to V2)
- WhatsApp Business API notifications (deferred to V2)
- SMS or email push notifications (deferred to V2)
- Mobile OS push notifications via FCM/APNs (deferred to V2)
- Advanced SLA rules per ticket type (V1 uses fixed per-hotel SLA)

---

## 4. Architecture

### 4.1 Tech Stack

| Layer | Technology | Reason |
|-------|-----------|--------|
| Mobile App | Flutter | Single codebase for iOS + Android + Web |
| Backend | Supabase | Auth + DB + Storage + Realtime out of the box |
| Database | PostgreSQL (via Supabase) | Relational, RLS for multi-tenant isolation |
| File Storage | Supabase Storage | Per-hotel buckets, enforced size limits |
| Realtime | Supabase Realtime (WebSockets) | Live ticket updates across users |
| Offline | SQLite (local cache) + sync queue | Full offline support |
| Super Admin | Next.js Web App | Separate dashboard, server-side Supabase service role |
| Excel Export | `excel` Flutter package + server-side Supabase Edge Function | Client-side simple exports, server-side for large reports |

### 4.2 System Diagram

```
┌─────────────────────────────────────────┐
│           Flutter App                   │
│   (Mobile iOS/Android + Web)            │
│                                         │
│  ┌─────────┐  ┌──────────┐             │
│  │ SQLite  │  │ Realtime │             │
│  │  Cache  │  │  Updates │             │
│  └────┬────┘  └────┬─────┘             │
└───────┼────────────┼────────────────────┘
        │            │  (anon/user JWT)
        ▼            ▼
┌───────────────────────────────────────┐
│              SUPABASE                 │
│  Auth | PostgreSQL | Storage          │
│  Realtime | Row Level Security        │
└───────────────┬───────────────────────┘
                │  (service role key, server-side only)
                ▼
┌───────────────────────┐
│   Super Admin Panel   │
│   (Next.js - Web)     │
│   Server-side only    │
│   App owner only      │
└───────────────────────┘
```

### 4.3 Multi-Tenant Isolation

- Every database table includes a `hotel_id` column
- Supabase RLS policies enforce that users only access rows where `hotel_id` matches their JWT claim
- Child tables (`ticket_updates`, `ticket_photos`, `ticket_approvals`) also carry `hotel_id` (denormalized) for efficient RLS without joins
- The Super Admin Next.js app uses the **Supabase service role key server-side only** (in Next.js API routes / server components). The service role key is never sent to the browser. This bypasses RLS for all hotels.

---

## 5. Data Model

### hotels
```sql
id                    uuid PRIMARY KEY
name                  text NOT NULL
logo_url              text
theme_colors          jsonb              -- { primary, secondary, accent }
subscription_plan     text               -- basic | pro | enterprise
default_sla_hours     integer DEFAULT 4  -- V1: single SLA per hotel
session_timeout_min   integer DEFAULT 480 -- minutes, configurable per hotel
storage_quota_gb      integer DEFAULT 10  -- per subscription_plan
is_active             boolean DEFAULT true
default_language      text DEFAULT 'he'  -- set during hotel onboarding
created_at            timestamptz DEFAULT now()
```

### users
```sql
id              uuid PRIMARY KEY  -- references auth.users
hotel_id        uuid REFERENCES hotels(id)  -- null for super_admin
full_name       text NOT NULL
email           text NOT NULL
role            text NOT NULL     -- see roles enum below
avatar_url      text
language        text              -- null = inherit hotel default_language
is_active       boolean DEFAULT true
created_at      timestamptz DEFAULT now()
```

**Roles enum:**
`super_admin | ceo | reception_manager | maintenance_manager | housekeeping_manager | security_manager | deputy_reception | receptionist | security_guard | maintenance_tech | repairman`

**Role clarification:**
- `maintenance_tech` and `repairman` are both in the Maintenance department. They have identical permissions. The distinction is job title only (a repairman may specialize in specific repairs). Both can open tickets and update tickets. Both are routed tickets from the Maintenance department queue.
- `receptionist` can only open tickets. Follow-up on resolved tickets is handled by `deputy_reception` or `reception_manager`.

### rooms
```sql
id              uuid PRIMARY KEY
hotel_id        uuid REFERENCES hotels(id)
room_number     text NOT NULL
floor           integer
room_type       text
status          text DEFAULT 'available'  -- available | on_hold | closed
notes           text
status_changed_by  uuid REFERENCES users(id)
status_changed_at  timestamptz
created_at      timestamptz DEFAULT now()
UNIQUE (hotel_id, room_number)
```

### tickets
```sql
id              uuid PRIMARY KEY
hotel_id        uuid REFERENCES hotels(id)
room_id         uuid REFERENCES rooms(id)
opened_by       uuid REFERENCES users(id)
assigned_dept   text NOT NULL    -- maintenance | housekeeping | security | reception
claimed_by      uuid REFERENCES users(id)  -- null = unassigned, visible to all dept members
title           text NOT NULL
description     text
priority        text DEFAULT 'normal'  -- low | normal | high | urgent
status          text DEFAULT 'open'
  -- open | in_progress | pending_approval | resolved | closed
resolution_type text               -- NOT NULL when status = resolved or closed
  -- fixed | on_hold | room_closed
sla_deadline    timestamptz        -- set at creation: now() + hotel.default_sla_hours
created_at      timestamptz DEFAULT now()
updated_at      timestamptz DEFAULT now()
resolved_at     timestamptz        -- set when status transitions to resolved/closed
```

**Assignment flow:**
1. Ticket is created with `claimed_by = null` (unassigned)
2. All members of `assigned_dept` see the ticket in their queue
3. Any dept member (or their manager) can claim the ticket → sets `claimed_by = user_id`, status → `in_progress`
4. Only one person claims a ticket at a time; claiming is first-come-first-served
5. **Claiming requires an active internet connection.** The claim action uses a conditional server-side update (`UPDATE tickets SET claimed_by = $user WHERE claimed_by IS NULL AND id = $id`) to prevent race conditions. If offline, the "Claim" button is disabled with a "connection required" message. All other actions (view, comment, add photo) work offline.

**Constraint:** `resolution_type` must be set (NOT NULL enforced at app layer) before status transitions to `resolved` or `closed`.

### ticket_updates
```sql
id              uuid PRIMARY KEY
hotel_id        uuid REFERENCES hotels(id)  -- denormalized for RLS
ticket_id       uuid REFERENCES tickets(id)
user_id         uuid REFERENCES users(id)
message         text
update_type     text   -- comment | status_change | photo_added | approval_request | claim
created_at      timestamptz DEFAULT now()
-- Append-only table. No updates or deletes. Not subject to conflict resolution.
```

### ticket_photos
```sql
id              uuid PRIMARY KEY
hotel_id        uuid REFERENCES hotels(id)  -- denormalized for RLS
ticket_id       uuid REFERENCES tickets(id)
uploaded_by     uuid REFERENCES users(id)
photo_url       text NOT NULL
file_size_bytes integer
taken_at        timestamptz
created_at      timestamptz DEFAULT now()
-- Append-only table. Not subject to conflict resolution.
-- Max file size: 10MB per photo enforced at upload.
```

### ticket_approvals
```sql
id              uuid PRIMARY KEY
hotel_id        uuid REFERENCES hotels(id)  -- denormalized for RLS
ticket_id       uuid REFERENCES tickets(id)
resolution_type text NOT NULL
  -- V1: always 'room_closed'. No DEFAULT — app must always supply explicitly.
submission_round integer NOT NULL DEFAULT 1
  -- increments each time ticket is resubmitted after rejection (for audit trail)
approver_id     uuid NOT NULL REFERENCES users(id)
  -- set at row creation: the manager holding that role at submission time
approver_role   text NOT NULL  -- maintenance_manager | reception_manager
approved        boolean        -- null = pending, true = approved, false = rejected
approved_at     timestamptz
notes           text
-- Append-only table. Not subject to conflict resolution.
-- On rejection + resubmission: new rows are created with submission_round + 1.
-- Old rows are preserved as audit trail. The completion query filters on MAX(submission_round).
```

**Approval completion query (current round):**
```sql
SELECT COUNT(*) FROM ticket_approvals
WHERE ticket_id = $ticket_id
  AND submission_round = (SELECT MAX(submission_round) FROM ticket_approvals WHERE ticket_id = $ticket_id)
  AND approver_role IN ('maintenance_manager', 'reception_manager')
  AND approved = true
-- Must equal 2 for ticket to close
```

**Approval completion rule:**
A ticket with `resolution_type = room_closed` transitions to `status = closed` when the current submission round has both required approvals:
```sql
SELECT COUNT(*) FROM ticket_approvals
WHERE ticket_id = $ticket_id
  AND submission_round = (
    SELECT MAX(submission_round) FROM ticket_approvals WHERE ticket_id = $ticket_id
  )
  AND approver_role IN ('maintenance_manager', 'reception_manager')
  AND approved = true
-- Must equal 2 for ticket to close
```
Both roles must have `approved = true` in the **current round**. If either has `approved = false` (rejected), the ticket returns to `in_progress` and the claimer is notified. Prior rounds are kept as audit trail only.

---

## 6. Ticket Routing (Department Rules)

All roles can open tickets. The opener selects the target department:

| Opened By | Can Route To |
|-----------|-------------|
| receptionist, deputy_reception, reception_manager | maintenance, housekeeping, security |
| housekeeping_manager | maintenance only (intentional — security issues escalate via reception) |
| maintenance_tech, repairman, maintenance_manager | security |
| security_guard, security_manager | maintenance, reception |
| ceo | any department |
| Any manager (all 5) | any department |

---

## 7. Ticket Lifecycle

```
[OPEN] (claimed_by = null)
  └── all dept members see ticket in queue
      │
      ▼ (any dept member claims)
[IN_PROGRESS] (claimed_by = user_id)
  └── claimer updates status, adds photos, adds comments
      │
      ▼ (claimer selects resolution_type)
      │
      ├── resolution_type = fixed
      │     └── [RESOLVED] ✅ green checkmark
      │           room status unchanged
      │           opener sees resolution in ticket timeline
      │
      ├── resolution_type = on_hold
      │     └── [RESOLVED] ⏸ yellow
      │           room status → on_hold
      │           opener sees "room on hold" in timeline
      │
      └── resolution_type = room_closed
            └── [PENDING_APPROVAL] 🔴
                  system creates 2 ticket_approval rows (submission_round = 1):
                    - approver_role = maintenance_manager, approver_id = current holder of that role
                    - approver_role = reception_manager,   approver_id = current holder of that role
                  both managers notified in-app
                  │
                  all approvals for current round approved = true?
                  ├── YES → [CLOSED] room status → closed
                  └── NO (any rejection) → back to [IN_PROGRESS]
                        claimer notified with rejection notes
                        on resubmission: 2 NEW ticket_approval rows created
                          with submission_round = previous_round + 1
                          old rows preserved as audit trail
```

**Receptionist follow-up:** A `receptionist` opens a ticket but cannot update it. Resolution visibility is automatic — when the ticket reaches `resolved` or `closed`, the receptionist sees the green/red indicator on their ticket list and in the ticket timeline. No action required from them. If escalation is needed, `deputy_reception` or `reception_manager` handles it.

---

## 8. Room Status Transitions

```
available ──► on_hold   (ticket resolution_type = on_hold)
available ──► closed    (ticket resolution_type = room_closed, both approvals done)
on_hold   ──► available (manual reset by: ceo, reception_manager, maintenance_manager)
on_hold   ──► closed    (ticket resolution_type = room_closed, both approvals done)
closed    ──► available (manual reset by: ceo, reception_manager, maintenance_manager)
```

Manual room status reset requires selecting a reason (text field, mandatory).

---

## 9. Permissions Matrix

| Role | Open Ticket | Claim & Update | Approve Room Close | View Analytics | Manage Users |
|------|:-----------:|:--------------:|:-----------------:|:--------------:|:------------:|
| CEO | ✓ | ✓ | ✓ | ✓ | ✓ |
| Reception Manager | ✓ | ✓ | ✓ (required) | ✓ | ✓ |
| Maintenance Manager | ✓ | ✓ | ✓ (required) | ✓ | ✓ |
| Housekeeping Manager | ✓ | ✓ | ✓ | ✓ | ✓ |
| Security Manager | ✓ | ✓ | ✓ | ✓ | ✓ |
| Deputy Reception | ✓ | ✓ | ✗ | ✗ | ✗ |
| Receptionist | ✓ (open only) | ✗ | ✗ | ✗ | ✗ |
| Security Guard | ✓ | ✓ | ✗ | ✗ | ✗ |
| Maintenance Tech | ✓ | ✓ | ✗ | ✗ | ✗ |
| Repairman | ✓ | ✓ | ✗ | ✗ | ✗ |
| **Super Admin** | **✓** | **✓** | **✓** | **✓** | **✓** |

---

## 10. App Screens

### All Users
- **Login** — email + password + language selector
- **Home / Dashboard** — my open tickets, department queue, in-app notifications
- **Tickets List** — filter by dept / room / date / status / priority
- **Ticket Detail** — full timeline (opener, claims, updates, photos, approvals), action buttons per role
- **New Ticket** — room selector, dept selector, title, description, optional photo
- **Rooms Grid** — color coded by status (green/yellow/red), per floor, tap to see open tickets
- **Profile** — language, avatar, password change

### Managers + CEO Only
- **Analytics Dashboard** — graphs: tickets/day/week/month, avg close time, per-tech, per-room, SLA compliance, trend comparison, Excel export
- **User Management** — add/edit/deactivate users, assign roles
- **Room Management** — add rooms, import CSV, manual status override with reason

### Super Admin Panel (Next.js Web, separate app)
- **Hotels Management** — add/edit hotels, logo, theme colors, SLA hours, session timeout, activate/deactivate
- **Global Users** — all users across all hotels, block/unblock, reset password
- **Global Analytics** — cross-hotel stats, trends, SLA compliance
- **System Settings** — feature flags, app version management
- **Audit Logs** — all system actions, user activity across all hotels

---

## 11. Offline Behavior

### Local Cache (SQLite)
- All tickets relevant to the user's role/dept are cached on device
- Photos stored locally until upload succeeds (respecting 10MB limit)
- All write actions queued when offline

### Sync Queue
- Actions execute in FIFO order when connection returns
- Supabase Realtime pushes live updates to online users

### Conflict Resolution Rules
- **`tickets` table**: last-write-wins on `updated_at`. User notified if local version was overridden.
- **`ticket_updates`, `ticket_photos`, `ticket_approvals`**: append-only. Each write creates a new row. No conflict possible — all offline rows are inserted on reconnect, preserving their original `created_at`.

---

## 12. Theming (White-Label)

Configured per hotel in Super Admin:
- Hotel logo (PNG/SVG, max 2MB)
- Primary color (hex)
- Secondary color (hex)
- Accent color (hex)

Flutter reads theme config on login. Config cached locally so theming works offline. Default theme used until hotel config is received.

---

## 13. Internationalization (i18n)

- V1 supported languages: Hebrew (RTL), English (LTR), Arabic (RTL)
- Language selected at login, changeable in profile. Falls back to hotel's `default_language`.
- All UI strings in translation files (Flutter's `intl` package)
- RTL/LTR layout handled by Flutter `Directionality` widget

---

## 14. Authentication & Security

- Supabase Auth (email + password)
- Role embedded in user JWT via Supabase custom claims
- RLS policies use JWT claim `hotel_id` and `role` for all queries
- Super Admin Next.js panel: service role key in server-side code only, never exposed to browser
- Password reset via Supabase built-in email flow
- Session timeout per hotel (`hotels.session_timeout_min`). Default: 480 min (8 hours)
- Super Admin panel: separate login URL, 2FA enforced (Supabase MFA)

---

## 15. Analytics & Reporting

Available to all managers and Super Admin:

| Metric | Description |
|--------|-------------|
| Tickets opened/closed | Per day / week / month |
| Average close time | Overall, by department, by priority |
| Per-technician report | Tickets handled, avg time, open vs closed |
| Per-room report | Which rooms have most issues |
| SLA compliance | % tickets closed within `default_sla_hours` |
| Trend comparison | Current vs previous period |
| Excel export | All of the above — Flutter `excel` package for simple exports, Supabase Edge Function for large datasets |

`sla_deadline` is set at ticket creation: `now() + hotel.default_sla_hours`. SLA compliance = tickets where `resolved_at <= sla_deadline`.

---

## 16. Room Management

- Add rooms manually: room number (unique per hotel), floor, type
- Import via CSV/Excel with defined format:
  ```
  room_number, floor, room_type
  101, 1, standard
  102, 1, deluxe
  ```
  - Duplicate room numbers: skip + report in import summary
  - Invalid rows: skip + list in import error report shown to user
  - Max import: 500 rooms per file
- Room statuses: Available (green) / On Hold (yellow) / Closed (red)
- Status auto-updates on ticket resolution; manual override by managers with mandatory reason

---

## 17. Storage & Quotas

| Plan | Storage Quota | Max photo size |
|------|-------------|----------------|
| Basic | 10 GB | 10 MB |
| Pro | 50 GB | 10 MB |
| Enterprise | 200 GB | 10 MB |

Photos exceeding 10MB are rejected at upload with a clear error message. When hotel storage quota is reached, uploads are blocked and Super Admin is notified.

---

## 18. Future Features (V2+)

| Feature | Description |
|---------|-------------|
| WhatsApp Business API | Ticket notifications via WhatsApp |
| Optima Integration | Import room/guest data from Optima PMS |
| SMS Notifications | Via Twilio or similar |
| Mobile push notifications | FCM / APNs |
| Advanced SLA rules | Custom deadlines per ticket type or priority |
| Guest-facing portal | Guests report issues directly |
| 2FA for hotel staff | TOTP-based second factor |
