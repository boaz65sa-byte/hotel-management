-- supabase/migrations/20260322000011_seed_test_data.sql
-- WARNING: For development only. Remove or gate behind an env check before production.

-- Seed Hotel A
INSERT INTO hotels (id, name, subscription_plan, default_sla_hours, default_language)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'Hotel Alpha', 'pro', 4, 'he'),
  ('00000000-0000-0000-0000-000000000002', 'Hotel Beta',  'basic', 8, 'en')
ON CONFLICT (id) DO NOTHING;

-- Seed Rooms for Hotel A
INSERT INTO rooms (hotel_id, room_number, floor, room_type)
VALUES
  ('00000000-0000-0000-0000-000000000001', '101', 1, 'standard'),
  ('00000000-0000-0000-0000-000000000001', '102', 1, 'deluxe'),
  ('00000000-0000-0000-0000-000000000001', '201', 2, 'suite')
ON CONFLICT (hotel_id, room_number) DO NOTHING;

-- Note: auth.users must be created via Supabase Auth API or dashboard.
-- After creating auth users, insert corresponding rows into public.users.
-- See README for test user credentials.
