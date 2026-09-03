-- Cleanup: remove all test fixtures created while live-verifying the
-- custom-department feature (20260903000011/12). The test user itself
-- was already deleted via the manage-user edge function (its ON DELETE
-- CASCADE/SET NULL would have handled the ticket/department FK either
-- way, but doing this explicitly is clearer).
DELETE FROM hotel_role_ticket_scope
  WHERE hotel_id = '00000000-0000-0000-0000-000000000001' AND role = 'custom_dept_manager';
DELETE FROM tickets WHERE id = '22222222-2222-2222-2222-222222222222';
DELETE FROM hotel_departments WHERE id = '11111111-1111-1111-1111-111111111111';
