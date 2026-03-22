-- supabase/migrations/20260322000013_tickets_repair.sql
-- Ensures tickets table has correct updated_at trigger.
-- Note: CHECK constraints with subqueries are not supported in PostgreSQL.
-- Room-hotel consistency is enforced at app layer + RLS.

-- Ensure update_updated_at function exists
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Ensure trigger exists on tickets
DROP TRIGGER IF EXISTS tickets_updated_at ON tickets;
CREATE TRIGGER tickets_updated_at
  BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
