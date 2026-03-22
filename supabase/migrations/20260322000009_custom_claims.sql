-- supabase/migrations/20260322000009_custom_claims.sql

-- Function called automatically after each login to set custom JWT claims
CREATE OR REPLACE FUNCTION public.custom_jwt_claims()
RETURNS jsonb
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  user_record users%ROWTYPE;
BEGIN
  SELECT * INTO user_record FROM users WHERE id = auth.uid();

  IF NOT FOUND THEN
    RETURN '{}'::jsonb;
  END IF;

  RETURN jsonb_build_object(
    'hotel_id', user_record.hotel_id,
    'role',     user_record.role,
    'is_active', user_record.is_active
  );
END;
$$;

-- Hook into Supabase Auth to run on each token refresh
-- In Supabase dashboard: Auth → Hooks → add custom_jwt_claims as "Custom Access Token" hook
