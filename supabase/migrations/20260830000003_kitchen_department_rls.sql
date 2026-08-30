-- supabase/migrations/20260830000003_kitchen_department_rls.sql

-- Let kitchen_manager create/edit their own department's staff accounts,
-- matching the existing per-department manager grant (reception/maintenance/
-- housekeeping/security) in 20260322000008_rls_policies.sql.

DROP POLICY IF EXISTS "users_insert_manager" ON users;
CREATE POLICY "users_insert_manager" ON users
  FOR INSERT WITH CHECK (
    hotel_id = auth_hotel_id() AND
    auth_role() IN ('super_admin','ceo','reception_manager','maintenance_manager',
                    'housekeeping_manager','security_manager','kitchen_manager')
  );

DROP POLICY IF EXISTS "users_update_manager" ON users;
CREATE POLICY "users_update_manager" ON users
  FOR UPDATE USING (
    hotel_id = auth_hotel_id() AND
    auth_role() IN ('super_admin','ceo','reception_manager','maintenance_manager',
                    'housekeeping_manager','security_manager','kitchen_manager')
  );

-- Note: tickets_select_same_hotel / tickets_update_same_hotel are already
-- hotel-scoped only (not per-role) -- kitchen tickets need no RLS change there.
