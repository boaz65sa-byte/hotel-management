-- Auto-set assigned_dept from category on INSERT into guest_requests.
-- Category values (housekeeping, maintenance, reception) match dept names directly.

CREATE OR REPLACE FUNCTION set_guest_request_dept()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.assigned_dept IS NULL THEN
    NEW.assigned_dept := NEW.category;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guest_request_dept ON guest_requests;

CREATE TRIGGER trg_guest_request_dept
  BEFORE INSERT ON guest_requests
  FOR EACH ROW EXECUTE FUNCTION set_guest_request_dept();

-- Backfill existing rows where assigned_dept is NULL
UPDATE guest_requests
SET assigned_dept = category
WHERE assigned_dept IS NULL;
