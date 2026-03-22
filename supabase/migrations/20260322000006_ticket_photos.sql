-- supabase/migrations/20260322000006_ticket_photos.sql

CREATE TABLE ticket_photos (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id        uuid NOT NULL REFERENCES hotels(id),
  ticket_id       uuid NOT NULL REFERENCES tickets(id),
  uploaded_by     uuid NOT NULL REFERENCES users(id),
  photo_url       text NOT NULL,
  file_size_bytes integer CHECK (file_size_bytes <= 10485760),
  taken_at        timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
  -- Append-only: no UPDATE or DELETE allowed
);

COMMENT ON TABLE ticket_photos IS 'Append-only photo log. Max 10MB per photo enforced at constraint and app layer.';
