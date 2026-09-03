'use client'
import { useState } from 'react'

type Department = {
  id: string
  key: string
  label: string
  icon: string
  is_active: boolean
  created_at: string
  userCount: number
}

export function CustomDepartmentsManager({
  departments,
  createAction,
  toggleAction,
  deleteAction,
}: {
  departments: Department[]
  createAction: (fd: FormData) => Promise<void>
  toggleAction: (fd: FormData) => Promise<void>
  deleteAction: (fd: FormData) => Promise<void>
}) {
  const [showForm, setShowForm] = useState(false)

  return (
    <div className="space-y-6">
      <div>
        {!showForm ? (
          <button
            type="button"
            onClick={() => setShowForm(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700"
          >
            + הוסף מחלקה חדשה
          </button>
        ) : (
          <form
            action={async (fd) => {
              await createAction(fd)
              setShowForm(false)
            }}
            className="bg-gray-50 border rounded-xl p-4 flex flex-wrap items-end gap-3"
          >
            <div>
              <label className="block text-xs font-medium mb-1">אייקון (אימוג&apos;י)</label>
              <input name="icon" defaultValue="🏷️" maxLength={4}
                className="w-20 border rounded px-3 py-2 text-sm text-center" />
            </div>
            <div className="flex-1 min-w-[200px]">
              <label className="block text-xs font-medium mb-1">שם המחלקה</label>
              <input name="label" placeholder="למשל: ספא, בריכה, חניה"
                className="w-full border rounded px-3 py-2 text-sm" required />
            </div>
            <div className="flex gap-2">
              <button type="submit" className="bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700">
                שמור
              </button>
              <button type="button" onClick={() => setShowForm(false)} className="border px-4 py-2 rounded-lg text-sm">
                ביטול
              </button>
            </div>
          </form>
        )}
      </div>

      {departments.length === 0 ? (
        <p className="text-gray-500 text-center py-12">אין עדיין מחלקות מותאמות למלון זה.</p>
      ) : (
        <div className="overflow-x-auto rounded-xl border">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">מחלקה</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">משתמשים</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">פעיל</th>
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {departments.map((d) => (
                <tr key={d.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium">{d.icon} {d.label}</td>
                  <td className="px-4 py-3 text-gray-500">{d.userCount}</td>
                  <td className="px-4 py-3">
                    <form action={toggleAction}>
                      <input type="hidden" name="department_id" value={d.id} />
                      <input type="hidden" name="next_active" value={(!d.is_active).toString()} />
                      <button
                        type="submit"
                        className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                          d.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                        }`}
                      >
                        {d.is_active ? 'פעיל' : 'כבוי'}
                      </button>
                    </form>
                  </td>
                  <td className="px-4 py-3">
                    {d.userCount === 0 && (
                      <form
                        action={deleteAction}
                        onSubmit={(e) => { if (!confirm('למחוק מחלקה זו?')) e.preventDefault() }}
                      >
                        <input type="hidden" name="department_id" value={d.id} />
                        <button type="submit" className="text-xs text-red-600 hover:underline">
                          מחק
                        </button>
                      </form>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
