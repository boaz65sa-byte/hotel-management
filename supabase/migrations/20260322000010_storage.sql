-- supabase/migrations/20260322000010_storage.sql

-- Create per-hotel photo storage (one bucket, path: hotel_id/ticket_id/photo.jpg)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'ticket-photos',
  'ticket-photos',
  false,
  10485760,
  ARRAY['image/jpeg','image/png','image/webp','image/heic']
)
ON CONFLICT DO NOTHING;

-- RLS on storage: users can only access photos from their hotel
CREATE POLICY "storage_select_same_hotel" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'ticket-photos' AND
    (storage.foldername(name))[1] = auth_hotel_id()::text
  );

CREATE POLICY "storage_insert_same_hotel" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'ticket-photos' AND
    (storage.foldername(name))[1] = auth_hotel_id()::text AND
    auth_is_active() = true
  );
