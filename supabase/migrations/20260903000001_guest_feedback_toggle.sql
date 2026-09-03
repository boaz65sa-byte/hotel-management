-- supabase/migrations/20260903000001_guest_feedback_toggle.sql
--
-- Per-hotel on/off switch for the guest feedback/survey feature. Unlike
-- `enabled_features` (opt-in, defaults off), this defaults to true — guest
-- feedback already works today for every hotel, so existing hotels must
-- keep exactly today's behavior until a super admin explicitly turns it
-- off for one of them. A plain boolean column (not a new opt-out table)
-- since this is a single per-hotel flag, not a keyed catalog like
-- departments or request tiles.

ALTER TABLE hotels ADD COLUMN IF NOT EXISTS guest_feedback_enabled boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN hotels.guest_feedback_enabled IS
  'Whether the guest feedback/survey banner is offered to guests of this hotel. Defaults true. Read by the admin panel (full row, via existing RLS) and by the Guest PWA (via get_hotel_branding, since anon never sees the raw hotels row).';

-- Extend the Guest PWA's public branding RPC to also return this — it's the
-- only anon-safe channel into the hotels table (see that function's own
-- comment for why this is an RPC and not a permissive SELECT policy).
-- Must DROP first: Postgres won't let CREATE OR REPLACE change a RETURNS
-- TABLE function's output columns.
DROP FUNCTION IF EXISTS public.get_hotel_branding(uuid);

CREATE FUNCTION public.get_hotel_branding(p_hotel_id uuid)
RETURNS TABLE (
  name                    text,
  logo_url                text,
  enabled_features        jsonb,
  guest_feedback_enabled  boolean
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT h.name, h.logo_url, h.enabled_features, h.guest_feedback_enabled
    FROM public.hotels h
   WHERE h.id = p_hotel_id;
$$;

REVOKE ALL ON FUNCTION public.get_hotel_branding(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_hotel_branding(uuid) TO anon, authenticated;
