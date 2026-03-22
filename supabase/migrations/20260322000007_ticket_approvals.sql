-- supabase/migrations/20260322000007_ticket_approvals.sql

CREATE TYPE approver_role AS ENUM ('maintenance_manager', 'reception_manager');

CREATE TABLE ticket_approvals (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id         uuid NOT NULL REFERENCES hotels(id),
  ticket_id        uuid NOT NULL REFERENCES tickets(id),
  resolution_type  resolution_type NOT NULL,
  submission_round integer NOT NULL DEFAULT 1 CHECK (submission_round > 0),
  approver_id      uuid NOT NULL REFERENCES users(id),
  approver_role    approver_role NOT NULL,
  approved         boolean,
  approved_at      timestamptz,
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now()
  -- Append-only. On rejection+resubmission: new rows with submission_round+1
);

-- Helper view: current round approval status (CTE avoids window-in-aggregate)
CREATE VIEW ticket_approval_status AS
WITH latest AS (
  SELECT ticket_id, MAX(submission_round) AS current_round
  FROM ticket_approvals
  GROUP BY ticket_id
)
SELECT
  ta.ticket_id,
  l.current_round,
  COUNT(*) FILTER (WHERE ta.approved = true  AND ta.submission_round = l.current_round) AS approvals_given,
  COUNT(*) FILTER (WHERE ta.approved = false AND ta.submission_round = l.current_round) AS rejections_given
FROM ticket_approvals ta
JOIN latest l ON l.ticket_id = ta.ticket_id
GROUP BY ta.ticket_id, l.current_round;

COMMENT ON TABLE ticket_approvals IS 'Append-only. New rows per resubmission round. Query on MAX(submission_round) for current state.';
