-- Public bucket for hotel logos.
-- Public read so the Guest PWA can load the image without auth.
-- Writes go through the service-role key (server actions in admin),
-- so we don't need explicit INSERT/UPDATE policies — service_role bypasses RLS.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'hotel-logos',
  'hotel-logos',
  true,
  2097152,
  ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Public read policy (idempotent — ignore if it already exists).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage'
      AND tablename = 'objects'
      AND policyname = 'Public read for hotel-logos'
  ) THEN
    EXECUTE $POL$
      CREATE POLICY "Public read for hotel-logos"
        ON storage.objects FOR SELECT
        USING (bucket_id = 'hotel-logos')
    $POL$;
  END IF;
END $$;
