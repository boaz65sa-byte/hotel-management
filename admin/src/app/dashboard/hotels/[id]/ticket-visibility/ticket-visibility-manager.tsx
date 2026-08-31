'use client'

// Mirrors the department manager roles in staff_app/lib/features/tickets/data/ticket_repository.dart
// fetchDeptStaff and admin/src/lib/roles.ts (DEPT_MANAGER_ROLES). Only
// department-manager-tier roles are meaningful here — hotel-wide roles
// (ceo, software_manager, hotel_admin, super_admin) always see everything
// regardless of this setting.
const DEPT_MANAGER_ROLES: { value: string; icon: string; label: string }[] = [
  { value: 'reception_manager',    icon: '🛎️', label: 'מנהל קבלה' },
  { value: 'maintenance_manager',  icon: '🔧', label: 'מנהל אחזקה' },
  { value: 'housekeeping_manager', icon: '🧹', label: 'מנהל משק בית' },
  { value: 'security_manager',     icon: '🔒', label: 'מנהל ביטחון' },
  { value: 'kitchen_manager',      icon: '🍳', label: 'מנהל מטבח' },
]

export function TicketVisibilityManager({
  restrictedRoles,
  setScopeAction,
}: {
  restrictedRoles: string[]
  setScopeAction: (fd: FormData) => Promise<void>
}) {
  const restricted = new Set(restrictedRoles)

  return (
    <div className="space-y-3">
      {DEPT_MANAGER_ROLES.map((role) => {
        const isRestricted = restricted.has(role.value)
        return (
          <div
            key={role.value}
            className="flex items-center justify-between rounded-xl border border-gray-200 bg-white p-4"
          >
            <div className="flex items-center gap-3">
              <span className="text-2xl">{role.icon}</span>
              <span className="font-medium text-gray-800">{role.label}</span>
            </div>
            <form action={setScopeAction} className="flex items-center gap-2 text-sm">
              <input type="hidden" name="role" value={role.value} />
              <input
                type="hidden"
                name="next_scope"
                value={isRestricted ? 'all_departments' : 'own_department_only'}
              />
              <span className={!isRestricted ? 'font-semibold text-gray-800' : 'text-gray-400'}>
                כל המחלקות
              </span>
              <button
                type="submit"
                className={`relative h-6 w-11 rounded-full transition-colors ${
                  isRestricted ? 'bg-blue-600' : 'bg-gray-300'
                }`}
                aria-label={`Toggle scope for ${role.label}`}
              >
                <span
                  className={`absolute top-0.5 h-5 w-5 rounded-full bg-white transition-transform ${
                    isRestricted ? 'translate-x-0.5' : 'translate-x-5'
                  }`}
                />
              </button>
              <span className={isRestricted ? 'font-semibold text-gray-800' : 'text-gray-400'}>
                רק המחלקה שלו
              </span>
            </form>
          </div>
        )
      })}
    </div>
  )
}
