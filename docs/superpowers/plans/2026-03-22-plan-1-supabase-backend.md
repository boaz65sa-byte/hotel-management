# Hotel Management App - Plan 1: Supabase Backend

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up the complete Supabase backend — database schema, RLS policies, Auth configuration, Storage buckets, and custom JWT claims — so the Flutter app and Super Admin panel have a secure, multi-tenant foundation to build on.

**Architecture:** Single Supabase project with PostgreSQL + RLS for multi-tenant isolation. Every table has `hotel_id`. Child tables denormalize `hotel_id` for efficient RLS without joins. Super Admin bypasses RLS via service role key (server-side only).

**Tech Stack:** Supabase CLI, PostgreSQL, pgTAP (SQL tests), Supabase Auth, Supabase Storage

---

## Prerequisites

- Supabase account at supabase.com
- Supabase CLI installed: `brew install supabase/tap/supabase`
- Node.js 18+ (for Supabase CLI and Edge Functions)

---

## File Structure

```
supabase/
├── config.toml                        # Supabase CLI config
├── migrations/
│   ├── 20260322000001_hotels.sql
│   ├── 20260322000002_users.sql
│   ├── 20260322000003_rooms.sql
│   ├── 20260322000004_tickets.sql
│   ├── 20260322000005_ticket_updates.sql
│   ├── 20260322000006_ticket_photos.sql
│   ├── 20260322000007_ticket_approvals.sql
│   ├── 20260322000008_rls_policies.sql
│   ├── 20260322000009_custom_claims.sql
│   ├── 20260322000010_storage.sql
│   ├── 20260322000011_seed_test_data.sql
│   └── 20260322000012_rpcs.sql        # claim_ticket, create_approval_request, check_and_close_ticket
├── functions/
│   └── export-excel/
│       └── index.ts                   # Edge Function for Excel export
└── tests/
    ├── rls_isolation.sql              # pgTAP: hotel isolation tests
    ├── approval_logic.sql             # pgTAP: dual approval query tests
    └── room_status.sql                # pgTAP: room status transition tests
```

---

## Task 1: Initialize Supabase Project

**Files:**
- Create: `supabase/config.toml` (auto-generated)
- Create: `.env.example`

- [ ] **Step 1: Create project on Supabase dashboard**

Go to supabase.com → New Project → name: `hotel-management` → choose region closest to Israel (eu-west-1 or eu-central-1) → save the Project URL and anon key.

- [ ] **Step 2: Initialize Supabase CLI locally**

```bash
cd "/Users/boazsaada/manegmant resapceon"
supabase init
```
Expected: `supabase/` directory created with `config.toml`.

- [ ] **Step 3: Link to remote project**

```bash
supabase login
supabase link --project-ref <your-project-ref>
```
`project-ref` is the ID from your Supabase dashboard URL: `https://supabase.com/dashboard/project/<project-ref>`

- [ ] **Step 4: Create .env.example**

```bash
cat > .env.example << 'EOF'
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
EOF
```

- [ ] **Step 5: Add .env to .gitignore (already present, verify)**

```bash
grep ".env" "/Users/boazsaada/manegmant resapceon/.gitignore"
```
Expected: `.env` appears in output.

- [ ] **Step 6: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon"
git init
git add supabase/ .env.example .gitignore
git commit -m "feat: initialize supabase project structure"
```

---

## Task 2: Hotels Table

**Files:**
- Create: `supabase/migrations/20260322000001_hotels.sql`

- [ ] **Step 1: Write migration**

```sql
-- supabase/migrations/20260322000001_hotels.sql

CREATE TABLE hotels (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                text NOT NULL,
  logo_url            text,
  theme_colors        jsonb DEFAULT '{"primary":"#1976D2","secondary":"#424242","accent":"#FF6F00"}'::jsonb,
  subscription_plan   text NOT NULL DEFAULT 'basic' CHECK (subscription_plan IN ('basic','pro','enterprise')),
  default_sla_hours   integer NOT NULL DEFAULT 4 CHECK (default_sla_hours > 0),
  session_timeout_min integer NOT NULL DEFAULT 480 CHECK (session_timeout_min > 0),
  storage_quota_gb    integer NOT NULL DEFAULT 10,
  is_active           boolean NOT NULL DEFAULT true,
  default_language    text NOT NULL DEFAULT 'he' CHECK (default_language IN ('he','en','ar')),
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- Storage quota by plan (enforced at app layer, documented here)
-- basic: 10 GB, pro: 50 GB, enterprise: 200 GB

COMMENT ON TABLE hotels IS 'One row per tenant hotel. hotel_id is the multi-tenant isolation key.';
```

- [ ] **Step 2: Apply migration locally**

```bash
supabase db reset
```
Expected: Migration applied, no errors.

- [ ] **Step 3: Apply migration to remote**

```bash
supabase db push
```
Expected: `hotels` table visible in Supabase dashboard → Table Editor.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260322000001_hotels.sql
git commit -m "feat: add hotels table migration"
```

---

## Task 3: Users Table + Custom Claims

**Files:**
- Create: `supabase/migrations/20260322000002_users.sql`
- Create: `supabase/migrations/20260322000009_custom_claims.sql`

- [ ] **Step 1: Write users migration**

```sql
-- supabase/migrations/20260322000002_users.sql

CREATE TYPE user_role AS ENUM (
  'super_admin',
  'ceo',
  'reception_manager',
  'maintenance_manager',
  'housekeeping_manager',
  'security_manager',
  'deputy_reception',
  'receptionist',
  'security_guard',
  'maintenance_tech',
  'repairman'
);

CREATE TABLE users (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  hotel_id    uuid REFERENCES hotels(id),  -- NULL for super_admin
  full_name   text NOT NULL,
  email       text NOT NULL,
  role        user_role NOT NULL,
  avatar_url  text,
  language    text CHECK (language IN ('he','en','ar')),  -- NULL = inherit hotel default
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT super_admin_no_hotel CHECK (
    (role = 'super_admin' AND hotel_id IS NULL) OR
    (role != 'super_admin' AND hotel_id IS NOT NULL)
  )
);

COMMENT ON TABLE users IS 'Public profile for each auth user. hotel_id=NULL for super_admin.';
COMMENT ON COLUMN users.language IS 'NULL means inherit from hotels.default_language';
```

- [ ] **Step 2: Write custom claims function**

This embeds `hotel_id` and `role` into the JWT so RLS policies can use them without extra DB lookups.

```sql
-- supabase/migrations/20260322000009_custom_claims.sql

-- Function called automatically after each login to set custom JWT claims
CREATE OR REPLACE FUNCTION public.custom_jwt_claims()
RETURNS jsonb
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  user_record users%ROWTYPE;
BEGIN
  SELECT * INTO user_record FROM users WHERE id = auth.uid();

  IF NOT FOUND THEN
    RETURN '{}'::jsonb;
  END IF;

  RETURN jsonb_build_object(
    'hotel_id', user_record.hotel_id,
    'role',     user_record.role,
    'is_active', user_record.is_active
  );
END;
$$;

-- Hook into Supabase Auth to run on each token refresh
-- In Supabase dashboard: Auth → Hooks → add custom_jwt_claims as "Custom Access Token" hook
```

- [ ] **Step 3: Apply migrations**

```bash
supabase db push
```

- [ ] **Step 4: Configure JWT hook in Supabase dashboard**

Go to: Supabase Dashboard → Authentication → Hooks → Custom Access Token → select function `custom_jwt_claims`

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260322000002_users.sql supabase/migrations/20260322000009_custom_claims.sql
git commit -m "feat: add users table and custom JWT claims"
```

---

## Task 4: Rooms Table

**Files:**
- Create: `supabase/migrations/20260322000003_rooms.sql`

- [ ] **Step 1: Write migration**

```sql
-- supabase/migrations/20260322000003_rooms.sql

CREATE TYPE room_status AS ENUM ('available', 'on_hold', 'closed');

CREATE TABLE rooms (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id          uuid NOT NULL REFERENCES hotels(id),
  room_number       text NOT NULL,
  floor             integer,
  room_type         text,
  status            room_status NOT NULL DEFAULT 'available',
  notes             text,
  status_changed_by uuid REFERENCES users(id),
  status_changed_at timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),

  UNIQUE (hotel_id, room_number)
);

COMMENT ON TABLE rooms IS 'Hotel rooms. Status auto-updated by ticket resolution, or manually by managers.';
```

- [ ] **Step 2: Apply and verify**

```bash
supabase db push
```

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260322000003_rooms.sql
git commit -m "feat: add rooms table migration"
```

---

## Task 5: Tickets Table

**Files:**
- Create: `supabase/migrations/20260322000004_tickets.sql`

- [ ] **Step 1: Write migration**

```sql
-- supabase/migrations/20260322000004_tickets.sql

CREATE TYPE ticket_status AS ENUM (
  'open', 'in_progress', 'pending_approval', 'resolved', 'closed'
);

CREATE TYPE ticket_priority AS ENUM ('low', 'normal', 'high', 'urgent');

CREATE TYPE dept_name AS ENUM ('maintenance', 'housekeeping', 'security', 'reception');

CREATE TYPE resolution_type AS ENUM ('fixed', 'on_hold', 'room_closed');

CREATE TABLE tickets (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id        uuid NOT NULL REFERENCES hotels(id),
  room_id         uuid NOT NULL REFERENCES rooms(id),
  opened_by       uuid NOT NULL REFERENCES users(id),
  assigned_dept   dept_name NOT NULL,
  claimed_by      uuid REFERENCES users(id),  -- NULL = unassigned
  title           text NOT NULL,
  description     text,
  priority        ticket_priority NOT NULL DEFAULT 'normal',
  status          ticket_status NOT NULL DEFAULT 'open',
  resolution_type resolution_type,  -- NOT NULL enforced at app layer when resolving
  sla_deadline    timestamptz,      -- set at creation: now() + hotel.default_sla_hours
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  resolved_at     timestamptz,

  -- Room must belong to same hotel
  CONSTRAINT ticket_room_hotel_match CHECK (
    EXISTS (SELECT 1 FROM rooms WHERE id = room_id AND hotel_id = tickets.hotel_id)
  )
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER tickets_updated_at
  BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

COMMENT ON TABLE tickets IS 'Service tickets. claimed_by=NULL means unassigned/visible to all dept members.';
COMMENT ON COLUMN tickets.resolution_type IS 'Must be set before status transitions to resolved or closed (enforced at app layer).';
COMMENT ON COLUMN tickets.sla_deadline IS 'Set at creation: now() + hotels.default_sla_hours';
```

- [ ] **Step 2: Apply and verify**

```bash
supabase db push
```

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260322000004_tickets.sql
git commit -m "feat: add tickets table migration"
```

---

## Task 6: Ticket Child Tables

**Files:**
- Create: `supabase/migrations/20260322000005_ticket_updates.sql`
- Create: `supabase/migrations/20260322000006_ticket_photos.sql`
- Create: `supabase/migrations/20260322000007_ticket_approvals.sql`

- [ ] **Step 1: Write ticket_updates migration**

```sql
-- supabase/migrations/20260322000005_ticket_updates.sql

CREATE TYPE update_type AS ENUM (
  'comment', 'status_change', 'photo_added', 'approval_request', 'claim'
);

CREATE TABLE ticket_updates (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id    uuid NOT NULL REFERENCES hotels(id),  -- denormalized for RLS
  ticket_id   uuid NOT NULL REFERENCES tickets(id),
  user_id     uuid NOT NULL REFERENCES users(id),
  message     text,
  update_type update_type NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
  -- Append-only: no UPDATE or DELETE allowed (enforced via RLS)
);

COMMENT ON TABLE ticket_updates IS 'Append-only audit trail for ticket events. No updates or deletes.';
```

- [ ] **Step 2: Write ticket_photos migration**

```sql
-- supabase/migrations/20260322000006_ticket_photos.sql

CREATE TABLE ticket_photos (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id        uuid NOT NULL REFERENCES hotels(id),  -- denormalized for RLS
  ticket_id       uuid NOT NULL REFERENCES tickets(id),
  uploaded_by     uuid NOT NULL REFERENCES users(id),
  photo_url       text NOT NULL,
  file_size_bytes integer CHECK (file_size_bytes <= 10485760),  -- 10MB max
  taken_at        timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
  -- Append-only: no UPDATE or DELETE allowed
);

COMMENT ON TABLE ticket_photos IS 'Append-only photo log. Max 10MB per photo enforced at constraint and app layer.';
```

- [ ] **Step 3: Write ticket_approvals migration**

```sql
-- supabase/migrations/20260322000007_ticket_approvals.sql

CREATE TYPE approver_role AS ENUM ('maintenance_manager', 'reception_manager');

CREATE TABLE ticket_approvals (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id         uuid NOT NULL REFERENCES hotels(id),  -- denormalized for RLS
  ticket_id        uuid NOT NULL REFERENCES tickets(id),
  resolution_type  resolution_type NOT NULL,  -- no DEFAULT, app must supply
  submission_round integer NOT NULL DEFAULT 1 CHECK (submission_round > 0),
  approver_id      uuid NOT NULL REFERENCES users(id),
  approver_role    approver_role NOT NULL,
  approved         boolean,  -- NULL=pending, true=approved, false=rejected
  approved_at      timestamptz,
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now()
  -- Append-only. On rejection+resubmission: new rows with submission_round+1
);

-- Helper view: current round approval status for a ticket (uses CTE to avoid invalid window-in-aggregate)
CREATE VIEW ticket_approval_status AS
WITH latest AS (
  SELECT ticket_id, MAX(submission_round) AS current_round
  FROM ticket_approvals
  GROUP BY ticket_id
)
SELECT
  ta.ticket_id,
  l.current_round,
  COUNT(*) FILTER (WHERE ta.approved = true  AND ta.submission_round = l.current_round) AS approvals_given,
  COUNT(*) FILTER (WHERE ta.approved = false AND ta.submission_round = l.current_round) AS rejections_given
FROM ticket_approvals ta
JOIN latest l ON l.ticket_id = ta.ticket_id
GROUP BY ta.ticket_id, l.current_round;

COMMENT ON TABLE ticket_approvals IS 'Append-only. New rows per resubmission round. Query on MAX(submission_round) for current state.';
```

- [ ] **Step 4: Apply all three migrations**

```bash
supabase db push
```

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260322000005_ticket_updates.sql \
        supabase/migrations/20260322000006_ticket_photos.sql \
        supabase/migrations/20260322000007_ticket_approvals.sql
git commit -m "feat: add ticket child tables (updates, photos, approvals)"
```

---

## Task 7: RLS Policies

**Files:**
- Create: `supabase/migrations/20260322000008_rls_policies.sql`

- [ ] **Step 1: Write RLS policies**

```sql
-- supabase/migrations/20260322000008_rls_policies.sql

-- Helper: get hotel_id from JWT claim
CREATE OR REPLACE FUNCTION auth_hotel_id() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT (auth.jwt() -> 'hotel_id')::uuid
$$;

-- Helper: get role from JWT claim
CREATE OR REPLACE FUNCTION auth_role() RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT auth.jwt() ->> 'role'
$$;

-- Helper: is user active?
CREATE OR REPLACE FUNCTION auth_is_active() RETURNS boolean
LANGUAGE sql STABLE AS $$
  SELECT (auth.jwt() ->> 'is_active')::boolean
$$;

-- =====================
-- HOTELS
-- =====================
ALTER TABLE hotels ENABLE ROW LEVEL SECURITY;

-- Users see only their own hotel
CREATE POLICY "hotels_select_own" ON hotels
  FOR SELECT USING (
    id = auth_hotel_id() OR auth_role() = 'super_admin'
  );

-- Only super_admin can insert/update/delete hotels
CREATE POLICY "hotels_admin_write" ON hotels
  FOR ALL USING (auth_role() = 'super_admin');

-- =====================
-- USERS
-- =====================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_same_hotel" ON users
  FOR SELECT USING (
    hotel_id = auth_hotel_id() OR auth_role() = 'super_admin'
  );

CREATE POLICY "users_insert_manager" ON users
  FOR INSERT WITH CHECK (
    hotel_id = auth_hotel_id() AND
    auth_role() IN ('super_admin','ceo','reception_manager','maintenance_manager',
                    'housekeeping_manager','security_manager')
  );

CREATE POLICY "users_update_manager" ON users
  FOR UPDATE USING (
    hotel_id = auth_hotel_id() AND
    auth_role() IN ('super_admin','ceo','reception_manager','maintenance_manager',
                    'housekeeping_manager','security_manager')
  );

-- Users can update their own profile (language, avatar)
CREATE POLICY "users_update_own_profile" ON users
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid() AND hotel_id = auth_hotel_id());

-- =====================
-- ROOMS
-- =====================
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rooms_select_same_hotel" ON rooms
  FOR SELECT USING (hotel_id = auth_hotel_id() OR auth_role() = 'super_admin');

CREATE POLICY "rooms_write_manager" ON rooms
  FOR INSERT WITH CHECK (
    hotel_id = auth_hotel_id() AND
    auth_role() IN ('super_admin','ceo','reception_manager','maintenance_manager',
                    'housekeeping_manager','security_manager')
  );

CREATE POLICY "rooms_update_manager" ON rooms
  FOR UPDATE USING (
    hotel_id = auth_hotel_id() AND
    auth_role() IN ('super_admin','ceo','reception_manager','maintenance_manager')
  );

-- =====================
-- TICKETS
-- =====================
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tickets_select_same_hotel" ON tickets
  FOR SELECT USING (hotel_id = auth_hotel_id() OR auth_role() = 'super_admin');

-- All active hotel users can open tickets
CREATE POLICY "tickets_insert_active_user" ON tickets
  FOR INSERT WITH CHECK (
    hotel_id = auth_hotel_id() AND auth_is_active() = true
  );

-- claiming and updates: only if same hotel + active
CREATE POLICY "tickets_update_same_hotel" ON tickets
  FOR UPDATE USING (
    hotel_id = auth_hotel_id() AND auth_is_active() = true
  );

-- =====================
-- TICKET_UPDATES (append-only)
-- =====================
ALTER TABLE ticket_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ticket_updates_select_same_hotel" ON ticket_updates
  FOR SELECT USING (hotel_id = auth_hotel_id() OR auth_role() = 'super_admin');

CREATE POLICY "ticket_updates_insert_same_hotel" ON ticket_updates
  FOR INSERT WITH CHECK (hotel_id = auth_hotel_id() AND auth_is_active() = true);

-- NO UPDATE or DELETE policies = append-only enforced

-- =====================
-- TICKET_PHOTOS (append-only)
-- =====================
ALTER TABLE ticket_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ticket_photos_select_same_hotel" ON ticket_photos
  FOR SELECT USING (hotel_id = auth_hotel_id() OR auth_role() = 'super_admin');

CREATE POLICY "ticket_photos_insert_same_hotel" ON ticket_photos
  FOR INSERT WITH CHECK (hotel_id = auth_hotel_id() AND auth_is_active() = true);

-- =====================
-- TICKET_APPROVALS (append-only)
-- =====================
ALTER TABLE ticket_approvals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ticket_approvals_select_same_hotel" ON ticket_approvals
  FOR SELECT USING (hotel_id = auth_hotel_id() OR auth_role() = 'super_admin');

-- Only maintenance_manager and reception_manager insert approvals
CREATE POLICY "ticket_approvals_insert_manager" ON ticket_approvals
  FOR INSERT WITH CHECK (
    hotel_id = auth_hotel_id() AND
    auth_role() IN ('super_admin','maintenance_manager','reception_manager','ceo')
  );

-- UPDATE allowed only for the assigned approver to record their decision
CREATE POLICY "ticket_approvals_update_approver" ON ticket_approvals
  FOR UPDATE USING (
    hotel_id = auth_hotel_id() AND approver_id = auth.uid()
  );
```

- [ ] **Step 2: Apply RLS policies**

```bash
supabase db push
```

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260322000008_rls_policies.sql
git commit -m "feat: add RLS policies for all tables"
```

---

## Task 8: Storage Buckets

**Files:**
- Create: `supabase/migrations/20260322000010_storage.sql`

- [ ] **Step 1: Write storage migration**

```sql
-- supabase/migrations/20260322000010_storage.sql

-- Create per-hotel photo storage (one bucket, path: hotel_id/ticket_id/photo.jpg)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'ticket-photos',
  'ticket-photos',
  false,                          -- private bucket
  10485760,                       -- 10MB per file
  ARRAY['image/jpeg','image/png','image/webp','image/heic']
);

-- RLS on storage: users can only access photos from their hotel
CREATE POLICY "storage_select_same_hotel" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'ticket-photos' AND
    (storage.foldername(name))[1] = auth_hotel_id()::text
  );

CREATE POLICY "storage_insert_same_hotel" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'ticket-photos' AND
    (storage.foldername(name))[1] = auth_hotel_id()::text AND
    auth_is_active() = true
  );
```

- [ ] **Step 2: Apply**

```bash
supabase db push
```

- [ ] **Step 3: Verify bucket in dashboard**

Supabase Dashboard → Storage → confirm `ticket-photos` bucket exists.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260322000010_storage.sql
git commit -m "feat: add ticket-photos storage bucket with RLS"
```

---

## Task 9: Seed Test Data

**Files:**
- Create: `supabase/migrations/20260322000011_seed_test_data.sql`

- [ ] **Step 1: Write seed migration**

```sql
-- supabase/migrations/20260322000011_seed_test_data.sql
-- WARNING: For development only. Remove or gate behind an env check before production.

-- Seed Hotel A
INSERT INTO hotels (id, name, subscription_plan, default_sla_hours, default_language)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'Hotel Alpha', 'pro', 4, 'he'),
  ('00000000-0000-0000-0000-000000000002', 'Hotel Beta',  'basic', 8, 'en');

-- Seed Rooms for Hotel A
INSERT INTO rooms (hotel_id, room_number, floor, room_type)
VALUES
  ('00000000-0000-0000-0000-000000000001', '101', 1, 'standard'),
  ('00000000-0000-0000-0000-000000000001', '102', 1, 'deluxe'),
  ('00000000-0000-0000-0000-000000000001', '201', 2, 'suite');

-- Note: auth.users must be created via Supabase Auth API or dashboard.
-- After creating auth users, insert corresponding rows into public.users.
-- See README for test user credentials.
```

- [ ] **Step 2: Apply**

```bash
supabase db push
```

- [ ] **Step 3: Create test auth users in dashboard**

Supabase Dashboard → Authentication → Users → Invite user:
- `admin@hotelalpha.test` (will become `reception_manager` for Hotel Alpha)
- `tech@hotelalpha.test` (will become `maintenance_tech`)

Then in SQL editor:
```sql
-- Replace UUIDs with actual auth.users IDs from dashboard
INSERT INTO users (id, hotel_id, full_name, email, role)
VALUES
  ('<auth-user-id-1>', '00000000-0000-0000-0000-000000000001', 'Alice Manager', 'admin@hotelalpha.test', 'reception_manager'),
  ('<auth-user-id-2>', '00000000-0000-0000-0000-000000000001', 'Bob Tech', 'tech@hotelalpha.test', 'maintenance_tech');
```

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260322000011_seed_test_data.sql
git commit -m "feat: add development seed data"
```

---

## Task 10: RLS Isolation Tests

**Files:**
- Create: `supabase/tests/rls_isolation.sql`

- [ ] **Step 1: Write isolation tests**

```sql
-- supabase/tests/rls_isolation.sql
-- Run via: supabase test db

BEGIN;
SELECT plan(6);

-- Test: Hotel Alpha user cannot see Hotel Beta rooms
SET LOCAL request.jwt.claims = '{"hotel_id":"00000000-0000-0000-0000-000000000001","role":"receptionist","is_active":true}';
SET LOCAL role = authenticated;

SELECT is(
  (SELECT count(*)::int FROM rooms WHERE hotel_id = '00000000-0000-0000-0000-000000000002'),
  0,
  'Hotel Alpha user sees 0 Hotel Beta rooms'
);

-- Test: Hotel Alpha user sees Hotel Alpha rooms
SELECT ok(
  (SELECT count(*)::int FROM rooms WHERE hotel_id = '00000000-0000-0000-0000-000000000001') > 0,
  'Hotel Alpha user sees Hotel Alpha rooms'
);

-- Test: Inactive user cannot insert ticket
SET LOCAL request.jwt.claims = '{"hotel_id":"00000000-0000-0000-0000-000000000001","role":"receptionist","is_active":false}';

SELECT throws_ok(
  $$INSERT INTO tickets (hotel_id, room_id, opened_by, assigned_dept, title)
    VALUES ('00000000-0000-0000-0000-000000000001',
            (SELECT id FROM rooms LIMIT 1),
            auth.uid(), 'maintenance', 'test')$$,
  'new row violates row-level security policy',
  'Inactive user cannot insert ticket'
);

-- Test: ticket_updates append-only (no delete)
SET LOCAL request.jwt.claims = '{"hotel_id":"00000000-0000-0000-0000-000000000001","role":"maintenance_tech","is_active":true}';

SELECT throws_ok(
  $$DELETE FROM ticket_updates WHERE hotel_id = '00000000-0000-0000-0000-000000000001' LIMIT 1$$,
  'new row violates row-level security policy',
  'ticket_updates is append-only: delete blocked'
);

SELECT finish();
ROLLBACK;
```

- [ ] **Step 2: Run tests**

```bash
supabase test db
```
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add supabase/tests/
git commit -m "test: add RLS isolation SQL tests"
```

---

## Task 11: Excel Export Edge Function

**Files:**
- Create: `supabase/functions/export-excel/index.ts`

- [ ] **Step 1: Write Edge Function**

```typescript
// supabase/functions/export-excel/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  // Verify caller is authenticated
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return new Response('Unauthorized', { status: 401 })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Verify user is a manager
  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace('Bearer ', '')
  )
  if (authError || !user) return new Response('Unauthorized', { status: 401 })

  const { data: profile } = await supabase
    .from('users')
    .select('hotel_id, role')
    .eq('id', user.id)
    .single()

  const managerRoles = ['ceo','reception_manager','maintenance_manager',
                        'housekeeping_manager','security_manager','super_admin']
  if (!profile || !managerRoles.includes(profile.role)) {
    return new Response('Forbidden', { status: 403 })
  }

  const { hotel_id } = profile
  const { from_date, to_date } = await req.json().catch(() => ({}))

  // Fetch tickets for this hotel in date range
  let query = supabase
    .from('tickets')
    .select(`
      id, title, assigned_dept, priority, status, resolution_type,
      sla_deadline, created_at, resolved_at,
      opened_by:users!tickets_opened_by_fkey(full_name),
      claimed_by:users!tickets_claimed_by_fkey(full_name),
      room:rooms(room_number, floor)
    `)
    .eq('hotel_id', hotel_id)
    .order('created_at', { ascending: false })

  if (from_date) query = query.gte('created_at', from_date)
  if (to_date)   query = query.lte('created_at', to_date)

  const { data: tickets, error } = await query
  if (error) return new Response(JSON.stringify({ error }), { status: 500 })

  // Return CSV (Flutter app converts to Excel client-side for small datasets,
  // or downloads CSV directly for large ones)
  const headers = ['ID','Room','Floor','Department','Title','Priority',
                   'Status','Resolution','Opened By','Claimed By',
                   'Created','Resolved','SLA Deadline']
  const rows = (tickets ?? []).map(t => [
    t.id, t.room?.room_number, t.room?.floor, t.assigned_dept, t.title,
    t.priority, t.status, t.resolution_type ?? '',
    t.opened_by?.full_name ?? '', t.claimed_by?.full_name ?? '',
    t.created_at, t.resolved_at ?? '', t.sla_deadline ?? ''
  ])

  const csv = [headers, ...rows].map(r => r.join(',')).join('\n')

  return new Response(csv, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/csv',
      'Content-Disposition': 'attachment; filename=tickets-export.csv'
    }
  })
})
```

- [ ] **Step 2: Deploy Edge Function**

```bash
supabase functions deploy export-excel
```
Expected: Function URL printed. Test it:
```bash
curl -X POST https://<project>.supabase.co/functions/v1/export-excel \
  -H "Authorization: Bearer <manager-jwt>" \
  -H "Content-Type: application/json" \
  -d '{}' --output tickets.csv
```
Expected: CSV file downloaded.

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/
git commit -m "feat: add excel export edge function"
```

---

## Task 12: RPCs Migration

**Files:**
- Create: `supabase/migrations/20260322000012_rpcs.sql`

These RPCs must be in a migration file — not applied manually — so `supabase db reset` can restore them.

- [ ] **Step 1: Write RPCs migration**

```sql
-- supabase/migrations/20260322000012_rpcs.sql

-- Atomic ticket claim: returns true if claimed, false if already taken
CREATE OR REPLACE FUNCTION claim_ticket(p_ticket_id uuid, p_user_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE rows_updated integer;
BEGIN
  UPDATE tickets
  SET claimed_by = p_user_id, status = 'in_progress', updated_at = now()
  WHERE id = p_ticket_id AND claimed_by IS NULL;
  GET DIAGNOSTICS rows_updated = ROW_COUNT;
  IF rows_updated > 0 THEN
    INSERT INTO ticket_updates (hotel_id, ticket_id, user_id, update_type, message)
    SELECT hotel_id, p_ticket_id, p_user_id, 'claim', 'Ticket claimed'
    FROM tickets WHERE id = p_ticket_id;
  END IF;
  RETURN rows_updated > 0;
END;
$$;

-- Create approval rows atomically for room_closed resolution
CREATE OR REPLACE FUNCTION create_approval_request(p_ticket_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_hotel_id uuid; v_round integer;
  v_maint_mgr uuid; v_recep_mgr uuid;
BEGIN
  SELECT hotel_id INTO v_hotel_id FROM tickets WHERE id = p_ticket_id;
  SELECT COALESCE(MAX(submission_round), 0) + 1 INTO v_round
    FROM ticket_approvals WHERE ticket_id = p_ticket_id;
  SELECT id INTO v_maint_mgr FROM users
    WHERE hotel_id = v_hotel_id AND role = 'maintenance_manager' AND is_active = true LIMIT 1;
  SELECT id INTO v_recep_mgr FROM users
    WHERE hotel_id = v_hotel_id AND role = 'reception_manager' AND is_active = true LIMIT 1;
  INSERT INTO ticket_approvals
    (hotel_id, ticket_id, resolution_type, submission_round, approver_id, approver_role)
  VALUES
    (v_hotel_id, p_ticket_id, 'room_closed', v_round, v_maint_mgr, 'maintenance_manager'),
    (v_hotel_id, p_ticket_id, 'room_closed', v_round, v_recep_mgr, 'reception_manager');
END;
$$;

-- Check if both approvals are done and close ticket + room
CREATE OR REPLACE FUNCTION check_and_close_ticket(p_ticket_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_round integer; v_approvals integer; v_room_id uuid;
BEGIN
  SELECT MAX(submission_round) INTO v_round FROM ticket_approvals WHERE ticket_id = p_ticket_id;
  SELECT COUNT(*) INTO v_approvals FROM ticket_approvals
  WHERE ticket_id = p_ticket_id AND submission_round = v_round AND approved = true;
  IF v_approvals = 2 THEN
    UPDATE tickets SET status = 'closed', updated_at = now()
    WHERE id = p_ticket_id RETURNING room_id INTO v_room_id;
    UPDATE rooms SET status = 'closed', status_changed_at = now() WHERE id = v_room_id;
  END IF;
  IF EXISTS (SELECT 1 FROM ticket_approvals
    WHERE ticket_id = p_ticket_id AND submission_round = v_round AND approved = false) THEN
    UPDATE tickets SET status = 'in_progress', updated_at = now() WHERE id = p_ticket_id;
  END IF;
END;
$$;
```

- [ ] **Step 2: Apply**

```bash
supabase db push
```

- [ ] **Step 3: Note on JWT custom claims**

The `custom_jwt_claims` function returns a jsonb object. When configured as a Supabase "Custom Access Token" hook, the returned keys appear in the JWT under `app_metadata`. The Flutter SDK exposes this as `user.appMetadata`. Verify by printing `supabase.auth.currentUser?.appMetadata` after login — it should contain `hotel_id` and `role`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260322000012_rpcs.sql
git commit -m "feat: add RPCs migration (claim_ticket, create_approval_request, check_and_close_ticket)"
```

---

## Task 14: Update PROGRESS.md

- [ ] **Step 1: Mark Plan 1 complete in PROGRESS.md**

Edit `/Users/boazsaada/manegmant resapceon/PROGRESS.md` — update the brainstorming checklist to show backend is complete, and note Plan 2 (Flutter Foundation) is next.

- [ ] **Step 2: Commit**

```bash
git add PROGRESS.md
git commit -m "docs: mark backend plan complete, next: flutter foundation"
```

---

## Verification Checklist

Before moving to Plan 2, confirm:

- [ ] All 8 tables exist in Supabase dashboard
- [ ] RLS is enabled on all tables (green lock icon in Table Editor)
- [ ] JWT hook is configured (Auth → Hooks)
- [ ] `ticket-photos` storage bucket exists and is private
- [ ] `supabase test db` passes all SQL tests
- [ ] Export Edge Function returns CSV for a manager JWT
- [ ] Hotel Alpha user cannot query Hotel Beta data (tested manually in SQL editor with SET LOCAL)
