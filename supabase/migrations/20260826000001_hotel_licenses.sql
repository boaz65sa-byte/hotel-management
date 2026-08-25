-- supabase/migrations/20260826000001_hotel_licenses.sql
--
-- Serial/license-key system: the super admin generates a code before selling
-- the platform to a new hotel; hotel creation redeems it. Deliberately scoped
-- to "generate + gate at creation" only — no expiry/billing enforcement yet.

CREATE TABLE hotel_licenses (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  serial_code   text NOT NULL UNIQUE,
  plan          text NOT NULL DEFAULT 'basic' CHECK (plan IN ('basic','pro','enterprise')),
  status        text NOT NULL DEFAULT 'unused' CHECK (status IN ('unused','active','revoked')),
  hotel_id      uuid REFERENCES hotels(id),
  issued_by     uuid REFERENCES users(id),
  issued_at     timestamptz NOT NULL DEFAULT now(),
  activated_at  timestamptz,
  notes         text
);

COMMENT ON TABLE hotel_licenses IS 'One serial code per sellable hotel license. redeem_hotel_license() flips unused -> active atomically at hotel-creation time.';

ALTER TABLE hotel_licenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hotel_licenses_super_admin_only" ON hotel_licenses
  FOR ALL USING (auth_role() = 'super_admin');

-- Atomically redeem a code for a newly created hotel. SECURITY DEFINER so the
-- hotel-creation server action (running as service role already, but this
-- keeps the check-and-set atomic regardless of caller) can call it as a
-- single statement instead of a read-then-write race.
CREATE OR REPLACE FUNCTION public.redeem_hotel_license(p_serial text, p_hotel_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated int;
BEGIN
  UPDATE hotel_licenses
     SET status = 'active',
         hotel_id = p_hotel_id,
         activated_at = now()
   WHERE serial_code = p_serial
     AND status = 'unused';

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  IF v_updated = 0 THEN
    RAISE EXCEPTION 'Invalid or already-used license code';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_hotel_license(text, uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.redeem_hotel_license(text, uuid) TO service_role;

COMMENT ON FUNCTION public.redeem_hotel_license(text, uuid) IS
  'Atomically marks an unused hotel_licenses row as active and links it to the new hotel. Raises if the code is missing/already used.';
