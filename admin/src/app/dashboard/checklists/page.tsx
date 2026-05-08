'use client'
import { useCallback, useEffect, useState } from 'react'
import Link from 'next/link'

interface Template {
  id: string
  name: string
  type: string
  is_vip: boolean
  checklist_items?: { count: number }[] | { count: number }
}

const TYPE_OPTIONS = [
  { value: 'housekeeping', label: 'ניקיון' },
  { value: 'maintenance',  label: 'אחזקה' },
]

function itemCount(t: Template): number {
  if (!t.checklist_items) return 0
  if (Array.isArray(t.checklist_items)) return t.checklist_items[0]?.count ?? 0
  return t.checklist_items.count ?? 0
}

export default function ChecklistsPage() {
  const [templates, setTemplates] = useState<Template[]>([])
  const [loading, setLoading] = useState(true)
  const [creating, setCreating] = useState(false)
  const [form, setForm] = useState({ name: '', type: 'housekeeping', is_vip: false })
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editForm, setEditForm] = useState<Partial<Template>>({})
  const [busyId, setBusyId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    const res = await fetch('/api/checklists')
    const data = await res.json()
    setTemplates(Array.isArray(data) ? data : [])
    setLoading(false)
  }, [])

  useEffect(() => {
    let cancelled = false
    void (async () => {
      const res = await fetch('/api/checklists')
      if (cancelled) return
      const data = await res.json()
      if (cancelled) return
      setTemplates(Array.isArray(data) ? data : [])
      setLoading(false)
    })()
    return () => { cancelled = true }
  }, [])

  async function createTemplate(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    const res = await fetch('/api/checklists', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form),
    })
    if (res.ok) {
      setForm({ name: '', type: 'housekeeping', is_vip: false })
      setCreating(false)
      await refresh()
    } else {
      const d = await res.json()
      setError(d.error ?? 'Failed to create')
    }
  }

  async function saveEdit(id: string) {
    setBusyId(id)
    const res = await fetch(`/api/checklists/${id}`, {
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

  async function deleteTemplate(id: string) {
    if (!confirm('למחוק את התבנית? כל הפריטים שלה יימחקו גם.')) return
    setBusyId(id)
    const res = await fetch(`/api/checklists/${id}`, { method: 'DELETE' })
    if (res.ok) await refresh()
    setBusyId(null)
  }

  return (
    <div className="p-6" dir="rtl">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">תבניות צ׳קליסט</h1>
        <button
          onClick={() => setCreating(c => !c)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
        >
          {creating ? 'ביטול' : '+ תבנית חדשה'}
        </button>
      </div>

      {creating && (
        <form
          onSubmit={createTemplate}
          className="bg-white border rounded-xl p-4 mb-6 grid grid-cols-1 md:grid-cols-4 gap-3 items-end"
        >
          <div>
            <label className="block text-xs font-medium mb-1">שם התבנית *</label>
            <input
              required
              value={form.name}
              onChange={e => setForm({...form, name: e.target.value})}
              className="w-full border rounded px-3 py-2 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs font-medium mb-1">סוג</label>
            <select
              value={form.type}
              onChange={e => setForm({...form, type: e.target.value})}
              className="w-full border rounded px-3 py-2 text-sm"
            >
              {TYPE_OPTIONS.map(o => (
                <option key={o.value} value={o.value}>{o.label}</option>
              ))}
            </select>
          </div>
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={form.is_vip}
              onChange={e => setForm({...form, is_vip: e.target.checked})}
            />
            VIP
          </label>
          <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">
            צור
          </button>
          {error && <p className="text-red-600 text-sm md:col-span-4">{error}</p>}
        </form>
      )}

      {loading ? (
        <p>טוען...</p>
      ) : (
        <div className="grid gap-4">
          {templates.map(t => (
            <div key={t.id} className="bg-white rounded-lg p-4 shadow">
              {editingId === t.id ? (
                <div className="grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
                  <input
                    value={editForm.name ?? ''}
                    onChange={e => setEditForm({...editForm, name: e.target.value})}
                    className="border rounded px-3 py-2 text-sm"
                  />
                  <select
                    value={editForm.type ?? 'housekeeping'}
                    onChange={e => setEditForm({...editForm, type: e.target.value})}
                    className="border rounded px-3 py-2 text-sm"
                  >
                    {TYPE_OPTIONS.map(o => (
                      <option key={o.value} value={o.value}>{o.label}</option>
                    ))}
                  </select>
                  <label className="flex items-center gap-2 text-sm">
                    <input
                      type="checkbox"
                      checked={editForm.is_vip ?? false}
                      onChange={e => setEditForm({...editForm, is_vip: e.target.checked})}
                    />
                    VIP
                  </label>
                  <div className="flex gap-2">
                    <button
                      onClick={() => saveEdit(t.id)}
                      disabled={busyId === t.id}
                      className="bg-blue-600 text-white px-3 py-2 rounded text-sm hover:bg-blue-700 disabled:opacity-50"
                    >
                      שמור
                    </button>
                    <button
                      onClick={() => setEditingId(null)}
                      className="border px-3 py-2 rounded text-sm hover:bg-gray-50"
                    >
                      ביטול
                    </button>
                  </div>
                </div>
              ) : (
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-semibold">{t.name}</p>
                    <p className="text-sm text-gray-500">
                      {t.type === 'housekeeping' ? 'ניקיון' : 'אחזקה'}
                      {t.is_vip && ' · VIP'}
                      {' · '}{itemCount(t)} פריטים
                    </p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      t.type === 'housekeeping'
                        ? 'bg-yellow-100 text-yellow-800'
                        : 'bg-blue-100 text-blue-800'
                    }`}>
                      {t.type}
                    </span>
                    <Link
                      href={`/dashboard/checklists/${t.id}`}
                      className="text-xs text-blue-600 hover:underline"
                    >
                      פריטים
                    </Link>
                    <button
                      onClick={() => {
                        setEditingId(t.id)
                        setEditForm({ name: t.name, type: t.type, is_vip: t.is_vip })
                      }}
                      className="text-xs text-blue-600 hover:underline"
                    >
                      ערוך
                    </button>
                    <button
                      onClick={() => deleteTemplate(t.id)}
                      disabled={busyId === t.id}
                      className="text-xs text-red-600 hover:underline disabled:opacity-50"
                    >
                      מחק
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
          {templates.length === 0 && <p className="text-gray-500">אין תבניות. צרו אחת!</p>}
        </div>
      )}
    </div>
  )
}
