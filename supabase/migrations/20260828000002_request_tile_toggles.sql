-- supabase/migrations/20260828000002_request_tile_toggles.sql
--
-- Boaz: some hotels don't offer every guest-request "quick select" tile
-- (e.g. no room service), so the super admin needs to turn specific tiles
-- off per hotel. The tile catalog itself (icon + label per category) is
-- static in the guest PWA client code (hotel_guest_app/lib/presentation/
-- new_request_screen.dart) and already fully localized in 4 languages —
-- duplicating that as DB rows would mean translating custom text per
-- hotel, which nobody asked for. So this table is opt-out only: it stores
-- which of the fixed tile keys are HIDDEN for a hotel, not a catalog.
-- Absence of a row = tile shown (existing hotels need zero backfill and
-- keep today's "show everything" behavior).

CREATE TABLE hotel_request_tiles_disabled (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id   uuid NOT NULL REFERENCES hotels(id) ON DELETE CASCADE,
  category   text NOT NULL CHECK (category IN ('housekeeping', 'maintenance', 'reception')),
  tile_key   text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (hotel_id, category, tile_key)
);

COMMENT ON TABLE hotel_request_tiles_disabled IS 'Opt-out per hotel: presence of a (hotel_id, category, tile_key) row hides that quick-select tile in the guest PWA new-request screen. Tile catalog itself is static client-side, see new_request_screen.dart _serviceTilesByCategory.';

ALTER TABLE hotel_request_tiles_disabled ENABLE ROW LEVEL SECURITY;

-- Guest PWA reads this anonymously (same trust model as get_hotel_branding /
-- hotel_amenities) to know which tiles to hide before the guest even logs in.
CREATE POLICY "request_tiles_disabled_public_read" ON hotel_request_tiles_disabled
  FOR SELECT USING (true);

-- Only the super admin (app owner) manages this — matches Boaz's explicit ask,
-- and the same restriction already used for hotels_admin_write.
CREATE POLICY "request_tiles_disabled_super_admin_manage" ON hotel_request_tiles_disabled
  FOR ALL USING (auth_role() = 'super_admin');
