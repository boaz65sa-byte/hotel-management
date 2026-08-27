-- supabase/migrations/20260827000002_hotel_feature_toggles.sql
--
-- Per-hotel feature toggles: which optional modules are active for a given
-- hotel (e.g. amenities ordering, the guided guest menu). Defaults to all
-- off — existing hotels keep exactly today's behavior until a super admin
-- opts them in.

ALTER TABLE hotels ADD COLUMN IF NOT EXISTS enabled_features jsonb NOT NULL
  DEFAULT '{"amenities_ordering": false, "guided_menu": false}'::jsonb;

COMMENT ON COLUMN hotels.enabled_features IS
  'Per-hotel module toggles, e.g. {"amenities_ordering": true, "guided_menu": true}. Read by the admin panel (full row, via existing RLS) and by the Guest PWA (via get_hotel_branding, since anon never sees the raw hotels row).';

-- Extend the Guest PWA's public branding RPC to also return this — it's the
-- only anon-safe channel into the hotels table (see that function's own
-- comment for why this is an RPC and not a permissive SELECT policy).
-- Must DROP first: Postgres won't let CREATE OR REPLACE change a RETURNS
-- TABLE function's output columns.
DROP FUNCTION IF EXISTS public.get_hotel_branding(uuid);

CREATE FUNCTION public.get_hotel_branding(p_hotel_id uuid)
RETURNS TABLE (
  name             text,
  logo_url         text,
  enabled_features jsonb
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT h.name, h.logo_url, h.enabled_features
    FROM public.hotels h
   WHERE h.id = p_hotel_id;
$$;

REVOKE ALL ON FUNCTION public.get_hotel_branding(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_hotel_branding(uuid) TO anon, authenticated;
