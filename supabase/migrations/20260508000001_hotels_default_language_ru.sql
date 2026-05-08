-- Allow 'ru' as a valid default_language for hotels.
-- The original CHECK constraint only permitted he/en/ar; this expands it.
-- Idempotent: drops the old constraint if present, then adds the new one.

ALTER TABLE hotels
  DROP CONSTRAINT IF EXISTS hotels_default_language_check;

ALTER TABLE hotels
  ADD CONSTRAINT hotels_default_language_check
    CHECK (default_language IN ('he', 'en', 'ar', 'ru'));
