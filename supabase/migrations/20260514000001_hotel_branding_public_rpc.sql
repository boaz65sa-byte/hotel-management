-- Allow the unauthenticated Guest PWA to read just the public-facing branding
-- (hotel name + logo) without exposing the full hotels row through RLS.
--
-- Why an RPC and not a permissive SELECT policy?
--   * Column-level scoping: the function returns ONLY (name, logo_url).
--     subscription_plan, contact info, theme, default_sla_hours, etc. stay
--     private.
--   * Idempotent + clearly named — the only thing anon can do on hotels.

CREATE OR REPLACE FUNCTION public.get_hotel_branding(p_hotel_id uuid)
RETURNS TABLE (
  name      text,
  logo_url  text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT h.name, h.logo_url
    FROM public.hotels h
   WHERE h.id = p_hotel_id;
$$;

REVOKE ALL ON FUNCTION public.get_hotel_branding(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.get_hotel_branding(uuid) TO anon, authenticated;

COMMENT ON FUNCTION public.get_hotel_branding(uuid) IS
  'Public-safe lookup used by the Guest PWA landing screen to display a hotel''s name and logo to unauthenticated visitors arriving via QR.';
