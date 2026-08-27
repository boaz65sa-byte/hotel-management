-- supabase/migrations/20260827000001_baseline_guest_requests.sql
--
-- `guest_requests` was created out-of-band (dashboard/SQL editor) and was
-- never captured in a tracked migration — two later migrations
-- (20260515000002, 20260515000003) already assume it exists. This adds a
-- CREATE TABLE IF NOT EXISTS baseline (a no-op against the live table, since
-- it already exists) so the schema is reproducible from migrations alone,
-- plus the CHECK constraints the client code has always enforced but the
-- database never did.
--
-- Also closes the same gap for hotels.stay_threshold, referenced throughout
-- the admin app (hotel-form.tsx, hotels/new/actions.ts) but never migrated.

CREATE TABLE IF NOT EXISTS guest_requests (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id      uuid NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
  room_number   text NOT NULL,
  guest_name    text NOT NULL,
  category      text NOT NULL,
  description   text,
  status        text NOT NULL DEFAULT 'open',
  assigned_dept text,
  assigned_to   uuid REFERENCES auth.users(id),
  created_by    text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'guest_requests_category_check'
  ) THEN
    ALTER TABLE guest_requests
      ADD CONSTRAINT guest_requests_category_check
      CHECK (category IN ('housekeeping', 'maintenance', 'reception'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'guest_requests_status_check'
  ) THEN
    ALTER TABLE guest_requests
      ADD CONSTRAINT guest_requests_status_check
      CHECK (status IN ('open', 'assigned', 'in_progress', 'resolved', 'cancelled'));
  END IF;
END $$;

ALTER TABLE hotels ADD COLUMN IF NOT EXISTS stay_threshold integer NOT NULL DEFAULT 3;

COMMENT ON TABLE guest_requests IS 'Baselined 2026-08-27 — table predates migration tracking; this CREATE is a documentation no-op against the live table, the CHECK constraints are the real change.';
