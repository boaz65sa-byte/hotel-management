# Hotel Management App — Pro Features Design
**Date:** 2026-03-25
**Status:** Approved
**Approach:** A — Incremental extension of existing codebase

---

## Overview

Expanding the hotel management app (Flutter/Supabase/Next.js) from a basic ticketing system to a professional task management and accountability platform, competing with RoomChecking.

---

## Users & Access Levels

| Role | Access |
|------|--------|
| Housekeeping | Only today's cleaning tasks + checklists + proof of work |
| Maintenance | Only repair queue by priority + SLA timer + proof of work |
| Reception | Room status grid + quick ticket creation |
| Hotel Manager | Full access — dashboard, SLA reports, team management, automations |
| Super Admin (app owner) | All hotels + checklist template management |

---

## Themes

Two design themes, selectable per hotel via admin panel:

| Theme | Style | Target |
|-------|-------|--------|
| **Luxury Dark** | Dark background + gold (#e4b800) | 4-5 star hotels |
| **Clean Blue** | White + blue (#1e40af) | All hotel types |

Stored in `hotels.theme` ('luxury' | 'clean_blue'). Applied at login via `AppTheme.fromHotelTheme()`.

---

## Implementation Phases (Priority Order)

### Phase 1 — Themes
- Add `theme` field to `hotels` table
- Implement `LuxuryTheme` + `CleanBlueTheme` in `app_theme.dart`
- Theme switcher in Admin Panel hotel settings
- Load theme on login, apply to `MaterialApp`

### Phase 2 — Role-Based Home Screens
- `HousekeepingHomeScreen` — today's rooms to clean, active checklist, proof of work
- `MaintenanceHomeScreen` — ticket queue by priority, live SLA timer
- `ReceptionHomeScreen` — room grid with live status, quick ticket creation
- `ManagerHomeScreen` — KPI dashboard, SLA report, team management, automations
- Router switches home screen based on `role` from JWT claims

### Phase 3 — Quick Actions on Ticket Cards
- Redesign `TicketCard` widget with inline action buttons
- `[📸 Before]` → opens camera directly
- `[▶ Start]` → claims ticket + sets `accepted_at`
- `[✅ Close]` → validates photo_after_url exists, then resolves
- No need to open full ticket detail for common actions

### Phase 4 — Proof of Work (Before & After Photos)
**DB changes:**
```sql
ALTER TABLE tickets
  ADD COLUMN photo_before_url TEXT,
  ADD COLUMN photo_after_url  TEXT;
```
**Logic:**
- `photo_before_url` captured when ticket is opened (optional but encouraged)
- `photo_after_url` REQUIRED before status can move to `resolved`
- Riverpod guard: `canResolve = ticket.photo_after_url != null`
- UI: disabled resolve button with message if no after-photo

### Phase 5 — Time Tracking & SLA
**DB changes:**
```sql
ALTER TABLE tickets
  ADD COLUMN accepted_at  TIMESTAMPTZ,
  ADD COLUMN resolved_at  TIMESTAMPTZ,
  ADD COLUMN sla_minutes  INT DEFAULT 120;
```
**Analytics query:**
```sql
SELECT
  AVG(EXTRACT(EPOCH FROM (accepted_at - created_at))/60) AS avg_response_min,
  AVG(EXTRACT(EPOCH FROM (resolved_at - accepted_at))/60) AS avg_resolve_min,
  COUNT(*) FILTER (WHERE resolved_at - created_at > (sla_minutes * INTERVAL '1 minute')) AS sla_breaches
FROM tickets
WHERE hotel_id = $1 AND created_at > NOW() - INTERVAL '30 days';
```
**SLA thresholds by priority:**
- urgent: 60 min
- high: 120 min
- normal: 240 min
- low: 480 min

### Phase 6 — Checklists
**New tables:**
```sql
CREATE TABLE checklist_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT CHECK (type IN ('housekeeping', 'maintenance')),
  is_vip BOOLEAN DEFAULT false,
  created_by UUID REFERENCES auth.users(id)
);

CREATE TABLE checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID REFERENCES checklist_templates(id) ON DELETE CASCADE,
  order_index INT NOT NULL,
  title_he TEXT NOT NULL,
  title_en TEXT,
  requires_photo BOOLEAN DEFAULT false
);

CREATE TABLE checklist_instances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID REFERENCES checklist_templates(id),
  room_id UUID REFERENCES rooms(id),
  assigned_to UUID REFERENCES auth.users(id),
  hotel_id UUID REFERENCES hotels(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE checklist_instance_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instance_id UUID REFERENCES checklist_instances(id) ON DELETE CASCADE,
  item_id UUID REFERENCES checklist_items(id),
  is_done BOOLEAN DEFAULT false,
  photo_url TEXT,
  done_at TIMESTAMPTZ
);
```
**Templates managed by Super Admin only (in Next.js admin panel).**
Default templates: Standard Clean, VIP Clean, Maintenance Inspection.

### Phase 7 — Tasks & Automations
**New table:**
```sql
CREATE TABLE scheduled_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id UUID REFERENCES hotels(id),
  room_id UUID REFERENCES rooms(id),
  title TEXT NOT NULL,
  description TEXT,
  recurrence TEXT CHECK (recurrence IN ('daily','weekly','monthly','quarterly')),
  assigned_role TEXT,
  next_run_at TIMESTAMPTZ NOT NULL,
  last_run_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true
);
```
**Supabase pg_cron job** runs every hour, creates tickets from `scheduled_tasks` where `next_run_at <= NOW()`, then updates `next_run_at` based on `recurrence`.

### Phase 8 — PMS Webhooks (Roadmap)
- Edge Function `/functions/pms-webhook` receives check-out events
- Auto-creates housekeeping ticket for vacated room
- Supports Optima and Opera via configurable webhook format per hotel

---

## File Structure Changes (Flutter)

```
lib/
  core/
    theme/
      app_theme.dart           ← add LuxuryTheme + CleanBlueTheme
      theme_provider.dart      ← load from hotel settings
  features/
    home/presentation/
      home_screen.dart         ← role-based router
      housekeeping_home.dart   ← NEW
      maintenance_home.dart    ← NEW
      reception_home.dart      ← NEW
      manager_home.dart        ← NEW
    tickets/presentation/
      ticket_card.dart         ← add Quick Actions
      ticket_detail_screen.dart ← proof of work enforcement
    checklists/                ← NEW feature module
      data/checklist_repository.dart
      domain/checklist_model.dart
      presentation/checklist_screen.dart
      presentation/checklist_item_tile.dart
      providers/checklist_provider.dart
    analytics/presentation/
      analytics_screen.dart    ← add SLA section
```

---

## Admin Panel Changes (Next.js)

- `/dashboard/hotels` — add theme picker (Luxury / Clean Blue)
- `/dashboard/checklists` — NEW: manage checklist templates + items
- `/dashboard/automations` — NEW: manage scheduled tasks per hotel

---

## Success Criteria

- [ ] Each role sees only their relevant screens on login
- [ ] Hotel theme applies immediately after login
- [ ] Ticket cannot be resolved without after-photo
- [ ] SLA breach visible in manager dashboard
- [ ] Housekeeping staff can complete checklist without typing
- [ ] Scheduled tasks auto-generate tickets via pg_cron
