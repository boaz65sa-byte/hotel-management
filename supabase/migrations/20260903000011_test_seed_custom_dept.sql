-- Temporary test fixture for live end-to-end verification of the custom
-- department feature — a real hotel_departments row and two tickets (one
-- in it, one in a fixed department) to check RLS visibility against.
-- Cleaned up by 20260903000012 once verification is done.
INSERT INTO hotel_departments (id, hotel_id, key, label, icon)
VALUES ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000001', 'spa_qa_test', 'Spa QA Test', '💆')
ON CONFLICT (id) DO NOTHING;

INSERT INTO tickets (id, hotel_id, room_id, opened_by, custom_department_id, title, priority, status)
SELECT
  '22222222-2222-2222-2222-222222222222',
  '00000000-0000-0000-0000-000000000001',
  r.id,
  u.id,
  '11111111-1111-1111-1111-111111111111',
  'QA test ticket — custom dept',
  'normal',
  'open'
FROM rooms r, users u
WHERE r.hotel_id = '00000000-0000-0000-0000-000000000001'
  AND u.hotel_id = '00000000-0000-0000-0000-000000000001'
LIMIT 1
ON CONFLICT (id) DO NOTHING;
