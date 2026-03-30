-- supabase/migrations/20260327000005_scheduled_tasks.sql

CREATE TABLE IF NOT EXISTS scheduled_tasks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id      UUID NOT NULL REFERENCES hotels(id),
  room_id       UUID REFERENCES rooms(id),
  title         TEXT NOT NULL,
  description   TEXT,
  recurrence    TEXT NOT NULL CHECK (recurrence IN ('daily','weekly','monthly','quarterly')),
  assigned_role TEXT NOT NULL,
  next_run_at   TIMESTAMPTZ NOT NULL,
  last_run_at   TIMESTAMPTZ,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- updated_at trigger (set_updated_at() created in Phase 6 migration)
CREATE TRIGGER trg_updated_at_scheduled_tasks
  BEFORE UPDATE ON scheduled_tasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS: hotel managers see their hotel's tasks, superAdmin sees all
ALTER TABLE scheduled_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hotel tasks" ON scheduled_tasks FOR ALL
  USING (
    (auth.jwt()->'claims'->>'hotel_id')::uuid = hotel_id
    OR (auth.jwt()->'claims'->>'role') = 'superAdmin'
  );
