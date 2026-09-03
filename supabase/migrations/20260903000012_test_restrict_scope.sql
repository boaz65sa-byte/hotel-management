-- Temporary: restrict custom_dept_manager's ticket scope in the test hotel
-- to exercise the restrictive branch of tickets_select_same_hotel (the
-- default/unrestricted branch was already proven — this checks the actual
-- new OR clause does real work, not just ride along on the default).
-- Reverted by the cleanup migration.
INSERT INTO hotel_role_ticket_scope (hotel_id, role, scope)
VALUES ('00000000-0000-0000-0000-000000000001', 'custom_dept_manager', 'own_department_only')
ON CONFLICT (hotel_id, role) DO UPDATE SET scope = 'own_department_only';
