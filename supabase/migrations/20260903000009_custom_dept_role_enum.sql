-- supabase/migrations/20260903000009_custom_dept_role_enum.sql
--
-- Two generic role values so a brand-new custom department (see
-- hotel_departments, previous migration) doesn't need its own dedicated
-- enum value the way the 5 fixed departments each have
-- (reception_manager, kitchen_staff, etc). Every custom department's
-- manager gets 'custom_dept_manager' and every custom department's staff
-- gets 'custom_dept_staff' — which specific department is then resolved
-- per-user via users.department_id (added in the next migration, in its
-- own file since a value added by ALTER TYPE ... ADD VALUE can't be
-- referenced in the same transaction that adds it).

ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'custom_dept_manager';
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'custom_dept_staff';
