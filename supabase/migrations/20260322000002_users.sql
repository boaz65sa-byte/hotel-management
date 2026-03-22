-- supabase/migrations/20260322000002_users.sql

CREATE TYPE user_role AS ENUM (
  'super_admin',
  'ceo',
  'reception_manager',
  'maintenance_manager',
  'housekeeping_manager',
  'security_manager',
  'deputy_reception',
  'receptionist',
  'security_guard',
  'maintenance_tech',
  'repairman'
);

CREATE TABLE users (
  id                  uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  hotel_id            uuid REFERENCES hotels(id),  -- NULL for super_admin
  full_name           text NOT NULL,
  email               text NOT NULL,
  role                user_role NOT NULL,
  avatar_url          text,
  language            text CHECK (language IN ('he','en','ar')),  -- NULL = inherit hotel default
  is_active           boolean NOT NULL DEFAULT true,
  is_primary_contact  boolean NOT NULL DEFAULT false,
  created_at          timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT super_admin_no_hotel CHECK (
    (role = 'super_admin' AND hotel_id IS NULL) OR
    (role != 'super_admin' AND hotel_id IS NOT NULL)
  )
);

-- Only one primary contact per hotel
CREATE UNIQUE INDEX one_primary_per_hotel
  ON users (hotel_id)
  WHERE is_primary_contact = true;

COMMENT ON TABLE users IS 'Public profile for each auth user. hotel_id=NULL for super_admin.';
COMMENT ON COLUMN users.language IS 'NULL means inherit from hotels.default_language';
COMMENT ON COLUMN users.is_primary_contact IS 'One per hotel. This user is the hotel representative for support and billing.';
