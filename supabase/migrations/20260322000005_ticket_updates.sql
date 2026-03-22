-- supabase/migrations/20260322000005_ticket_updates.sql

CREATE TYPE update_type AS ENUM (
  'comment', 'status_change', 'photo_added', 'approval_request', 'claim'
);

CREATE TABLE ticket_updates (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id    uuid NOT NULL REFERENCES hotels(id),
  ticket_id   uuid NOT NULL REFERENCES tickets(id),
  user_id     uuid NOT NULL REFERENCES users(id),
  message     text,
  update_type update_type NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
  -- Append-only: no UPDATE or DELETE allowed (enforced via RLS)
);

COMMENT ON TABLE ticket_updates IS 'Append-only audit trail for ticket events. No updates or deletes.';
