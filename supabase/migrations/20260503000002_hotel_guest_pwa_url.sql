-- supabase/migrations/20260503000002_hotel_guest_pwa_url.sql
--
-- Adds a per-hotel guest PWA URL so QR codes (in Flutter app + Admin Panel)
-- generate links pointing to the right deployment for each hotel.
-- Until set per-hotel, falls back to the default value.
-- Idempotent.

ALTER TABLE hotels
  ADD COLUMN IF NOT EXISTS guest_pwa_url TEXT
    NOT NULL DEFAULT 'https://zesty-queijadas-16c29.netlify.app';

COMMENT ON COLUMN hotels.guest_pwa_url IS
  'Base URL of the guest PWA deployment for this hotel. QR codes append /?hotel=<id>&room=<num>.';
