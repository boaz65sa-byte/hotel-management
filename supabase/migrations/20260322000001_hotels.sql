-- supabase/migrations/20260322000001_hotels.sql

CREATE TABLE hotels (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                text NOT NULL,
  logo_url            text,
  theme_colors        jsonb DEFAULT '{"primary":"#1976D2","secondary":"#424242","accent":"#FF6F00"}'::jsonb,
  subscription_plan   text NOT NULL DEFAULT 'basic' CHECK (subscription_plan IN ('basic','pro','enterprise')),
  default_sla_hours   integer NOT NULL DEFAULT 4 CHECK (default_sla_hours > 0),
  session_timeout_min integer NOT NULL DEFAULT 480 CHECK (session_timeout_min > 0),
  storage_quota_gb    integer NOT NULL DEFAULT 10,
  is_active           boolean NOT NULL DEFAULT true,
  default_language    text NOT NULL DEFAULT 'he' CHECK (default_language IN ('he','en','ar')),
  created_at          timestamptz NOT NULL DEFAULT now()
);

-- Storage quota by plan (enforced at app layer, documented here)
-- basic: 10 GB, pro: 50 GB, enterprise: 200 GB

COMMENT ON TABLE hotels IS 'One row per tenant hotel. hotel_id is the multi-tenant isolation key.';
