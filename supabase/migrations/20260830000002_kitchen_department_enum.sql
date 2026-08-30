-- supabase/migrations/20260830000002_kitchen_department_enum.sql

-- New department: kitchen (מטבח), matching the existing
-- maintenance/reception/security/housekeeping departments.
ALTER TYPE dept_name ADD VALUE IF NOT EXISTS 'kitchen';

-- Matching manager + staff roles, following the per-department pattern
-- (reception_manager/receptionist, maintenance_manager/maintenance_tech, ...).
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'kitchen_manager';
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'kitchen_staff';

-- Note: new enum values can't be referenced (in policies, inserts, etc.)
-- until this migration has committed — any usage lives in a later migration.
