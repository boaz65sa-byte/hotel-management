-- ============================================================
-- HOTEL APP - INITIAL SETUP SCRIPT
-- הרץ ב: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. צור מלון ראשון ────────────────────────────────────────
INSERT INTO hotels (id, name, subscription_plan, default_sla_hours, default_language, is_active)
VALUES (
  'aaaaaaaa-0000-0000-0000-000000000001',
  'מלון דן תל אביב',
  'pro',
  4,
  'he',
  true
)
ON CONFLICT (id) DO NOTHING;

-- ── 2. צור משתמשי Auth ───────────────────────────────────────
-- Super Admin
INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  aud, role
) VALUES (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'superadmin@hotel.com',
  crypt('Admin1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Super Admin"}',
  now(), now(), 'authenticated', 'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- מנהל קבלה
INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  aud, role
) VALUES (
  'bbbbbbbb-0000-0000-0000-000000000002',
  'manager@hotel.com',
  crypt('Manager1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"ישראל ישראלי"}',
  now(), now(), 'authenticated', 'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- פקיד קבלה
INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  aud, role
) VALUES (
  'bbbbbbbb-0000-0000-0000-000000000003',
  'reception@hotel.com',
  crypt('Reception1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"דנה כהן"}',
  now(), now(), 'authenticated', 'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- טכנאי אחזקה
INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  aud, role
) VALUES (
  'bbbbbbbb-0000-0000-0000-000000000004',
  'tech@hotel.com',
  crypt('Tech1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"משה לוי"}',
  now(), now(), 'authenticated', 'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- מנהל אחזקה
INSERT INTO auth.users (
  id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  aud, role
) VALUES (
  'bbbbbbbb-0000-0000-0000-000000000005',
  'maintenance@hotel.com',
  crypt('Maintenance1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"אבי גבאי"}',
  now(), now(), 'authenticated', 'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- ── 3. צור רשומות users (פרופיל) ────────────────────────────
INSERT INTO users (id, hotel_id, full_name, email, role, is_active, is_primary_contact)
VALUES
  -- Super Admin — ללא hotel_id
  ('bbbbbbbb-0000-0000-0000-000000000001', NULL,
   'Super Admin', 'superadmin@hotel.com', 'super_admin', true, false),

  -- מנהל קבלה
  ('bbbbbbbb-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000001',
   'ישראל ישראלי', 'manager@hotel.com', 'reception_manager', true, true),

  -- פקיד קבלה
  ('bbbbbbbb-0000-0000-0000-000000000003', 'aaaaaaaa-0000-0000-0000-000000000001',
   'דנה כהן', 'reception@hotel.com', 'receptionist', true, false),

  -- טכנאי אחזקה
  ('bbbbbbbb-0000-0000-0000-000000000004', 'aaaaaaaa-0000-0000-0000-000000000001',
   'משה לוי', 'tech@hotel.com', 'maintenance_tech', true, false),

  -- מנהל אחזקה
  ('bbbbbbbb-0000-0000-0000-000000000005', 'aaaaaaaa-0000-0000-0000-000000000001',
   'אבי גבאי', 'maintenance@hotel.com', 'maintenance_manager', true, false)
ON CONFLICT (id) DO NOTHING;

-- ── 4. צור חדרים לדוגמה ──────────────────────────────────────
INSERT INTO rooms (id, hotel_id, room_number, floor, room_type, status)
VALUES
  (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001', '101', 1, 'standard',  'available'),
  (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001', '102', 1, 'standard',  'available'),
  (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001', '103', 1, 'suite',     'on_hold'),
  (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001', '201', 2, 'standard',  'available'),
  (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001', '202', 2, 'deluxe',    'available'),
  (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001', '203', 2, 'standard',  'closed'),
  (gen_random_uuid(), 'aaaaaaaa-0000-0000-0000-000000000001', '301', 3, 'penthouse', 'available')
ON CONFLICT DO NOTHING;

-- ── 5. בדיקה ─────────────────────────────────────────────────
SELECT 'hotels' AS tbl, count(*) FROM hotels
UNION ALL
SELECT 'users',         count(*) FROM users
UNION ALL
SELECT 'rooms',         count(*) FROM rooms;
