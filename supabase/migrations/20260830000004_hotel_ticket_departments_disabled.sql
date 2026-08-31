-- supabase/migrations/20260830000004_hotel_ticket_departments_disabled.sql
--
-- Boaz: not every hotel needs every staff department (e.g. no in-house
-- kitchen, no dedicated security team) — super admin decides which
-- departments are active per hotel. Mirrors the exact opt-out design
-- already used for guest-request tiles (hotel_request_tiles_disabled,
-- 20260828000002): the department catalog itself (key + icon + label)
-- stays static client-side (staff_app/lib/features/tickets/presentation/
-- new_ticket_screen.dart _deptMeta) — this table only stores which of
-- those fixed keys are HIDDEN for a hotel. Absence of a row = department
-- active (existing hotels need zero backfill and keep today's
-- "all departments active" behavior).

CREATE TABLE hotel_ticket_departments_disabled (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id   uuid NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
  department dept_name NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (hotel_id, department)
);

COMMENT ON TABLE hotel_ticket_departments_disabled IS 'Opt-out per hotel: presence of a (hotel_id, department) row hides that department from staff ticket routing/creation. Department catalog itself is static client-side, see new_ticket_screen.dart _deptMeta.';

ALTER TABLE hotel_ticket_departments_disabled ENABLE ROW LEVEL SECURITY;

-- Staff app reads this once authenticated (unlike the guest-tile table,
-- staff always have a session), so scope to their own hotel like the
-- rest of the schema (tickets_select_same_hotel, etc.).
CREATE POLICY "hotel_ticket_departments_disabled_read" ON hotel_ticket_departments_disabled
  FOR SELECT USING (hotel_id = auth_hotel_id() OR auth_role() = 'super_admin');

-- Only the super admin (app owner) manages this — same restriction as
-- hotel_request_tiles_disabled and hotels_admin_write.
CREATE POLICY "hotel_ticket_departments_disabled_super_admin_manage" ON hotel_ticket_departments_disabled
  FOR ALL USING (auth_role() = 'super_admin');
