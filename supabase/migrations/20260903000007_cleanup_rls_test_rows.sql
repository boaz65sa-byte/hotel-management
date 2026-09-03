-- Cleanup: remove the test rows created while live-verifying
-- 20260903000004's RLS fix (anon key has no DELETE policy on either
-- table, so this runs with the migration runner's elevated privileges).
DELETE FROM guest_requests WHERE room_number = 'TEST-999' AND guest_name = 'QA Test';
DELETE FROM guest_feedback WHERE room_number = 'TEST-999' AND guest_name = 'QA Test';
