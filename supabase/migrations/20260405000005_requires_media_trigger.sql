CREATE OR REPLACE FUNCTION set_requires_media()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.priority::text IN ('urgent','emergency') THEN
    NEW.requires_media = true;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_requires_media ON tickets;
CREATE TRIGGER trg_requires_media
  BEFORE INSERT OR UPDATE OF priority ON tickets
  FOR EACH ROW EXECUTE FUNCTION set_requires_media();
