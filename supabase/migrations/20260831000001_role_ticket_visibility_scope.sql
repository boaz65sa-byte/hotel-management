-- supabase/migrations/20260831000001_role_ticket_visibility_scope.sql
--
-- Boaz: today, any active staff member can see every department's tickets
-- within their hotel (tickets_select_same_hotel only checks hotel_id, no
-- department predicate) -- confirmed as today's actual behavior, and kept
-- as the default here (nothing changes for hotels that don't opt in).
-- This migration adds a per-hotel, per-role SWITCH so a hotel can instead
-- restrict a given department-manager role to see only their own
-- department's tickets (plus anything they personally opened/claimed/were
-- assigned, regardless of department, so their own work never disappears).
--
-- Absence of a row = current behavior (all departments visible) -- zero
-- backfill needed, nothing breaks for existing hotels.

CREATE TABLE hotel_role_ticket_scope (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id   uuid NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
  role       user_role NOT NULL,
  scope      text NOT NULL DEFAULT 'all_departments'
             CHECK (scope IN ('all_departments', 'own_department_only')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (hotel_id, role)
);

COMMENT ON TABLE hotel_role_ticket_scope IS 'Per-hotel, per-role override: scope=own_department_only restricts that role to tickets in their home department (see auth_role_department()) plus tickets they personally opened/claimed/were assigned. Absence of a row (or scope=all_departments) keeps the original hotel-wide visibility.';

ALTER TABLE hotel_role_ticket_scope ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hotel_role_ticket_scope_read" ON hotel_role_ticket_scope
  FOR SELECT USING (hotel_id = auth_hotel_id() OR auth_role() = 'super_admin');

CREATE POLICY "hotel_role_ticket_scope_super_admin_manage" ON hotel_role_ticket_scope
  FOR ALL USING (auth_role() = 'super_admin');

-- Maps a role to the single department it "belongs to", for the roles this
-- toggle is meaningful for. NULL for hotel-wide roles (ceo, software_manager,
-- hotel_admin, super_admin) and reception (reception has no separate
-- assigned_dept restriction need today) -- NULL means "this role should
-- never actually be set to own_department_only" but if it somehow is, they
-- fall back to only their personally-opened/claimed/assigned tickets rather
-- than an error.
CREATE OR REPLACE FUNCTION auth_role_department() RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT CASE auth_role()
    WHEN 'reception_manager'    THEN 'reception'
    WHEN 'deputy_reception'     THEN 'reception'
    WHEN 'receptionist'         THEN 'reception'
    WHEN 'maintenance_manager'  THEN 'maintenance'
    WHEN 'maintenance_tech'     THEN 'maintenance'
    WHEN 'repairman'            THEN 'maintenance'
    WHEN 'housekeeping_manager' THEN 'housekeeping'
    WHEN 'housekeeping'         THEN 'housekeeping'
    WHEN 'security_manager'     THEN 'security'
    WHEN 'security_guard'       THEN 'security'
    WHEN 'kitchen_manager'      THEN 'kitchen'
    WHEN 'kitchen_staff'        THEN 'kitchen'
    ELSE NULL
  END
$$;

-- True if the caller's own role is currently set to own_department_only for
-- their hotel.
CREATE OR REPLACE FUNCTION auth_ticket_scope_restricted() RETURNS boolean
LANGUAGE sql STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM hotel_role_ticket_scope
    WHERE hotel_id = auth_hotel_id()
      AND role = auth_role()::user_role
      AND scope = 'own_department_only'
  )
$$;
