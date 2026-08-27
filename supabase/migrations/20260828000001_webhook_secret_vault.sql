-- Replace the hardcoded plaintext webhook secret in all 6 pg_net -> send-push
-- trigger functions with a runtime lookup against Supabase Vault.
--
-- Background: 20260515000003_send_push_webhooks.sql and
-- 20260827000003_amenities_ordering.sql both hardcoded the same literal
-- webhook secret directly in committed SQL, which ended up in git history.
-- The secret has been rotated (new value stored as the 'webhook_secret'
-- Vault entry and as the send-push Edge Function's WEBHOOK_SECRET env var,
-- both set out-of-band before this migration — never commit the raw value
-- to a migration file, or this problem just repeats itself).
--
-- This migration only replaces function bodies (CREATE OR REPLACE), so it
-- is safe to apply on top of the already-populated production database:
-- no schema/data changes, no locks beyond a brief per-function DDL lock.

CREATE OR REPLACE FUNCTION whk_fn_guest_request_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
DECLARE
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets WHERE name = 'webhook_secret';

  PERFORM net.http_post(
    url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  v_secret,
      'x-event-type',      'guest_request_insert'
    ),
    body    := jsonb_build_object('record', row_to_json(NEW))
  );
  RETURN NEW;
END;
$fn$;

CREATE OR REPLACE FUNCTION whk_fn_guest_request_status()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
DECLARE
  v_secret text;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    SELECT decrypted_secret INTO v_secret
      FROM vault.decrypted_secrets WHERE name = 'webhook_secret';

    PERFORM net.http_post(
      url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type',      'application/json',
        'x-webhook-secret',  v_secret,
        'x-event-type',      'guest_request_status'
      ),
      body    := jsonb_build_object(
        'record',     row_to_json(NEW),
        'old_record', row_to_json(OLD)
      )
    );
  END IF;
  RETURN NEW;
END;
$fn$;

CREATE OR REPLACE FUNCTION whk_fn_ticket_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
DECLARE
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets WHERE name = 'webhook_secret';

  PERFORM net.http_post(
    url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  v_secret,
      'x-event-type',      'ticket_insert'
    ),
    body    := jsonb_build_object('record', row_to_json(NEW))
  );
  RETURN NEW;
END;
$fn$;

CREATE OR REPLACE FUNCTION whk_fn_ticket_assigned()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
DECLARE
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets WHERE name = 'webhook_secret';

  PERFORM net.http_post(
    url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  v_secret,
      'x-event-type',      'ticket_assigned'
    ),
    body    := jsonb_build_object('record', row_to_json(NEW))
  );
  RETURN NEW;
END;
$fn$;

CREATE OR REPLACE FUNCTION whk_fn_room_assigned()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
DECLARE
  v_secret text;
BEGIN
  IF NEW.assigned_to IS DISTINCT FROM OLD.assigned_to THEN
    SELECT decrypted_secret INTO v_secret
      FROM vault.decrypted_secrets WHERE name = 'webhook_secret';

    PERFORM net.http_post(
      url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type',      'application/json',
        'x-webhook-secret',  v_secret,
        'x-event-type',      'room_assigned'
      ),
      body    := jsonb_build_object(
        'record',     row_to_json(NEW),
        'old_record', row_to_json(OLD)
      )
    );
  END IF;
  RETURN NEW;
END;
$fn$;

CREATE OR REPLACE FUNCTION whk_fn_amenity_order_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
DECLARE
  v_secret text;
BEGIN
  SELECT decrypted_secret INTO v_secret
    FROM vault.decrypted_secrets WHERE name = 'webhook_secret';

  PERFORM net.http_post(
    url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  v_secret,
      'x-event-type',      'amenity_order_insert'
    ),
    body    := jsonb_build_object('record', row_to_json(NEW))
  );
  RETURN NEW;
END;
$fn$;
