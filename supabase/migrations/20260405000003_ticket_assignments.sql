CREATE TABLE IF NOT EXISTS ticket_assignments (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id   uuid NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  assigned_to uuid NOT NULL REFERENCES users(id),
  assigned_by uuid NOT NULL REFERENCES users(id),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  note        text
);

CREATE INDEX IF NOT EXISTS idx_ticket_assignments_ticket ON ticket_assignments(ticket_id);

ALTER TABLE ticket_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hotel members can view assignments"
  ON ticket_assignments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      JOIN users u ON u.id = auth.uid()
      WHERE t.id = ticket_id AND t.hotel_id = u.hotel_id
    )
  );

CREATE POLICY "managers can insert assignments"
  ON ticket_assignments FOR INSERT
  WITH CHECK (
    (auth.jwt()->>'role') IN (
      'super_admin','hotel_admin',
      'reception_manager','maintenance_manager',
      'housekeeping_manager','security_manager',
      'deputy_reception'
    )
  );
