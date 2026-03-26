-- Fix: Auth Hook must return ONLY {"claims": {...}}, not the full event object
-- Supabase Custom Access Token Hook spec:
--   Input:  { "user_id": "uuid", "claims": {...} }
--   Output: { "claims": {...} }  ← only claims, not full event

CREATE OR REPLACE FUNCTION public.custom_jwt_claims(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_record users%ROWTYPE;
  user_id     uuid;
  base_claims jsonb;
BEGIN
  user_id     := (event->>'user_id')::uuid;
  base_claims := event->'claims';

  SELECT * INTO user_record FROM users WHERE id = user_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('claims', base_claims);
  END IF;

  RETURN jsonb_build_object(
    'claims',
    base_claims
    || jsonb_build_object(
        'hotel_id',  user_record.hotel_id,
        'role',      user_record.role,
        'is_active', user_record.is_active
       )
  );
END;
$$;
