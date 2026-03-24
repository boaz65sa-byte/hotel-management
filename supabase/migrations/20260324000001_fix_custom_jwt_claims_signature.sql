-- supabase/migrations/20260324000001_fix_custom_jwt_claims_signature.sql
-- Fix: Auth Hook requires (event jsonb) RETURNS jsonb signature

DROP FUNCTION IF EXISTS public.custom_jwt_claims();

CREATE OR REPLACE FUNCTION public.custom_jwt_claims(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  user_record users%ROWTYPE;
  user_id     uuid;
BEGIN
  user_id := (event->>'user_id')::uuid;

  SELECT * INTO user_record FROM users WHERE id = user_id;

  IF NOT FOUND THEN
    RETURN event;
  END IF;

  RETURN jsonb_set(
    jsonb_set(
      jsonb_set(
        event,
        '{claims,hotel_id}', to_jsonb(user_record.hotel_id)
      ),
      '{claims,role}', to_jsonb(user_record.role)
    ),
    '{claims,is_active}', to_jsonb(user_record.is_active)
  );
END;
$$;
