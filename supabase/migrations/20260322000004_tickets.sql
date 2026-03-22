-- supabase/migrations/20260322000004_tickets.sql

CREATE TYPE ticket_status AS ENUM (
  'open', 'in_progress', 'pending_approval', 'resolved', 'closed'
);

CREATE TYPE ticket_priority AS ENUM ('low', 'normal', 'high', 'urgent');

CREATE TYPE dept_name AS ENUM ('maintenance', 'housekeeping', 'security', 'reception');

CREATE TYPE resolution_type AS ENUM ('fixed', 'on_hold', 'room_closed');

CREATE TABLE tickets (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id        uuid NOT NULL REFERENCES hotels(id),
  room_id         uuid NOT NULL REFERENCES rooms(id),
  opened_by       uuid NOT NULL REFERENCES users(id),
  assigned_dept   dept_name NOT NULL,
  claimed_by      uuid REFERENCES users(id),  -- NULL = unassigned
  title           text NOT NULL,
  description     text,
  priority        ticket_priority NOT NULL DEFAULT 'normal',
  status          ticket_status NOT NULL DEFAULT 'open',
  resolution_type resolution_type,  -- NOT NULL enforced at app layer when resolving
  sla_deadline    timestamptz,      -- set at creation: now() + hotel.default_sla_hours
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  resolved_at     timestamptz
  -- Room must belong to same hotel (enforced via trigger below)
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER tickets_updated_at
  BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Enforce room belongs to same hotel (subqueries not allowed in CHECK constraints)
CREATE OR REPLACE FUNCTION check_ticket_room_hotel_match()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM rooms WHERE id = NEW.room_id AND hotel_id = NEW.hotel_id
  ) THEN
    RAISE EXCEPTION 'room_id % does not belong to hotel_id %', NEW.room_id, NEW.hotel_id
      USING ERRCODE = 'foreign_key_violation';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER ticket_room_hotel_match
  BEFORE INSERT OR UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION check_ticket_room_hotel_match();

COMMENT ON TABLE tickets IS 'Service tickets. claimed_by=NULL means unassigned/visible to all dept members.';
COMMENT ON COLUMN tickets.resolution_type IS 'Must be set before status transitions to resolved or closed (enforced at app layer).';
COMMENT ON COLUMN tickets.sla_deadline IS 'Set at creation: now() + hotels.default_sla_hours';
