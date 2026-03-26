# Hotel Management App — Pro Features Design
**Date:** 2026-03-25
**Status:** Approved (v3 — final)
**Approach:** A — Incremental extension of existing codebase

---

## Overview

Expanding the hotel management app (Flutter/Supabase/Next.js) from a basic ticketing system to a professional task management and accountability platform, competing with RoomChecking.

---

## Users & Role Mapping

11 existing `UserRole` values mapped to 4 home screens:

| UserRole (existing) | Home Screen | Notes |
|---|---|---|
| `receptionist`, `deputyReception`, `receptionManager` | `ReceptionHomeScreen` | Full access |
| `maintenanceTech`, `repairman`, `maintenanceManager` | `MaintenanceHomeScreen` | Full access |
| `housekeepingManager` | `HousekeepingHomeScreen` | Covers all housekeeping staff — no separate worker role exists in enum |
| `securityManager`, `securityGuard` | `ReceptionHomeScreen` | Read-only: widget-level only, action buttons hidden |
| `ceo`, `superAdmin` | `ManagerHomeScreen` | Full access |

**`isManager`** = `ceo | superAdmin | receptionManager | maintenanceManager | housekeepingManager | securityManager`

**Security read-only:** Enforced at widget level — action buttons hidden via `role.canClaimAndUpdate` guard (already exists). No new RLS needed since security roles cannot claim/update tickets by existing logic.

---

## Themes

Two design themes, selectable per hotel via admin panel. Stored as `hotels.theme TEXT ('luxury' | 'clean_blue')`.

The new system **replaces** the existing `HotelTheme.fromJson()` hex-color approach with two named themes:

| Theme | Style | Target |
|-------|-------|--------|
| **Luxury Dark** | Dark (#1a1a2e) + gold (#e4b800) | 4-5 star hotels |
| **Clean Blue** | White + blue (#1e40af) | All hotel types |

`AppTheme.forHotel(String theme)` returns a `ThemeData`. Called once at login, stored in `themeProvider`.

---

## Implementation Phases

### Phase 1 — Themes
**DB migration:**
```sql
ALTER TABLE hotels ADD COLUMN theme TEXT NOT NULL DEFAULT 'clean_blue'
  CHECK (theme IN ('luxury', 'clean_blue'));
```
- Implement `AppTheme.forHotel()` with two complete `ThemeData` objects
- Theme picker in Admin Panel `/dashboard/hotels` (replaces existing color pickers)
- Load `hotels.theme` at login, apply globally

---

### Phase 2 — Role-Based Home Screens
- `HomeScreen` reads `UserRole` from JWT → routes to correct home screen
- Four new screens (see role mapping table above)
- Each screen has its own `providers/` directory

**File structure:**
```
features/home/presentation/
  home_screen.dart              ← role router
  housekeeping_home.dart
  maintenance_home.dart
  reception_home.dart
  manager_home.dart
features/home/providers/
  housekeeping_home_provider.dart   ← today's rooms query
  maintenance_home_provider.dart    ← ticket queue + SLA state
  manager_home_provider.dart        ← KPIs + SLA summary
```

**Rooms — housekeeping status:**
Add `dirty | cleaning | clean` statuses to rooms table:
```sql
ALTER TABLE rooms ADD COLUMN housekeeping_status TEXT
  NOT NULL DEFAULT 'clean'
  CHECK (housekeeping_status IN ('dirty', 'cleaning', 'clean'));
```
- Set to `dirty` automatically on guest check-out (Phase 8 PMS, or manually by reception)
- Set to `cleaning` when housekeeping claims the checklist instance
- Set to `clean` when checklist instance is completed

**Reception quick ticket creation:**
- Tapping a room in the grid opens a bottom sheet with pre-filled room number
- One-tap priority buttons (low / normal / high / urgent)
- Department auto-selected based on ticket type
- Submit with single tap — no full-screen navigation required

---

### Phase 3 — Quick Actions on Ticket Cards
> **Dependency:** Requires `accepted_at` column from Phase 5 DB migration.
> Implement Phase 5 DB migration first, then build Phase 3 UI.

Redesign `TicketCard` widget:
- `[📸 לפני]` → opens camera, uploads to `ticket_photos` table (existing pattern), sets `tickets.photo_before_url = url`
- `[▶ קח אחריות]` → sets `status = in_progress`, `accepted_at = NOW()`
- `[✅ סגור]` → validates `photo_after_url != null`, then sets `status = resolved`, `resolved_at = NOW()`

**photo_before_url / photo_after_url** are convenience columns on `tickets` pointing to the primary before/after photo. Full photo history remains in `ticket_photos` table (existing pattern preserved).

---

### Phase 4 — Proof of Work
**DB migration:**
```sql
ALTER TABLE tickets
  ADD COLUMN photo_before_url TEXT,
  ADD COLUMN photo_after_url  TEXT;
```

**Riverpod guard:**
```dart
final canResolveProvider = Provider.family<bool, String>((ref, ticketId) {
  final ticket = ref.watch(ticketDetailProvider(ticketId)).valueOrNull;
  return ticket?.photoAfterUrl != null;
});
```

**UI enforcement:**
- "סגור קריאה" button disabled + tooltip "נדרשת תמונה אחרי" when `canResolve = false`
- Camera icon highlighted in red on ticket card when after-photo is missing and ticket is `in_progress`

---

### Phase 5 — Time Tracking & SLA
**DB migration:**
```sql
ALTER TABLE tickets
  ADD COLUMN accepted_at  TIMESTAMPTZ,
  ADD COLUMN resolved_at  TIMESTAMPTZ;
-- sla_deadline already exists — compute it at ticket creation:
-- sla_deadline = created_at + INTERVAL per priority
```

**SLA computation (on ticket insert trigger):**
```sql
CREATE OR REPLACE FUNCTION set_sla_deadline()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.sla_deadline := NEW.created_at + CASE NEW.priority
    WHEN 'urgent'  THEN INTERVAL '60 minutes'
    WHEN 'high'    THEN INTERVAL '2 hours'
    WHEN 'normal'  THEN INTERVAL '4 hours'
    WHEN 'low'     THEN INTERVAL '8 hours'
    ELSE INTERVAL '4 hours'
  END;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_set_sla_deadline
  BEFORE INSERT ON tickets
  FOR EACH ROW EXECUTE FUNCTION set_sla_deadline();
```

**SLA analytics query (Edge Function `sla-report`):**
```sql
SELECT
  COUNT(*) AS total,
  AVG(EXTRACT(EPOCH FROM (accepted_at - created_at))/60)::int AS avg_response_min,
  AVG(EXTRACT(EPOCH FROM (resolved_at - accepted_at))/60)::int AS avg_resolve_min,
  COUNT(*) FILTER (WHERE resolved_at > sla_deadline) AS sla_breaches,
  COUNT(*) FILTER (WHERE resolved_at IS NULL AND NOW() > sla_deadline) AS active_breaches
FROM tickets
WHERE hotel_id = $1
  AND created_at > NOW() - INTERVAL '30 days';
```

---

### Phase 6 — Checklists
**Scope:** Templates are **global** (created by Super Admin, used by all hotels). No `hotel_id` on templates.

**DB migrations:**
```sql
CREATE TABLE checklist_templates (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('housekeeping', 'maintenance')),
  is_vip      BOOLEAN NOT NULL DEFAULT false,
  created_by  UUID REFERENCES auth.users(id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE checklist_items (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id   UUID NOT NULL REFERENCES checklist_templates(id) ON DELETE CASCADE,
  order_index   INT NOT NULL,
  title_he      TEXT NOT NULL,
  title_en      TEXT,
  requires_photo BOOLEAN NOT NULL DEFAULT false,
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE checklist_instances (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id  UUID NOT NULL REFERENCES checklist_templates(id),
  room_id      UUID REFERENCES rooms(id),        -- nullable: hotel-level checklists have no room
  assigned_to  UUID REFERENCES auth.users(id),
  hotel_id     UUID NOT NULL REFERENCES hotels(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE checklist_instance_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instance_id UUID NOT NULL REFERENCES checklist_instances(id) ON DELETE CASCADE,
  item_id     UUID REFERENCES checklist_items(id) ON DELETE SET NULL, -- SET NULL if template item deleted
  is_done     BOOLEAN NOT NULL DEFAULT false,
  photo_url   TEXT,
  done_at     TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**`updated_at` triggers (shared function, applied to all 5 new tables):**
```sql
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER trg_updated_at_checklist_templates
  BEFORE UPDATE ON checklist_templates FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_checklist_items
  BEFORE UPDATE ON checklist_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_checklist_instances
  BEFORE UPDATE ON checklist_instances FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_checklist_instance_items
  BEFORE UPDATE ON checklist_instance_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_updated_at_scheduled_tasks
  BEFORE UPDATE ON scheduled_tasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

**RLS Policies:**
```sql
-- checklist_templates: readable by all authenticated, writable by super_admin only
ALTER TABLE checklist_templates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read templates" ON checklist_templates FOR SELECT TO authenticated USING (true);
CREATE POLICY "write templates" ON checklist_templates FOR ALL
  USING  ((auth.jwt()->'claims'->>'role') = 'superAdmin')
  WITH CHECK ((auth.jwt()->'claims'->>'role') = 'superAdmin');

-- checklist_items: same as templates
ALTER TABLE checklist_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read items" ON checklist_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "write items" ON checklist_items FOR ALL
  USING  ((auth.jwt()->'claims'->>'role') = 'superAdmin')
  WITH CHECK ((auth.jwt()->'claims'->>'role') = 'superAdmin');

-- checklist_instances: scoped to hotel_id
ALTER TABLE checklist_instances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hotel instances" ON checklist_instances FOR ALL
  USING ((auth.jwt()->'claims'->>'hotel_id')::uuid = hotel_id);

-- checklist_instance_items: via instance's hotel
ALTER TABLE checklist_instance_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hotel instance items" ON checklist_instance_items FOR ALL
  USING (EXISTS (
    SELECT 1 FROM checklist_instances ci
    WHERE ci.id = instance_id
      AND (auth.jwt()->'claims'->>'hotel_id')::uuid = ci.hotel_id
  ));
```

**Default templates (seeded by Super Admin):**
1. ניקיון רגיל (8 items, housekeeping)
2. ניקיון VIP (12 items, housekeeping, is_vip=true)
3. ביקורת אחזקה (10 items, maintenance)

---

### Phase 7 — Tasks & Automations
**DB migration:**
```sql
CREATE TABLE scheduled_tasks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id      UUID NOT NULL REFERENCES hotels(id),
  room_id       UUID REFERENCES rooms(id),   -- nullable: hotel-level tasks
  title         TEXT NOT NULL,
  description   TEXT,
  recurrence    TEXT NOT NULL CHECK (recurrence IN ('daily','weekly','monthly','quarterly')),
  assigned_role TEXT NOT NULL,               -- maps to tickets.assigned_dept
  next_run_at   TIMESTAMPTZ NOT NULL,
  last_run_at   TIMESTAMPTZ,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE scheduled_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hotel tasks" ON scheduled_tasks FOR ALL
  USING ((auth.jwt()->'claims'->>'hotel_id')::uuid = hotel_id
      OR (auth.jwt()->'claims'->>'role') = 'superAdmin');
```

**pg_cron job** (runs every hour via Supabase Edge Function `run-scheduled-tasks`):
1. SELECT all `scheduled_tasks` WHERE `is_active = true` AND `next_run_at <= NOW()`
2. For each: INSERT into `tickets` with `title`, `hotel_id`, `room_id`, `assigned_dept = assigned_role`, `priority = 'normal'`
3. UPDATE `scheduled_tasks` SET `last_run_at = NOW()`, `next_run_at = NOW() + recurrence_interval`

`assigned_role` → `tickets.assigned_dept` (existing TEXT field).

---

### Phase 8 — PMS Webhooks (Roadmap — out of scope for this iteration)
- Edge Function `/functions/pms-webhook`
- On check-out event: set `rooms.housekeeping_status = 'dirty'`, create housekeeping checklist instance
- Supports Optima and Opera via per-hotel webhook config

---

## Offline Behavior
- Checklist item completions queued in `sync_queue` when offline, flushed by `SyncWorker` on reconnect
- Proof of work photos stored locally, uploaded on reconnect
- Ticket quick actions (claim, resolve) queued if offline — same pattern as existing ticket operations

---

## File Structure Changes (Flutter)

```
lib/
  core/
    theme/
      app_theme.dart                  ← replace HotelTheme.fromJson() with AppTheme.forHotel()
      theme_provider.dart             ← load from hotel JWT claim
  features/
    home/
      presentation/
        home_screen.dart              ← role router
        housekeeping_home.dart        ← NEW
        maintenance_home.dart         ← NEW
        reception_home.dart           ← NEW
        manager_home.dart             ← NEW
      providers/
        housekeeping_home_provider.dart
        maintenance_home_provider.dart
        manager_home_provider.dart
    tickets/presentation/
      ticket_card.dart                ← Quick Actions redesign
      ticket_detail_screen.dart       ← proof of work enforcement
    checklists/                       ← NEW module
      data/checklist_repository.dart
      domain/checklist_model.dart
      presentation/
        checklist_screen.dart
        checklist_item_tile.dart
      providers/checklist_provider.dart
    analytics/presentation/
      analytics_screen.dart           ← add SLA section
```

## Admin Panel Changes (Next.js)

- `/dashboard/hotels` — theme picker replaces color picker
- `/dashboard/checklists` — NEW: manage templates + items (Super Admin only)
- `/dashboard/automations` — NEW: manage scheduled tasks per hotel

---

## Success Criteria

- [ ] Each role logs in and sees their designated home screen (per role mapping table above)
- [ ] Switching hotel theme in admin panel reflects immediately on next app login
- [ ] A ticket with no `photo_after_url` cannot be moved to `resolved` status (UI button disabled + API rejects)
- [ ] `sla_deadline` is set automatically on ticket creation; manager dashboard shows breach count
- [ ] Housekeeping staff completes a 5-item checklist (all checkbox items) with 5 taps, zero typing
- [ ] A `scheduled_task` with `recurrence='daily'` generates a new ticket within 65 minutes of `next_run_at`
