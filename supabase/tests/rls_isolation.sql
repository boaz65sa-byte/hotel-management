-- supabase/tests/rls_isolation.sql
-- Run via: supabase test db

BEGIN;
SELECT plan(4);

-- Test 1: Hotel Alpha user cannot see Hotel Beta rooms
SET LOCAL request.jwt.claims = '{"hotel_id":"00000000-0000-0000-0000-000000000001","role":"receptionist","is_active":true}';
SET LOCAL role = authenticated;

SELECT is(
  (SELECT count(*)::int FROM rooms WHERE hotel_id = '00000000-0000-0000-0000-000000000002'),
  0,
  'Hotel Alpha user sees 0 Hotel Beta rooms'
);

-- Test 2: Hotel Alpha user sees Hotel Alpha rooms
SELECT ok(
  (SELECT count(*)::int FROM rooms WHERE hotel_id = '00000000-0000-0000-0000-000000000001') > 0,
  'Hotel Alpha user sees Hotel Alpha rooms'
);

-- Test 3: ticket_updates append-only (no delete)
SET LOCAL request.jwt.claims = '{"hotel_id":"00000000-0000-0000-0000-000000000001","role":"maintenance_tech","is_active":true}';

SELECT throws_ok(
  $$DELETE FROM ticket_updates WHERE hotel_id = '00000000-0000-0000-0000-000000000001'$$,
  42501,
  NULL,
  'ticket_updates is append-only: delete blocked by RLS'
);

-- Test 4: ticket_photos append-only (no delete)
SELECT throws_ok(
  $$DELETE FROM ticket_photos WHERE hotel_id = '00000000-0000-0000-0000-000000000001'$$,
  42501,
  NULL,
  'ticket_photos is append-only: delete blocked by RLS'
);

SELECT finish();
ROLLBACK;
