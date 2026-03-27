-- Phase 2: Add housekeeping_status to rooms
ALTER TABLE rooms
  ADD COLUMN IF NOT EXISTS housekeeping_status TEXT NOT NULL DEFAULT 'clean'
  CHECK (housekeeping_status IN ('dirty', 'cleaning', 'clean'));
