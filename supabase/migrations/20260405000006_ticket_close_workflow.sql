CREATE OR REPLACE FUNCTION mark_ticket_done(p_ticket_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM tickets
    WHERE id = p_ticket_id
      AND requires_media = true
      AND photo_after_url IS NULL
  ) THEN
    RAISE EXCEPTION 'requires_after_photo';
  END IF;

  UPDATE tickets
  SET pending_close = true, updated_at = now()
  WHERE id = p_ticket_id
    AND (claimed_by = auth.uid() OR assigned_to = auth.uid());
END;
$$;

CREATE OR REPLACE FUNCTION manager_close_ticket(p_ticket_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_role text;
BEGIN
  v_role := auth.jwt()->>'role';

  IF v_role NOT IN (
    'super_admin','hotel_admin',
    'reception_manager','maintenance_manager',
    'housekeeping_manager','security_manager'
  ) THEN
    RAISE EXCEPTION 'insufficient_role';
  END IF;

  UPDATE tickets
  SET status = 'resolved',
      resolved_at = now(),
      pending_close = false,
      updated_at = now()
  WHERE id = p_ticket_id;
END;
$$;
