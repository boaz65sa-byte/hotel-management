// Single source of truth for user roles in the admin panel.
// Mirror of the `user_role` Postgres ENUM in supabase/migrations/20260322000002_users.sql
// + `hotel_admin` from 20260405000001_hotel_admin_role.sql.
export const ROLES = [
  { value: 'hotel_admin',          label: 'Hotel Admin' },
  { value: 'ceo',                  label: 'CEO' },
  { value: 'reception_manager',    label: 'Reception Manager' },
  { value: 'maintenance_manager',  label: 'Maintenance Manager' },
  { value: 'housekeeping_manager', label: 'Housekeeping Manager' },
  { value: 'security_manager',     label: 'Security Manager' },
  { value: 'deputy_reception',     label: 'Deputy Reception' },
  { value: 'receptionist',         label: 'Receptionist' },
  { value: 'security_guard',       label: 'Security Guard' },
  { value: 'maintenance_tech',     label: 'Maintenance Tech' },
  { value: 'repairman',            label: 'Repairman' },
] as const

export type RoleValue = typeof ROLES[number]['value']

export const MANAGER_ROLES: ReadonlySet<RoleValue> = new Set([
  'super_admin' as RoleValue, // not in ROLES list (created elsewhere) but treated as manager
  'hotel_admin',
  'ceo',
  'reception_manager',
  'maintenance_manager',
  'housekeeping_manager',
  'security_manager',
])
