-- Add theme column to hotels table
-- Supports two named themes: 'luxury' (dark gold) and 'clean_blue' (white + blue)
ALTER TABLE hotels
  ADD COLUMN theme TEXT NOT NULL DEFAULT 'clean_blue'
    CHECK (theme IN ('luxury', 'clean_blue'));
