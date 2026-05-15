-- Ensures accepted_at column exists on tickets table.
-- The original migration (20260327000002) may have partially failed.
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ;
