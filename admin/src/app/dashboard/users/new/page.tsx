'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'

const ROLES = [
  { value: 'ceo',                  label: 'CEO' },
  { value: 'reception_manager',    label: 'Reception Manager' },
  { value: 'maintenance_manager',  label: 'Maintenance Manager' },
  { value: 'housekeeping_manager', label: 'Housekeeping Manager' },
  { value: 'security_manager',     label: 'Security Manager' },
  { value: 'deputy_reception',     label: 'Deputy Reception' },
  { value: 'receptionist',         label: 'Receptionist' },
  { value: 'security_guard',       label: 'Security Guard' },
  { value: 'maintenance_tech',     label: 'Maintenance Tech' },
  { value: 'repairman',            label: 'Repairman' },
]

export default function NewUserPage() {
  const router = useRouter()
  const [form, setForm] = useState({ full_name: '', email: '', password: '', role: 'receptionist', hotel_id: '' })
  const [hotels, setHotels] = useState<{ id: string; name: string }[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  // Load hotels on mount
  useState(() => {
    fetch('/api/hotels').then(r => r.json()).then(setHotels)
  })

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const res = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'create', ...form }),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error)
      router.push('/dashboard/users')
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-lg">
      <h1 className="text-2xl font-bold mb-6">Create User</h1>
      <form onSubmit={handleSubmit} className="space-y-4 bg-white p-6 rounded-xl border">
        <div>
          <label className="block text-sm font-medium mb-1">Full Name *</label>
          <input required className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.full_name} onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))} />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Email *</label>
          <input required type="email" className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Password *</label>
          <input required type="password" minLength={8} className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
            placeholder="Min 8 characters" />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Role *</label>
          <select required className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value }))}>
            {ROLES.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Hotel *</label>
          <select required className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.hotel_id} onChange={e => setForm(f => ({ ...f, hotel_id: e.target.value }))}>
            <option value="">Select hotel...</option>
            {hotels.map(h => <option key={h.id} value={h.id}>{h.name}</option>)}
          </select>
        </div>
        {error && <p className="text-red-600 text-sm">{error}</p>}
        <div className="flex gap-3 pt-2">
          <button type="submit" disabled={loading}
            className="bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700 disabled:opacity-50">
            {loading ? 'Creating...' : 'Create User'}
          </button>
          <button type="button" onClick={() => router.back()}
            className="border px-4 py-2 rounded-lg text-sm hover:bg-gray-50">
            Cancel
          </button>
        </div>
      </form>
    </div>
  )
}
