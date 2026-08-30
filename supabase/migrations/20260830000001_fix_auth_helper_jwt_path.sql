-- supabase/migrations/20260830000001_fix_auth_helper_jwt_path.sql
--
-- Root-cause fix for the "maintenance_manager Requests tab spins forever"
-- report (which turned out to affect every non-super-admin staff member,
-- on every screen, not just that one tab or role).
--
-- History: the tracked custom_jwt_claims migrations (20260322000009,
-- 20260324000001, 20260325000001) all put hotel_id/role/is_active at the
-- TOP LEVEL of the JWT claims, matching auth_hotel_id()/auth_role()/
-- auth_is_active() below, which read auth.jwt() ->> 'hotel_id' etc.
--
-- At some point during the 2026-08-27 security/QA session, custom_jwt_claims
-- was hotfixed out-of-band (never captured in a tracked migration — same
-- gap as the guest_requests baseline) to nest those claims under
-- `app_metadata` instead, most likely to fix jsonb_strip_nulls stripping a
-- NULL hotel_id for super_admin. That fixed the JWT's own shape, but nobody
-- updated these three helper functions to match, so every RLS policy built
-- on them silently started evaluating auth_hotel_id() as NULL and
-- auth_role() as the string "authenticated" (Supabase's own reserved
-- top-level role claim, not the app's custom role) for every non-service-role
-- request. Confirmed live: `select id from users where id = <own id>`
-- returns 0 rows for a logged-in staff member querying their own row.
--
-- This went unnoticed because:
--   - The admin panel reads through a service_role client (bypasses RLS).
--   - guest_requests' own policies were written inline with the correct
--     nested path already, so that table happened to keep working.
--   - Most other tables (hotels, users, rooms, tickets, ticket_updates,
--     ticket_photos, ticket_approvals, hotel_licenses, hotel_amenities,
--     amenity_orders, hotel_request_tiles_disabled) route through these
--     three shared helpers and were quietly broken for direct client access
--     since the hotfix — surfacing first as an uncaught PGRST116 (406) from
--     lib/core/auth/session_timeout.dart's `.single()` call on `users`,
--     fired on every staff login, misdiagnosed as tied to the Requests tab
--     purely because of timing coincidence.
--
-- Fix: read the same app_metadata-nested path the live hook actually
-- produces, matching how guest_requests' own policies already do it.

CREATE OR REPLACE FUNCTION auth_hotel_id() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT ((auth.jwt() -> 'app_metadata') ->> 'hotel_id')::uuid
$$;

CREATE OR REPLACE FUNCTION auth_role() RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT (auth.jwt() -> 'app_metadata') ->> 'role'
$$;

CREATE OR REPLACE FUNCTION auth_is_active() RETURNS boolean
LANGUAGE sql STABLE AS $$
  SELECT ((auth.jwt() -> 'app_metadata') ->> 'is_active')::boolean
$$;

COMMENT ON FUNCTION auth_hotel_id() IS 'Reads hotel_id from JWT app_metadata (matches the live custom_jwt_claims hook, which nests claims there — see migration 20260830000001 for the regression history).';
COMMENT ON FUNCTION auth_role() IS 'Reads the app role from JWT app_metadata. Do not confuse with the JWT''s own top-level "role" claim, which is Supabase''s reserved value ("authenticated") and unrelated to this.';
COMMENT ON FUNCTION auth_is_active() IS 'Reads is_active from JWT app_metadata (matches the live custom_jwt_claims hook — see migration 20260830000001 for the regression history).';
