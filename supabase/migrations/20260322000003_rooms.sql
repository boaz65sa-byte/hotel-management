-- supabase/migrations/20260322000003_rooms.sql

CREATE TYPE room_status AS ENUM ('available', 'on_hold', 'closed');

CREATE TABLE rooms (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id          uuid NOT NULL REFERENCES hotels(id),
  room_number       text NOT NULL,
  floor             integer,
  room_type         text,
  status            room_status NOT NULL DEFAULT 'available',
  notes             text,
  status_changed_by uuid REFERENCES users(id),
  status_changed_at timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),

  UNIQUE (hotel_id, room_number)
);

COMMENT ON TABLE rooms IS 'Hotel rooms. Status auto-updated by ticket resolution, or manually by managers.';
