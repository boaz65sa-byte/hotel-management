-- Database webhooks → send-push Edge Function via pg_net.
-- Replaces manual Dashboard webhook configuration.
-- Re-runnable (DROP IF EXISTS + CREATE).

-- Ensure pg_net is available
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ─── Constants ───────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_url      text := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push';
  v_secret   text := '9ce4f12d132a2c10acb2d97f9c1eb0d90023d0e21c334e60da0b1881beb31b4e';
BEGIN

-- ─── 1. guest_request INSERT → notify dept staff + managers ──────────────────
DROP TRIGGER IF EXISTS whk_guest_request_insert ON guest_requests;

CREATE OR REPLACE FUNCTION whk_fn_guest_request_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
BEGIN
  PERFORM net.http_post(
    url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  '9ce4f12d132a2c10acb2d97f9c1eb0d90023d0e21c334e60da0b1881beb31b4e',
      'x-event-type',      'guest_request_insert'
    ),
    body    := jsonb_build_object('record', row_to_json(NEW))
  );
  RETURN NEW;
END;
$fn$;

CREATE TRIGGER whk_guest_request_insert
  AFTER INSERT ON guest_requests
  FOR EACH ROW EXECUTE FUNCTION whk_fn_guest_request_insert();

-- ─── 2. guest_request UPDATE (status) → notify guest ─────────────────────────
DROP TRIGGER IF EXISTS whk_guest_request_status ON guest_requests;

CREATE OR REPLACE FUNCTION whk_fn_guest_request_status()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    PERFORM net.http_post(
      url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type',      'application/json',
        'x-webhook-secret',  '9ce4f12d132a2c10acb2d97f9c1eb0d90023d0e21c334e60da0b1881beb31b4e',
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

CREATE TRIGGER whk_guest_request_status
  AFTER UPDATE ON guest_requests
  FOR EACH ROW EXECUTE FUNCTION whk_fn_guest_request_status();

-- ─── 3. ticket INSERT → notify dept staff + managers ─────────────────────────
DROP TRIGGER IF EXISTS whk_ticket_insert ON tickets;

CREATE OR REPLACE FUNCTION whk_fn_ticket_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
BEGIN
  PERFORM net.http_post(
    url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  '9ce4f12d132a2c10acb2d97f9c1eb0d90023d0e21c334e60da0b1881beb31b4e',
      'x-event-type',      'ticket_insert'
    ),
    body    := jsonb_build_object('record', row_to_json(NEW))
  );
  RETURN NEW;
END;
$fn$;

CREATE TRIGGER whk_ticket_insert
  AFTER INSERT ON tickets
  FOR EACH ROW EXECUTE FUNCTION whk_fn_ticket_insert();

-- ─── 4. ticket_assignments INSERT → notify assigned user ─────────────────────
DROP TRIGGER IF EXISTS whk_ticket_assigned ON ticket_assignments;

CREATE OR REPLACE FUNCTION whk_fn_ticket_assigned()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
BEGIN
  PERFORM net.http_post(
    url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type',      'application/json',
      'x-webhook-secret',  '9ce4f12d132a2c10acb2d97f9c1eb0d90023d0e21c334e60da0b1881beb31b4e',
      'x-event-type',      'ticket_assigned'
    ),
    body    := jsonb_build_object('record', row_to_json(NEW))
  );
  RETURN NEW;
END;
$fn$;

CREATE TRIGGER whk_ticket_assigned
  AFTER INSERT ON ticket_assignments
  FOR EACH ROW EXECUTE FUNCTION whk_fn_ticket_assigned();

-- ─── 5. rooms UPDATE (assigned_to) → notify housekeeping staff ───────────────
DROP TRIGGER IF EXISTS whk_room_assigned ON rooms;

CREATE OR REPLACE FUNCTION whk_fn_room_assigned()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $fn$
BEGIN
  IF NEW.assigned_to IS DISTINCT FROM OLD.assigned_to THEN
    PERFORM net.http_post(
      url     := 'https://vetwlonyzyzvhrtdwbzj.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type',      'application/json',
        'x-webhook-secret',  '9ce4f12d132a2c10acb2d97f9c1eb0d90023d0e21c334e60da0b1881beb31b4e',
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

CREATE TRIGGER whk_room_assigned
  AFTER UPDATE ON rooms
  FOR EACH ROW EXECUTE FUNCTION whk_fn_room_assigned();

END $$;
