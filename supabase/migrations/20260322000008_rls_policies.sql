-- supabase/migrations/20260322000008_rls_policies.sql

-- Helper: get hotel_id from JWT claim
CREATE OR REPLACE FUNCTION auth_hotel_id() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT (auth.jwt() ->> 'hotel_id')::uuid
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

CREATE POLICY "hotels_select_own" ON hotels
  FOR SELECT USING (
    id = auth_hotel_id() OR auth_role() = 'super_admin'
  );

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

CREATE POLICY "tickets_insert_active_user" ON tickets
  FOR INSERT WITH CHECK (
    hotel_id = auth_hotel_id() AND auth_is_active() = true
  );

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

CREATE POLICY "ticket_approvals_insert_manager" ON ticket_approvals
  FOR INSERT WITH CHECK (
    hotel_id = auth_hotel_id() AND
    auth_role() IN ('super_admin','maintenance_manager','reception_manager','ceo')
  );

CREATE POLICY "ticket_approvals_update_approver" ON ticket_approvals
  FOR UPDATE USING (
    hotel_id = auth_hotel_id() AND approver_id = auth.uid()
  );
