'use client'

import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'

interface Item {
  id: string
  order_index: number
  title_he: string
  title_en: string | null
  requires_photo: boolean
}

interface Template {
  id: string
  name: string
  type: string
  is_vip: boolean
}

export default function ChecklistTemplateDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [template, setTemplate] = useState<Template | null>(null)
  const [items, setItems] = useState<Item[]>([])
  const [loading, setLoading] = useState(true)
  const [newItem, setNewItem] = useState({ title_he: '', title_en: '', requires_photo: false })
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editForm, setEditForm] = useState<Partial<Item>>({})
  const [busyId, setBusyId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    if (!id) return
    const res = await fetch(`/api/checklists/${id}`)
    if (res.ok) {
      const data = await res.json()
      setTemplate(data.template)
      setItems(data.items ?? [])
    } else {
      setError('שגיאה בטעינת התבנית')
    }
    setLoading(false)
  }, [id])

  useEffect(() => {
    if (!id) return
    let cancelled = false
    void (async () => {
      const res = await fetch(`/api/checklists/${id}`)
      if (cancelled) return
      if (res.ok) {
        const data = await res.json()
        if (cancelled) return
        setTemplate(data.template)
        setItems(data.items ?? [])
      } else {
        setError('שגיאה בטעינת התבנית')
      }
      setLoading(false)
    })()
    return () => { cancelled = true }
  }, [id])

  async function addItem(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    if (!newItem.title_he.trim()) return
    const res = await fetch(`/api/checklists/${id}/items`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title_he: newItem.title_he.trim(),
        title_en: newItem.title_en.trim() || null,
        requires_photo: newItem.requires_photo,
      }),
    })
    if (res.ok) {
      setNewItem({ title_he: '', title_en: '', requires_photo: false })
      await refresh()
    } else {
      const d = await res.json()
      setError(d.error ?? 'Failed')
    }
  }

  async function saveItemEdit(itemId: string) {
    setBusyId(itemId)
    const res = await fetch(`/api/checklists/${id}/items/${itemId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(editForm),
    })
    if (res.ok) {
      setEditingId(null)
      await refresh()
    }
    setBusyId(null)
  }

  async function deleteItem(itemId: string) {
    if (!confirm('למחוק את הפריט?')) return
    setBusyId(itemId)
    const res = await fetch(`/api/checklists/${id}/items/${itemId}`, { method: 'DELETE' })
    if (res.ok) await refresh()
    setBusyId(null)
  }

  async function moveItem(itemId: string, direction: -1 | 1) {
    const idx = items.findIndex(i => i.id === itemId)
    const swapIdx = idx + direction
    if (idx < 0 || swapIdx < 0 || swapIdx >= items.length) return
    const a = items[idx]
    const b = items[swapIdx]
    setBusyId(itemId)
    await Promise.all([
      fetch(`/api/checklists/${id}/items/${a.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ order_index: b.order_index }),
      }),
      fetch(`/api/checklists/${id}/items/${b.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ order_index: a.order_index }),
      }),
    ])
    await refresh()
    setBusyId(null)
  }

  if (loading) return <div className="p-6">טוען...</div>
  if (!template) return <div className="p-6">תבנית לא נמצאה</div>

  return (
    <div className="p-6" dir="rtl">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">{template.name}</h1>
          <p className="text-sm text-gray-500 mt-1">
            {template.type === 'housekeeping' ? 'ניקיון' : 'אחזקה'}
            {template.is_vip && ' · VIP'}
            {' · '}{items.length} פריטים
          </p>
        </div>
        <Link href="/dashboard/checklists" className="text-sm text-blue-600 hover:underline">
          ← חזרה לתבניות
        </Link>
      </div>

      {/* Add item */}
      <form
        onSubmit={addItem}
        className="bg-white border rounded-xl p-4 mb-6 grid grid-cols-1 md:grid-cols-4 gap-3 items-end"
      >
        <div>
          <label className="block text-xs font-medium mb-1">פריט (עברית) *</label>
          <input
            value={newItem.title_he}
            onChange={e => setNewItem({...newItem, title_he: e.target.value})}
            required
            className="w-full border rounded px-3 py-2 text-sm"
            placeholder="בדיקת מיזוג"
          />
        </div>
        <div>
          <label className="block text-xs font-medium mb-1">English (optional)</label>
          <input
            value={newItem.title_en}
            onChange={e => setNewItem({...newItem, title_en: e.target.value})}
            className="w-full border rounded px-3 py-2 text-sm"
            placeholder="Check AC"
          />
        </div>
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={newItem.requires_photo}
            onChange={e => setNewItem({...newItem, requires_photo: e.target.checked})}
          />
          דרוש צילום
        </label>
        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">
          + הוסף פריט
        </button>
        {error && <p className="text-red-600 text-sm md:col-span-4">{error}</p>}
      </form>

      {/* Items list */}
      <div className="bg-white rounded-xl border overflow-hidden">
        {items.length === 0 ? (
          <p className="text-gray-500 text-center py-12">אין פריטים. הוסיפו את הראשון למעלה.</p>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-right px-4 py-3 font-semibold text-gray-600 w-16">סדר</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">פריט (עברית)</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">English</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600 w-32">צילום</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">פעולות</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {items.map((item, idx) => (
                editingId === item.id ? (
                  <tr key={item.id} className="bg-blue-50/30">
                    <td colSpan={5} className="px-4 py-3">
                      <div className="grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
                        <input
                          value={editForm.title_he ?? ''}
                          onChange={e => setEditForm({...editForm, title_he: e.target.value})}
                          className="border rounded px-3 py-2 text-sm"
                          placeholder="עברית"
                        />
                        <input
                          value={editForm.title_en ?? ''}
                          onChange={e => setEditForm({...editForm, title_en: e.target.value})}
                          className="border rounded px-3 py-2 text-sm"
                          placeholder="English"
                        />
                        <label className="flex items-center gap-2 text-sm">
                          <input
                            type="checkbox"
                            checked={editForm.requires_photo ?? false}
                            onChange={e => setEditForm({...editForm, requires_photo: e.target.checked})}
                          />
                          דרוש צילום
                        </label>
                        <div className="flex gap-2">
                          <button
                            onClick={() => saveItemEdit(item.id)}
                            disabled={busyId === item.id}
                            className="bg-blue-600 text-white px-3 py-2 rounded text-sm hover:bg-blue-700 disabled:opacity-50"
                          >
                            שמור
                          </button>
                          <button
                            onClick={() => setEditingId(null)}
                            className="border px-3 py-2 rounded text-sm hover:bg-white"
                          >
                            ביטול
                          </button>
                        </div>
                      </div>
                    </td>
                  </tr>
                ) : (
                  <tr key={item.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-500">
                      <div className="flex items-center gap-1">
                        <button
                          type="button"
                          onClick={() => moveItem(item.id, -1)}
                          disabled={idx === 0 || busyId === item.id}
                          className="text-gray-400 hover:text-gray-700 disabled:opacity-30"
                          title="הזז למעלה"
                        >▲</button>
                        <button
                          type="button"
                          onClick={() => moveItem(item.id, 1)}
                          disabled={idx === items.length - 1 || busyId === item.id}
                          className="text-gray-400 hover:text-gray-700 disabled:opacity-30"
                          title="הזז למטה"
                        >▼</button>
                        <span className="text-xs ml-1">{item.order_index}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 font-medium">{item.title_he}</td>
                    <td className="px-4 py-3 text-gray-600">{item.title_en ?? '—'}</td>
                    <td className="px-4 py-3">
                      {item.requires_photo
                        ? <span className="bg-orange-100 text-orange-700 text-xs px-2 py-0.5 rounded-full">📷 דרוש</span>
                        : <span className="text-gray-400">—</span>}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <button
                          type="button"
                          onClick={() => {
                            setEditingId(item.id)
                            setEditForm({
                              title_he: item.title_he,
                              title_en: item.title_en,
                              requires_photo: item.requires_photo,
                            })
                          }}
                          className="text-xs text-blue-600 hover:underline"
                        >ערוך</button>
                        <button
                          type="button"
                          onClick={() => deleteItem(item.id)}
                          disabled={busyId === item.id}
                          className="text-xs text-red-600 hover:underline disabled:opacity-50"
                        >מחק</button>
                      </div>
                    </td>
                  </tr>
                )
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
