// Single source of truth for user roles in the admin panel.
// Mirror of the `user_role` Postgres ENUM in
//   supabase/migrations/20260322000002_users.sql
//   supabase/migrations/20260405000001_hotel_admin_role.sql (hotel_admin)
//   supabase/migrations/20260514000002_software_manager_role.sql (software_manager)
//
// ──────────────────────────────────────────────────────────────────────
// Role hierarchy (decided 2026-05-14):
//
//   🟣 super_admin       — Platform owner (Boaz). All hotels, all data.
//
//   🟦 ceo               — "מנכ"ל מלון". Hotel-level admin, scoped to ONE hotel.
//   🟦 software_manager  — "מנהל תוכנה". Hotel-level admin, scoped to ONE hotel.
//   🟦 hotel_admin       — Legacy synonym, still recognised.
//
//   🟢 *_manager         — Department head (reception / maintenance / …).
//
//   ⚪ staff              — Operational employees.
// ──────────────────────────────────────────────────────────────────────

export type RoleTier = 'super_admin' | 'hotel_admin' | 'dept_manager' | 'staff'

export type Role = {
  value: string
  label: string         // Hebrew display name
  icon: string          // Single emoji for badges / lists
  tier: RoleTier
  description?: string  // Optional one-liner for tooltips and the wizard
}

export const ROLES: readonly Role[] = [
  // ─── 🟣 Platform owner ────────────────────────────────────────────
  // super_admin is intentionally NOT in this list — it is created out
  // of band (SQL seed) and must not be selectable from the admin UI.

  // ─── 🟦 Hotel-level admins ───────────────────────────────────────
  {
    value:       'ceo',
    label:       'מנכ"ל מלון',
    icon:        '👔',
    tier:        'hotel_admin',
    description: 'ניהול מלא של המלון שלו: הוספת משתמשים, צפייה בכל הנתונים, שינוי הגדרות.',
  },
  {
    value:       'software_manager',
    label:       'מנהל תוכנה',
    icon:        '🛠️',
    tier:        'hotel_admin',
    description: 'גישת מנהל לתוכנה במלון שלו. אחראי על משתמשים, הרשאות וטכנולוגיה.',
  },
  {
    value:       'hotel_admin',
    label:       'אדמין מלון (legacy)',
    icon:        '🛡️',
    tier:        'hotel_admin',
    description: 'תפקיד קיים מהעבר — שווה ערך למנכ"ל / מנהל תוכנה.',
  },

  // ─── 🟢 Department managers ──────────────────────────────────────
  {
    value: 'reception_manager',
    label: 'מנהל קבלה',
    icon:  '📞',
    tier:  'dept_manager',
  },
  {
    value: 'maintenance_manager',
    label: 'מנהל אחזקה',
    icon:  '🔧',
    tier:  'dept_manager',
  },
  {
    value: 'housekeeping_manager',
    label: 'מנהל משק בית',
    icon:  '🧹',
    tier:  'dept_manager',
  },
  {
    value: 'security_manager',
    label: 'מנהל ביטחון',
    icon:  '🛡️',
    tier:  'dept_manager',
  },

  // ─── ⚪ Operational staff ─────────────────────────────────────────
  {
    value: 'deputy_reception',
    label: 'סגן מנהל קבלה',
    icon:  '📋',
    tier:  'staff',
  },
  {
    value: 'receptionist',
    label: 'פקיד קבלה',
    icon:  '🧑‍💼',
    tier:  'staff',
  },
  {
    value: 'security_guard',
    label: 'קב"ט',
    icon:  '👮',
    tier:  'staff',
  },
  {
    value: 'maintenance_tech',
    label: 'טכנאי אחזקה',
    icon:  '🔩',
    tier:  'staff',
  },
  {
    value: 'repairman',
    label: 'תיקונאי',
    icon:  '🪛',
    tier:  'staff',
  },
] as const

export type RoleValue = (typeof ROLES)[number]['value']

// ─── Helpful sets / lookups ────────────────────────────────────────

export const HOTEL_ADMIN_ROLES: ReadonlySet<string> = new Set(
  ROLES.filter((r) => r.tier === 'hotel_admin').map((r) => r.value),
)

export const DEPT_MANAGER_ROLES: ReadonlySet<string> = new Set(
  ROLES.filter((r) => r.tier === 'dept_manager').map((r) => r.value),
)

// Anyone with elevated permissions — used to gate Excel export, audit
// log, etc. (Super admin always passes, even though it's not in ROLES.)
export const MANAGER_ROLES: ReadonlySet<string> = new Set<string>([
  'super_admin',
  ...HOTEL_ADMIN_ROLES,
  ...DEPT_MANAGER_ROLES,
])

export function roleLabel(value: string | null | undefined): string {
  if (!value) return '—'
  if (value === 'super_admin') return '👑 סופר אדמין'
  const r = ROLES.find((x) => x.value === value)
  if (!r) return value
  return `${r.icon} ${r.label}`
}

export function isHotelAdmin(role: string | null | undefined): boolean {
  if (!role) return false
  return HOTEL_ADMIN_ROLES.has(role)
}

export function canManageAdmin(role: string | null | undefined): boolean {
  // Who is allowed into the Admin Panel at all?
  return role === 'super_admin' || isHotelAdmin(role)
}

export function isSuperAdmin(role: string | null | undefined): boolean {
  return role === 'super_admin'
}
