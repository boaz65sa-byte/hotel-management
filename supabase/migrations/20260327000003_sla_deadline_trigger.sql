CREATE OR REPLACE FUNCTION set_sla_deadline()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.sla_deadline := NEW.created_at + CASE NEW.priority
    WHEN 'urgent' THEN INTERVAL '60 minutes'
    WHEN 'high'   THEN INTERVAL '2 hours'
    WHEN 'normal' THEN INTERVAL '4 hours'
    WHEN 'low'    THEN INTERVAL '8 hours'
    ELSE INTERVAL '4 hours'
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_sla_deadline ON tickets;
CREATE TRIGGER trg_set_sla_deadline
  BEFORE INSERT ON tickets
  FOR EACH ROW EXECUTE FUNCTION set_sla_deadline();
