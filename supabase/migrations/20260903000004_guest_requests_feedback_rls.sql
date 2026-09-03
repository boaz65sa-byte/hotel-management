-- supabase/migrations/20260903000004_guest_requests_feedback_rls.sql
--
-- guest_requests and guest_feedback were both created out-of-band (see
-- 20260827000001_baseline_guest_requests.sql's own comment) and — unlike
-- every other table in this app — never got RLS policies in any tracked
-- migration. Live-verified via a real anon-key INSERT against production:
-- both tables reject every anon write with 42501 (insufficient_privilege),
-- meaning a real guest cannot currently submit a request or feedback at
-- all. This adds the missing policies, mirroring the exact same
-- anon-can-insert / hotel-scoped-staff-access shape already used for
-- amenity_orders (20260827000003_amenities_ordering.sql) and tickets
-- (20260322000008_rls_policies.sql).
--
-- Guarded with pg_policies existence checks (not DROP+CREATE) since we
-- can't be certain nothing already exists out-of-band on the live table —
-- safe to run whether or not that's the case.

ALTER TABLE guest_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_feedback ENABLE ROW LEVEL SECURITY;

-- guest_requests
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'guest_requests' AND policyname = 'guest_requests_anyone_can_insert'
  ) THEN
    CREATE POLICY "guest_requests_anyone_can_insert" ON guest_requests
      FOR INSERT WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'guest_requests' AND policyname = 'guest_requests_anon_read_same_hotel'
  ) THEN
    CREATE POLICY "guest_requests_anon_read_same_hotel" ON guest_requests
      FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'guest_requests' AND policyname = 'guest_requests_staff_update_same_hotel'
  ) THEN
    CREATE POLICY "guest_requests_staff_update_same_hotel" ON guest_requests
      FOR UPDATE USING (
        auth_role() = 'super_admin' OR
        (hotel_id = auth_hotel_id() AND auth_is_active() = true)
      );
  END IF;
END $$;

-- guest_feedback
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'guest_feedback' AND policyname = 'guest_feedback_anyone_can_insert'
  ) THEN
    CREATE POLICY "guest_feedback_anyone_can_insert" ON guest_feedback
      FOR INSERT WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'guest_feedback' AND policyname = 'guest_feedback_staff_select_same_hotel'
  ) THEN
    CREATE POLICY "guest_feedback_staff_select_same_hotel" ON guest_feedback
      FOR SELECT USING (
        auth_role() = 'super_admin' OR hotel_id = auth_hotel_id()
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'guest_feedback' AND policyname = 'guest_feedback_staff_update_same_hotel'
  ) THEN
    CREATE POLICY "guest_feedback_staff_update_same_hotel" ON guest_feedback
      FOR UPDATE USING (
        auth_role() = 'super_admin' OR
        (hotel_id = auth_hotel_id() AND auth_is_active() = true)
      );
  END IF;
END $$;
