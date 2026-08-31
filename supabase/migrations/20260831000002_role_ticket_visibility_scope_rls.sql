-- supabase/migrations/20260831000002_role_ticket_visibility_scope_rls.sql
--
-- Wires hotel_role_ticket_scope into the actual tickets RLS policies.
-- Default (no override row, or scope='all_departments') behaves exactly
-- like today: any active user in the hotel sees every ticket. Only when a
-- hotel explicitly sets a role to 'own_department_only' does that role's
-- visibility narrow to their home department plus tickets they personally
-- touched.

DROP POLICY IF EXISTS "tickets_select_same_hotel" ON tickets;
CREATE POLICY "tickets_select_same_hotel" ON tickets
  FOR SELECT USING (
    auth_role() = 'super_admin' OR (
      hotel_id = auth_hotel_id() AND (
        NOT auth_ticket_scope_restricted()
        OR assigned_dept::text = auth_role_department()
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
        OR opened_by = auth.uid()
        OR claimed_by = auth.uid()
        OR assigned_to = auth.uid()
      )
    )
  );
