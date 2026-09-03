-- supabase/migrations/20260903000010_custom_departments_wiring.sql
--
-- Wires up custom_dept_manager/custom_dept_staff (added in the previous
-- migration) so they actually work: which department a user belongs to,
-- which department a ticket is routed to, and ticket-visibility RLS so
-- those users see their own department's tickets.

-- Which hotel_departments row this user belongs to. Only meaningful when
-- role is custom_dept_manager/custom_dept_staff — NULL for every other role.
ALTER TABLE users ADD COLUMN IF NOT EXISTS department_id uuid REFERENCES hotel_departments(id);

-- A ticket now routes to EITHER the fixed dept_name enum OR a custom
-- department, never both/neither.
ALTER TABLE tickets ALTER COLUMN assigned_dept DROP NOT NULL;
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS custom_department_id uuid REFERENCES hotel_departments(id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'tickets_dept_xor_custom'
  ) THEN
    ALTER TABLE tickets ADD CONSTRAINT tickets_dept_xor_custom CHECK (
      (assigned_dept IS NOT NULL AND custom_department_id IS NULL) OR
      (assigned_dept IS NULL AND custom_department_id IS NOT NULL)
    );
  END IF;
END $$;

-- Current user's department_id. Unlike auth_hotel_id()/auth_role()/
-- auth_is_active(), this can't be read from the JWT: those claims come
-- from a custom_jwt_claims Auth Hook that was hotfixed out-of-band and
-- isn't in any tracked migration (see 20260830000001's own history notes)
-- — too fragile/opaque to extend blind. A direct users lookup is safe
-- here: users_select_same_hotel already lets any hotel member read any
-- user row in their own hotel, so no SECURITY DEFINER is needed.
CREATE OR REPLACE FUNCTION auth_department_id() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT department_id FROM users WHERE id = auth.uid()
$$;

-- Extend ticket visibility so custom-department staff/managers see their
-- own department's tickets under the same rules the 5 fixed departments
-- already get (see 20260831000001/2_role_ticket_visibility_scope*.sql).
DROP POLICY IF EXISTS "tickets_select_same_hotel" ON tickets;
CREATE POLICY "tickets_select_same_hotel" ON tickets
  FOR SELECT USING (
    auth_role() = 'super_admin' OR (
      hotel_id = auth_hotel_id() AND (
        NOT auth_ticket_scope_restricted()
        OR assigned_dept::text = auth_role_department()
        OR (custom_department_id IS NOT NULL AND custom_department_id = auth_department_id())
        OR opened_by = auth.uid()
        OR claimed_by = auth.uid()
        OR assigned_to = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "tickets_update_same_hotel" ON tickets;
CREATE POLICY "tickets_update_same_hotel" ON tickets
  FOR UPDATE USING (
    auth_role() = 'super_admin' OR (
      hotel_id = auth_hotel_id() AND auth_is_active() = true AND (
        NOT auth_ticket_scope_restricted()
        OR assigned_dept::text = auth_role_department()
        OR (custom_department_id IS NOT NULL AND custom_department_id = auth_department_id())
        OR opened_by = auth.uid()
        OR claimed_by = auth.uid()
        OR assigned_to = auth.uid()
      )
    )
  );
