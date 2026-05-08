-- Optional internal notes on guest feedback rows (Admin Panel, service role).
-- Idempotent. Safe if applied after guest_feedback table exists.

ALTER TABLE guest_feedback
  ADD COLUMN IF NOT EXISTS staff_notes TEXT;

COMMENT ON COLUMN guest_feedback.staff_notes IS
  'Internal notes visible only in Super Admin panel; not shown to guests.';
