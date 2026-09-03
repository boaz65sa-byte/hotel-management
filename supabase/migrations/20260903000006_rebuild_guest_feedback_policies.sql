-- supabase/migrations/20260903000005_rebuild_guest_feedback_policies.sql
--
-- 20260903000004 added a guarded (IF NOT EXISTS) permissive INSERT policy
-- to guest_feedback, but live-testing after applying it still shows anon
-- INSERT rejected with 42501. guest_requests got the identical treatment
-- in the same migration and works correctly, so something specific to
-- guest_feedback — most likely a leftover restrictive or misconfigured
-- policy from an earlier out-of-band attempt — is still blocking it, and
-- there's no read-only way to inspect pg_policies available here to
-- confirm what. The table has zero working anon access today regardless
-- (every real guest currently fails to submit feedback), so a clean wipe
-- and rebuild of every policy on this table can't regress anything.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT policyname FROM pg_policies WHERE tablename = 'guest_feedback' LOOP
    EXECUTE format('DROP POLICY %I ON guest_feedback', r.policyname);
  END LOOP;
END $$;

CREATE POLICY "guest_feedback_anyone_can_insert" ON guest_feedback
  FOR INSERT WITH CHECK (true);

CREATE POLICY "guest_feedback_staff_select_same_hotel" ON guest_feedback
  FOR SELECT USING (
    auth_role() = 'super_admin' OR hotel_id = auth_hotel_id()
  );

CREATE POLICY "guest_feedback_staff_update_same_hotel" ON guest_feedback
  FOR UPDATE USING (
    auth_role() = 'super_admin' OR
    (hotel_id = auth_hotel_id() AND auth_is_active() = true)
  );
