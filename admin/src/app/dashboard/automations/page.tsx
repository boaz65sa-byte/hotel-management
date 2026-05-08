'use client'
import { useCallback, useEffect, useState } from 'react'
import Link from 'next/link'

interface Task {
  id: string; title: string; recurrence: string; assigned_role: string;
  next_run_at: string; is_active: boolean; hotels?: { name: string }
}

const RECURRENCE_HE: Record<string, string> = {
  daily: 'יומי', weekly: 'שבועי', monthly: 'חודשי', quarterly: 'רבעוני'
}

const ROLE_OPTIONS = ['maintenance', 'housekeeping', 'reception']
const RECURRENCE_OPTIONS = ['daily', 'weekly', 'monthly', 'quarterly']

export default function AutomationsPage() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editForm, setEditForm] = useState<Partial<Task>>({})
  const [busyId, setBusyId] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    const res = await fetch('/api/automations')
    const data = await res.json()
    setTasks(Array.isArray(data) ? data : [])
    setLoading(false)
  }, [])

  useEffect(() => {
    let cancelled = false
    void (async () => {
      const res = await fetch('/api/automations')
      if (cancelled) return
      const data = await res.json()
      if (cancelled) return
      setTasks(Array.isArray(data) ? data : [])
      setLoading(false)
    })()
    return () => { cancelled = true }
  }, [])

  async function toggleActive(id: string, is_active: boolean) {
    setBusyId(id)
    await fetch(`/api/automations/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ is_active: !is_active }),
    })
    setTasks(tasks.map(t => t.id === id ? { ...t, is_active: !is_active } : t))
    setBusyId(null)
  }

  async function deleteTask(id: string) {
    if (!confirm('למחוק את האוטומציה לצמיתות?')) return
    setBusyId(id)
    const res = await fetch(`/api/automations/${id}`, { method: 'DELETE' })
    if (res.ok) {
      setTasks(tasks.filter(t => t.id !== id))
    }
    setBusyId(null)
  }

  function startEdit(task: Task) {
    setEditingId(task.id)
    setEditForm({
      title: task.title,
      recurrence: task.recurrence,
      assigned_role: task.assigned_role,
      next_run_at: task.next_run_at,
    })
  }

  async function saveEdit(id: string) {
    setBusyId(id)
    const payload: Record<string, unknown> = { ...editForm }
    if (typeof payload.next_run_at === 'string' && !payload.next_run_at.endsWith('Z')) {
      // datetime-local string → ISO
      const d = new Date(payload.next_run_at as string)
      if (!isNaN(d.getTime())) payload.next_run_at = d.toISOString()
    }
    const res = await fetch(`/api/automations/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
    if (res.ok) {
      setEditingId(null)
      await refresh()
    }
    setBusyId(null)
  }

  function toLocalInput(iso: string | undefined): string {
    if (!iso) return ''
    const d = new Date(iso)
    if (isNaN(d.getTime())) return ''
    const pad = (n: number) => String(n).padStart(2, '0')
    return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">אוטומציות</h1>
        <Link href="/dashboard/automations/new"
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          + אוטומציה חדשה
        </Link>
      </div>

      {loading ? <p>טוען...</p> : (
        <div className="grid gap-4">
          {tasks.map(task => (
            <div key={task.id} className="bg-white rounded-lg p-4 shadow">
              {editingId === task.id ? (
                <div className="space-y-3">
                  <input
                    className="w-full border rounded px-3 py-2"
                    value={editForm.title ?? ''}
                    onChange={e => setEditForm({...editForm, title: e.target.value})}
                  />
                  <div className="grid grid-cols-3 gap-3">
                    <select
                      className="border rounded px-3 py-2"
                      value={editForm.recurrence ?? 'daily'}
                      onChange={e => setEditForm({...editForm, recurrence: e.target.value})}
                    >
                      {RECURRENCE_OPTIONS.map(r => (
                        <option key={r} value={r}>{RECURRENCE_HE[r]}</option>
                      ))}
                    </select>
                    <select
                      className="border rounded px-3 py-2"
                      value={editForm.assigned_role ?? 'maintenance'}
                      onChange={e => setEditForm({...editForm, assigned_role: e.target.value})}
                    >
                      {ROLE_OPTIONS.map(r => (
                        <option key={r} value={r}>{r}</option>
                      ))}
                    </select>
                    <input
                      type="datetime-local"
                      className="border rounded px-3 py-2"
                      value={toLocalInput(editForm.next_run_at)}
                      onChange={e => setEditForm({...editForm, next_run_at: e.target.value})}
                    />
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => saveEdit(task.id)}
                      disabled={busyId === task.id}
                      className="bg-blue-600 text-white px-3 py-1 rounded text-sm hover:bg-blue-700 disabled:opacity-50"
                    >
                      שמור
                    </button>
                    <button
                      onClick={() => setEditingId(null)}
                      className="border px-3 py-1 rounded text-sm hover:bg-gray-50"
                    >
                      ביטול
                    </button>
                  </div>
                </div>
              ) : (
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <p className="font-semibold">{task.title}</p>
                    <p className="text-sm text-gray-500">
                      {RECURRENCE_HE[task.recurrence]} · {task.assigned_role} · {task.hotels?.name}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      הבא: {new Date(task.next_run_at).toLocaleDateString('he-IL')}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => toggleActive(task.id, task.is_active)}
                      disabled={busyId === task.id}
                      className={`px-3 py-1 rounded-full text-xs font-medium disabled:opacity-50 ${
                        task.is_active
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-600'
                      }`}>
                      {task.is_active ? 'פעיל' : 'כבוי'}
                    </button>
                    <button
                      onClick={() => startEdit(task)}
                      className="text-xs text-blue-600 hover:underline"
                    >
                      ערוך
                    </button>
                    <button
                      onClick={() => deleteTask(task.id)}
                      disabled={busyId === task.id}
                      className="text-xs text-red-600 hover:underline disabled:opacity-50"
                    >
                      מחק
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
          {tasks.length === 0 && <p className="text-gray-500">אין אוטומציות. צור אחת!</p>}
        </div>
      )}
    </div>
  )
}
