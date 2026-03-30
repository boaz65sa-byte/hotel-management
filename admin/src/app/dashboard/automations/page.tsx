'use client'
import { useEffect, useState } from 'react'
import Link from 'next/link'

interface Task {
  id: string; title: string; recurrence: string; assigned_role: string;
  next_run_at: string; is_active: boolean; hotels?: { name: string }
}

const RECURRENCE_HE: Record<string, string> = {
  daily: 'יומי', weekly: 'שבועי', monthly: 'חודשי', quarterly: 'רבעוני'
}

export default function AutomationsPage() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/automations')
      .then(r => r.json())
      .then(data => { setTasks(data); setLoading(false) })
  }, [])

  const toggleActive = async (id: string, is_active: boolean) => {
    await fetch(`/api/automations/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ is_active: !is_active }),
    })
    setTasks(tasks.map(t => t.id === id ? { ...t, is_active: !is_active } : t))
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
              <div className="flex justify-between items-start">
                <div>
                  <p className="font-semibold">{task.title}</p>
                  <p className="text-sm text-gray-500">
                    {RECURRENCE_HE[task.recurrence]} · {task.assigned_role} · {task.hotels?.name}
                  </p>
                  <p className="text-xs text-gray-400 mt-1">
                    הבא: {new Date(task.next_run_at).toLocaleDateString('he-IL')}
                  </p>
                </div>
                <button
                  onClick={() => toggleActive(task.id, task.is_active)}
                  className={`px-3 py-1 rounded-full text-xs font-medium ${
                    task.is_active
                      ? 'bg-green-100 text-green-800'
                      : 'bg-gray-100 text-gray-600'
                  }`}>
                  {task.is_active ? 'פעיל' : 'כבוי'}
                </button>
              </div>
            </div>
          ))}
          {tasks.length === 0 && <p className="text-gray-500">אין אוטומציות. צור אחת!</p>}
        </div>
      )}
    </div>
  )
}
