CREATE TABLE IF NOT EXISTS ticket_messages (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id  uuid NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  sender_id  uuid NOT NULL REFERENCES users(id),
  body       text NOT NULL CHECK (char_length(body) > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket ON ticket_messages(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_messages_created ON ticket_messages(created_at);

ALTER TABLE ticket_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "hotel members can read messages"
  ON ticket_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tickets t
      JOIN users u ON u.id = auth.uid()
      WHERE t.id = ticket_id AND t.hotel_id = u.hotel_id
    )
  );

CREATE POLICY "hotel members can send messages"
  ON ticket_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM tickets t
      JOIN users u ON u.id = auth.uid()
      WHERE t.id = ticket_id AND t.hotel_id = u.hotel_id
    )
  );

ALTER PUBLICATION supabase_realtime ADD TABLE ticket_messages;
