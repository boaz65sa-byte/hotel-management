'use client'
import { useState } from 'react'

type Category = {
  id: string
  key: string
  label: string
  icon: string
  is_system: boolean
  is_active: boolean
  sort_order: number
}

export function RequestCategoriesManager({
  categories,
  createAction,
  toggleAction,
  deleteAction,
}: {
  categories: Category[]
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
            + הוסף קטגוריה חדשה
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
              <input name="icon" defaultValue="📋" maxLength={4}
                className="w-20 border rounded px-3 py-2 text-sm text-center" />
            </div>
            <div className="flex-1 min-w-[200px]">
              <label className="block text-xs font-medium mb-1">שם הקטגוריה</label>
              <input name="label" placeholder="למשל: ספא, טניס, מיני בר"
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

      <div className="overflow-x-auto rounded-xl border">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="text-right px-4 py-3 font-semibold text-gray-600">קטגוריה</th>
              <th className="text-right px-4 py-3 font-semibold text-gray-600">סוג</th>
              <th className="text-right px-4 py-3 font-semibold text-gray-600">פעיל</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {categories.map(c => (
              <tr key={c.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{c.icon} {c.label}</td>
                <td className="px-4 py-3 text-gray-500">
                  {c.is_system ? 'מובנית' : 'מותאמת אישית'}
                </td>
                <td className="px-4 py-3">
                  <form action={toggleAction}>
                    <input type="hidden" name="category_id" value={c.id} />
                    <input type="hidden" name="next_active" value={(!c.is_active).toString()} />
                    <button
                      type="submit"
                      className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                        c.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                      }`}
                    >
                      {c.is_active ? 'פעיל' : 'כבוי'}
                    </button>
                  </form>
                </td>
                <td className="px-4 py-3">
                  {!c.is_system && (
                    <form
                      action={deleteAction}
                      onSubmit={(e) => { if (!confirm('למחוק קטגוריה זו?')) e.preventDefault() }}
                    >
                      <input type="hidden" name="category_id" value={c.id} />
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
    </div>
  )
}
