-- ============================================================
-- CREATE TEST USERS WITH PROPER AUTH IDENTITIES
-- הרץ ב: Supabase Dashboard → SQL Editor
-- ============================================================

-- נקה משתמשי טסט קיימים אם יש
DELETE FROM auth.identities WHERE user_id IN (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'bbbbbbbb-0000-0000-0000-000000000002',
  'bbbbbbbb-0000-0000-0000-000000000003',
  'bbbbbbbb-0000-0000-0000-000000000004',
  'bbbbbbbb-0000-0000-0000-000000000005'
);
DELETE FROM auth.users WHERE id IN (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'bbbbbbbb-0000-0000-0000-000000000002',
  'bbbbbbbb-0000-0000-0000-000000000003',
  'bbbbbbbb-0000-0000-0000-000000000004',
  'bbbbbbbb-0000-0000-0000-000000000005'
);

-- צור מחדש עם identities תקינות

-- Super Admin
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'superadmin@hotel.com',
  crypt('Admin1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Super Admin"}',
  now(), now(), 'authenticated', 'authenticated'
);
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'bbbbbbbb-0000-0000-0000-000000000001',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000001","email":"superadmin@hotel.com"}',
  'email',
  'superadmin@hotel.com',
  now(), now(), now()
);

-- מנהל קבלה
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000000',
  'manager@hotel.com',
  crypt('Manager1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"ישראל ישראלי"}',
  now(), now(), 'authenticated', 'authenticated'
);
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000002',
  'bbbbbbbb-0000-0000-0000-000000000002',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000002","email":"manager@hotel.com"}',
  'email',
  'manager@hotel.com',
  now(), now(), now()
);

-- פקיד קבלה
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000000',
  'reception@hotel.com',
  crypt('Reception1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"דנה כהן"}',
  now(), now(), 'authenticated', 'authenticated'
);
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000003',
  'bbbbbbbb-0000-0000-0000-000000000003',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000003","email":"reception@hotel.com"}',
  'email',
  'reception@hotel.com',
  now(), now(), now()
);

-- טכנאי אחזקה
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000000',
  'tech@hotel.com',
  crypt('Tech1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"משה לוי"}',
  now(), now(), 'authenticated', 'authenticated'
);
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000004',
  'bbbbbbbb-0000-0000-0000-000000000004',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000004","email":"tech@hotel.com"}',
  'email',
  'tech@hotel.com',
  now(), now(), now()
);

-- מנהל אחזקה
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, aud, role)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000005',
  '00000000-0000-0000-0000-000000000000',
  'maintenance@hotel.com',
  crypt('Maintenance1234!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"אבי גבאי"}',
  now(), now(), 'authenticated', 'authenticated'
);
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000005',
  'bbbbbbbb-0000-0000-0000-000000000005',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000005","email":"maintenance@hotel.com"}',
  'email',
  'maintenance@hotel.com',
  now(), now(), now()
);

-- בדיקה
SELECT u.email, p.role, p.full_name
FROM auth.users u
JOIN public.users p ON p.id = u.id
WHERE u.email LIKE '%hotel.com'
ORDER BY p.role;
