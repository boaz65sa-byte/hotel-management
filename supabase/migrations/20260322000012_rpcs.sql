-- supabase/migrations/20260322000012_rpcs.sql

-- Atomic ticket claim: returns true if claimed, false if already taken
CREATE OR REPLACE FUNCTION claim_ticket(p_ticket_id uuid, p_user_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE rows_updated integer;
BEGIN
  UPDATE tickets
  SET claimed_by = p_user_id, status = 'in_progress', updated_at = now()
  WHERE id = p_ticket_id AND claimed_by IS NULL;
  GET DIAGNOSTICS rows_updated = ROW_COUNT;
  IF rows_updated > 0 THEN
    INSERT INTO ticket_updates (hotel_id, ticket_id, user_id, update_type, message)
    SELECT hotel_id, p_ticket_id, p_user_id, 'claim', 'Ticket claimed'
    FROM tickets WHERE id = p_ticket_id;
  END IF;
  RETURN rows_updated > 0;
END;
$$;

-- Create approval rows atomically for room_closed resolution
CREATE OR REPLACE FUNCTION create_approval_request(p_ticket_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_hotel_id uuid; v_round integer;
  v_maint_mgr uuid; v_recep_mgr uuid;
  v_resolution resolution_type;
BEGIN
  SELECT hotel_id, resolution_type INTO v_hotel_id, v_resolution
  FROM tickets WHERE id = p_ticket_id;
  SELECT COALESCE(MAX(submission_round), 0) + 1 INTO v_round
    FROM ticket_approvals WHERE ticket_id = p_ticket_id;
  SELECT id INTO v_maint_mgr FROM users
    WHERE hotel_id = v_hotel_id AND role = 'maintenance_manager' AND is_active = true LIMIT 1;
  SELECT id INTO v_recep_mgr FROM users
    WHERE hotel_id = v_hotel_id AND role = 'reception_manager' AND is_active = true LIMIT 1;
  INSERT INTO ticket_approvals
    (hotel_id, ticket_id, resolution_type, submission_round, approver_id, approver_role)
  VALUES
    (v_hotel_id, p_ticket_id, v_resolution, v_round, v_maint_mgr, 'maintenance_manager'),
    (v_hotel_id, p_ticket_id, v_resolution, v_round, v_recep_mgr, 'reception_manager');
END;
$$;

-- Check if both approvals are done and close ticket + room
CREATE OR REPLACE FUNCTION check_and_close_ticket(p_ticket_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_round integer; v_approvals integer; v_room_id uuid;
BEGIN
  SELECT MAX(submission_round) INTO v_round FROM ticket_approvals WHERE ticket_id = p_ticket_id;
  SELECT COUNT(*) INTO v_approvals FROM ticket_approvals
  WHERE ticket_id = p_ticket_id AND submission_round = v_round AND approved = true;
  IF v_approvals = 2 THEN
    UPDATE tickets SET status = 'closed', updated_at = now()
    WHERE id = p_ticket_id RETURNING room_id INTO v_room_id;
    UPDATE rooms SET status = 'closed', status_changed_at = now() WHERE id = v_room_id;
  END IF;
  IF EXISTS (SELECT 1 FROM ticket_approvals
    WHERE ticket_id = p_ticket_id AND submission_round = v_round AND approved = false) THEN
    UPDATE tickets SET status = 'in_progress', updated_at = now() WHERE id = p_ticket_id;
  END IF;
END;
$$;
