'use client'

// Mirrors the staff-app department catalog in
// staff_app/lib/features/tickets/presentation/new_ticket_screen.dart
// (_deptMeta). Icon + key must stay in sync with that file.
const DEPARTMENTS: { key: string; icon: string; label: string }[] = [
  { key: 'maintenance',  icon: '🔧', label: 'אחזקה' },
  { key: 'reception',    icon: '🛎️', label: 'קבלה' },
  { key: 'security',     icon: '🔒', label: 'ביטחון' },
  { key: 'housekeeping', icon: '🧹', label: 'משק בית' },
  { key: 'kitchen',      icon: '🍳', label: 'מטבח' },
]

export function DepartmentsManager({
  disabledDepartments,
  setDepartmentAction,
}: {
  disabledDepartments: string[]
  setDepartmentAction: (fd: FormData) => Promise<void>
}) {
  const disabled = new Set(disabledDepartments)

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-3">
      {DEPARTMENTS.map((dept) => {
        const enabled = !disabled.has(dept.key)
        return (
          <form key={dept.key} action={setDepartmentAction}>
            <input type="hidden" name="department" value={dept.key} />
            <input type="hidden" name="next_enabled" value={(!enabled).toString()} />
            <button
              type="submit"
              className={`w-full rounded-xl border p-4 text-center transition-colors ${
                enabled
                  ? 'bg-white border-gray-200 hover:border-gray-400'
                  : 'bg-gray-50 border-gray-200 opacity-40 hover:opacity-70'
              }`}
            >
              <div className="text-3xl mb-1">{dept.icon}</div>
              <div className="text-sm font-medium text-gray-700 leading-tight">
                {dept.label}
              </div>
              <div
                className={`mt-2 text-[10px] font-semibold rounded-full px-2 py-0.5 inline-block ${
                  enabled ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-500'
                }`}
              >
                {enabled ? 'פעיל' : 'כבוי'}
              </div>
            </button>
          </form>
        )
      })}
    </div>
  )
}
