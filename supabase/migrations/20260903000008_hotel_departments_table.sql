-- supabase/migrations/20260903000008_hotel_departments_table.sql
--
-- Per-hotel catalog of entirely NEW staff departments (with their own
-- manager/staff — e.g. "Spa"), on top of the fixed 5 (reception/
-- maintenance/housekeeping/security/kitchen) that live in the dept_name
-- enum. Distinct from two other tables that sound similar:
--   - hotel_ticket_departments_disabled: on/off toggle for the 5 FIXED
--     departments, no new names possible.
--   - hotel_request_categories: the GUEST-facing request-category catalog
--     (what a guest picks in "new request") — unrelated to staff accounts.
-- This table is the staff side: a super admin can stand up a whole new
-- department here, then invite a manager/staff member into it (see
-- 20260903000009/10 for the role enum values and users.department_id
-- wiring that make that possible).

CREATE TABLE hotel_departments (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id   uuid NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
  key        text NOT NULL,
  label      text NOT NULL,
  icon       text NOT NULL DEFAULT '🏷️',
  is_active  boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (hotel_id, key)
);

COMMENT ON TABLE hotel_departments IS
  'Per-hotel catalog of custom staff departments beyond the fixed dept_name enum set. A user with role custom_dept_manager/custom_dept_staff belongs to one row here via users.department_id.';

ALTER TABLE hotel_departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hotel_departments_read_same_hotel" ON hotel_departments
  FOR SELECT USING (hotel_id = auth_hotel_id() OR auth_role() = 'super_admin');

CREATE POLICY "hotel_departments_super_admin_manage" ON hotel_departments
  FOR ALL USING (auth_role() = 'super_admin');
