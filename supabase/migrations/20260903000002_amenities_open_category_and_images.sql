-- supabase/migrations/20260903000002_amenities_open_category_and_images.sql
--
-- Two changes to hotel_amenities so super_admin/hotel admins can add
-- entirely new named services (not just spa/restaurant/room_service) and
-- attach a photo to each:
--
-- 1. Drop the fixed category CHECK constraint. Category becomes a free-text
--    label the hotel operator chooses (e.g. "עיסוי", "טניס", "מיני בר") —
--    the three original values stay as UI quick-picks in the admin panel,
--    but the database no longer restricts the value.
-- 2. Add a public storage bucket for amenity photos, same trust model as
--    hotel-logos (public read, writes only via the admin's service-role key).

ALTER TABLE hotel_amenities DROP CONSTRAINT IF EXISTS hotel_amenities_category_check;

COMMENT ON COLUMN hotel_amenities.category IS
  'Free-text service/menu category chosen by the hotel operator (e.g. spa, restaurant, room_service, or any custom name). No longer constrained to a fixed list — admin UI offers the original three as quick-picks plus free text.';

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'hotel-amenities',
  'hotel-amenities',
  true,
  2097152,
  ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Public read for hotel-amenities'
  ) THEN
    EXECUTE $POL$
      CREATE POLICY "Public read for hotel-amenities"
        ON storage.objects FOR SELECT
        USING (bucket_id = 'hotel-amenities')
    $POL$;
  END IF;
END $$;
