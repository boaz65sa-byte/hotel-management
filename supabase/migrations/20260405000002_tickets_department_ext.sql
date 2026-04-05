-- supabase/migrations/20260405000002_tickets_department_ext.sql

-- assigned_to: explicit manager assignment (different from claimed_by which is self-claim)
ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS assigned_to    uuid REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS requires_media boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS pending_close  boolean NOT NULL DEFAULT false;

-- Extend ticket_priority enum to include 'emergency' (enums self-constrain; no CHECK needed)
ALTER TYPE ticket_priority ADD VALUE IF NOT EXISTS 'emergency';

-- Note: assigned_dept is already constrained by the dept_name enum
-- ('maintenance','reception','security','housekeeping') — no additional CHECK required.
