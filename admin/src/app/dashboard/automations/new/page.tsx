'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function NewAutomationPage() {
  const router = useRouter()
  const [form, setForm] = useState({
    hotel_id: '', title: '', recurrence: 'daily',
    assigned_role: 'maintenance', next_run_at: '',
  })
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    const res = await fetch('/api/automations', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form),
    })
    if (res.ok) {
      router.push('/dashboard/automations')
    } else {
      const data = await res.json()
      setError(data.error || 'שגיאה')
      setSaving(false)
    }
  }

  return (
    <div className="p-6 max-w-lg">
      <h1 className="text-2xl font-bold mb-6">אוטומציה חדשה</h1>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">Hotel ID</label>
          <input className="w-full border rounded px-3 py-2"
            value={form.hotel_id} onChange={e => setForm({...form, hotel_id: e.target.value})}
            required placeholder="UUID של המלון" />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">כותרת</label>
          <input className="w-full border rounded px-3 py-2"
            value={form.title} onChange={e => setForm({...form, title: e.target.value})}
            required placeholder="פילטר מיזוג חדר 201" />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">תדירות</label>
          <select className="w-full border rounded px-3 py-2"
            value={form.recurrence} onChange={e => setForm({...form, recurrence: e.target.value})}>
            <option value="daily">יומי</option>
            <option value="weekly">שבועי</option>
            <option value="monthly">חודשי</option>
            <option value="quarterly">רבעוני</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">מחלקה</label>
          <select className="w-full border rounded px-3 py-2"
            value={form.assigned_role} onChange={e => setForm({...form, assigned_role: e.target.value})}>
            <option value="maintenance">אחזקה</option>
            <option value="housekeeping">ניקיון</option>
            <option value="reception">קבלה</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">הרצה ראשונה</label>
          <input type="datetime-local" className="w-full border rounded px-3 py-2"
            value={form.next_run_at} onChange={e => setForm({...form, next_run_at: new Date(e.target.value).toISOString()})}
            required />
        </div>
        {error && <p className="text-red-600 text-sm">{error}</p>}
        <button type="submit" disabled={saving}
          className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50">
          {saving ? 'שומר...' : 'צור אוטומציה'}
        </button>
      </form>
    </div>
  )
}
