'use client'
import { useEffect, useState } from 'react'
import { useRouter, useParams } from 'next/navigation'

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

export default function EditUserPage() {
  const router = useRouter()
  const { id } = useParams<{ id: string }>()
  const [form, setForm] = useState({ full_name: '', role: '', hotel_id: '', is_active: true })
  const [hotels, setHotels] = useState<{ id: string; name: string }[]>([])
  const [loading, setLoading] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    Promise.all([
      fetch(`/api/users/${id}`).then(r => r.json()),
      fetch('/api/hotels').then(r => r.json()),
    ]).then(([user, hs]) => {
      setForm({ full_name: user.full_name, role: user.role, hotel_id: user.hotel_id ?? '', is_active: user.is_active })
      setHotels(hs)
    })
  }, [id])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const res = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'update', user_id: id, ...form }),
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

  async function handleDelete() {
    if (!confirm('Delete this user permanently?')) return
    setDeleting(true)
    try {
      const res = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'delete', user_id: id }),
      })
      if (!res.ok) throw new Error('Delete failed')
      router.push('/dashboard/users')
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error')
      setDeleting(false)
    }
  }

  return (
    <div className="max-w-lg">
      <h1 className="text-2xl font-bold mb-6">Edit User</h1>
      <form onSubmit={handleSubmit} className="space-y-4 bg-white p-6 rounded-xl border">
        <div>
          <label className="block text-sm font-medium mb-1">Full Name</label>
          <input className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.full_name} onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))} />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Role</label>
          <select className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value }))}>
            {ROLES.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Hotel</label>
          <select className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.hotel_id} onChange={e => setForm(f => ({ ...f, hotel_id: e.target.value }))}>
            <option value="">No hotel (Super Admin)</option>
            {hotels.map(h => <option key={h.id} value={h.id}>{h.name}</option>)}
          </select>
        </div>
        <div className="flex items-center gap-2">
          <input type="checkbox" id="active" checked={form.is_active}
            onChange={e => setForm(f => ({ ...f, is_active: e.target.checked }))} />
          <label htmlFor="active" className="text-sm font-medium">Active</label>
        </div>
        {error && <p className="text-red-600 text-sm">{error}</p>}
        <div className="flex gap-3 pt-2">
          <button type="submit" disabled={loading}
            className="bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700 disabled:opacity-50">
            {loading ? 'Saving...' : 'Save Changes'}
          </button>
          <button type="button" onClick={() => router.back()}
            className="border px-4 py-2 rounded-lg text-sm hover:bg-gray-50">
            Cancel
          </button>
          <button type="button" onClick={handleDelete} disabled={deleting}
            className="ml-auto text-red-600 border border-red-200 px-4 py-2 rounded-lg text-sm hover:bg-red-50 disabled:opacity-50">
            {deleting ? 'Deleting...' : 'Delete User'}
          </button>
        </div>
      </form>
    </div>
  )
}
