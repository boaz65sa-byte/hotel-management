'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { useParams, useRouter } from 'next/navigation'

import { ROLES } from '@/lib/roles'

export default function EditUserClient({
  isSuperAdmin,
  lockedHotelId,
}: {
  isSuperAdmin: boolean
  lockedHotelId?: string | null
}) {
  const router = useRouter()
  const { id } = useParams<{ id: string }>()
  const [form, setForm] = useState({ full_name: '', role: '', hotel_id: '', department_id: '', is_active: true })
  const [hotels, setHotels] = useState<{ id: string; name: string }[]>([])
  const [departments, setDepartments] = useState<{ id: string; key: string; label: string; icon: string }[]>([])
  const [loading, setLoading] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [error, setError] = useState('')
  const [forbidden, setForbidden] = useState(false)
  const [loadError, setLoadError] = useState(false)
  const [showPasswordField, setShowPasswordField] = useState(false)
  const [newPassword, setNewPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)

  useEffect(() => {
    Promise.all([
      fetch(`/api/users/${id}`),
      fetch('/api/hotels'),
    ]).then(async ([userRes, hotelRes]) => {
      const hsRaw = await hotelRes.json().catch(() => [])
      const hotelsList = Array.isArray(hsRaw) ? hsRaw : []
      setHotels(hotelsList)

      if (userRes.status === 403) {
        setForbidden(true)
        return
      }
      if (!userRes.ok) {
        setLoadError(true)
        return
      }
      const user = await userRes.json().catch(() => null)
      if (!user?.id) {
        setLoadError(true)
        return
      }
      setForm({
        full_name: user.full_name ?? '',
        role: user.role ?? '',
        hotel_id: user.hotel_id ?? '',
        department_id: user.department_id ?? '',
        is_active: Boolean(user.is_active),
      })
    })
  }, [id])

  const isCustomDeptRole = form.role === 'custom_dept_manager' || form.role === 'custom_dept_staff'

  useEffect(() => {
    if (!isCustomDeptRole || !form.hotel_id) {
      setDepartments([])
      return
    }
    fetch(`/api/hotel-departments?hotel_id=${form.hotel_id}`)
      .then((r) => r.json())
      .then((data) => setDepartments(Array.isArray(data) ? data : []))
      .catch(() => setDepartments([]))
  }, [isCustomDeptRole, form.hotel_id])

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')

    if (showPasswordField && newPassword.length > 0 && newPassword.length < 8) {
      setError('הסיסמה חייבת להכיל לפחות 8 תווים')
      return
    }

    setLoading(true)
    try {
      if (isCustomDeptRole && !form.department_id) {
        setError('בחרו מחלקה מותאמת')
        setLoading(false)
        return
      }

      const payload: Record<string, unknown> = {
        action: 'update',
        user_id: id,
        full_name: form.full_name,
        role: form.role,
        department_id: isCustomDeptRole ? form.department_id : null,
        is_active: form.is_active,
      }
      if (isSuperAdmin) payload.hotel_id = form.hotel_id
      if (showPasswordField && newPassword.length > 0) payload.password = newPassword
      const res = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error ?? 'Error')
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

  if (forbidden) {
    return (
      <div className="max-w-lg p-6">
        <p className="text-red-700">אין לכם הרשאה לצפות במשתמש זה.</p>
        <Link href="/dashboard/users" className="text-blue-600 text-sm mt-4 inline-block">
          חזרה לרשימה
        </Link>
      </div>
    )
  }

  if (loadError) {
    return (
      <div className="max-w-lg p-6">
        <p className="text-gray-700">משתמש לא נמצא או טעינה נכשלה.</p>
        <Link href="/dashboard/users" className="text-blue-600 text-sm mt-4 inline-block">
          חזרה לרשימה
        </Link>
      </div>
    )
  }

  const hotelLocked = !!(lockedHotelId || !isSuperAdmin)

  return (
    <div className="max-w-lg">
      <h1 className="text-2xl font-bold mb-6">Edit User</h1>
      <form onSubmit={handleSubmit} className="space-y-4 bg-white p-6 rounded-xl border">
        <div>
          <label className="block text-sm font-medium mb-1">Full Name</label>
          <input className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.full_name}
            onChange={(e) => setForm((f) => ({ ...f, full_name: e.target.value }))}
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Role</label>
          <select className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.role}
            onChange={(e) => setForm((f) => ({ ...f, role: e.target.value }))}>
            {!isSuperAdmin && form.role === 'super_admin' && (
              <option value="super_admin">סופר אדמין</option>
            )}
            {isSuperAdmin && <option value="super_admin">super_admin</option>}
            {ROLES.map(r => (
              <option key={r.value} value={r.value}>{r.label}</option>
            ))}
          </select>
        </div>
        {isCustomDeptRole && (
          <div>
            <label className="block text-sm font-medium mb-1">מחלקה מותאמת</label>
            <select className="w-full border rounded-lg px-3 py-2 text-sm bg-white"
              value={form.department_id}
              onChange={(e) => setForm((f) => ({ ...f, department_id: e.target.value }))}>
              <option value="">בחרו מחלקה…</option>
              {departments.map((d) => (
                <option key={d.id} value={d.id}>{d.icon} {d.label}</option>
              ))}
            </select>
          </div>
        )}
        <div>
          <label className="block text-sm font-medium mb-1">Hotel</label>
          <select
            className="w-full border rounded-lg px-3 py-2 text-sm bg-white disabled:bg-gray-100"
            disabled={hotelLocked}
            value={form.hotel_id}
            onChange={(e) => setForm((f) => ({ ...f, hotel_id: e.target.value }))}>
            {isSuperAdmin && (
              <option value="">No hotel (Super Admin)</option>
            )}
            {hotels.map(h => (
              <option key={h.id} value={h.id}>{h.name}</option>
            ))}
          </select>
        </div>
        <div className="flex items-center gap-2">
          <input type="checkbox" id="active" checked={form.is_active}
            onChange={(e) => setForm((f) => ({ ...f, is_active: e.target.checked }))} />
          <label htmlFor="active" className="text-sm font-medium">Active</label>
        </div>

        <div className="border-t pt-4">
          {!showPasswordField ? (
            <button
              type="button"
              onClick={() => setShowPasswordField(true)}
              className="text-sm text-blue-600 hover:underline"
            >
              🔑 איפוס סיסמה
            </button>
          ) : (
            <div>
              <label className="block text-sm font-medium mb-1">סיסמה חדשה</label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  className="w-full border rounded-lg px-3 py-2 text-sm pr-16"
                  placeholder="לפחות 8 תווים"
                  minLength={8}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  autoComplete="new-password"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  className="absolute inset-y-0 left-2 text-xs text-gray-500 hover:text-gray-800"
                >
                  {showPassword ? 'הסתר' : 'הצג'}
                </button>
              </div>
              <button
                type="button"
                onClick={() => { setShowPasswordField(false); setNewPassword('') }}
                className="text-xs text-gray-500 hover:underline mt-1"
              >
                ביטול
              </button>
              <p className="text-xs text-gray-500 mt-1">
                המשתמש ייכנס עם הסיסמה החדשה בפעם הבאה. השדה נשאר ריק — לא משנים סיסמה אלא אם ממלאים כאן.
              </p>
            </div>
          )}
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
          {isSuperAdmin && (
            <button type="button" onClick={() => void handleDelete()} disabled={deleting}
              className="ml-auto text-red-600 border border-red-200 px-4 py-2 rounded-lg text-sm hover:bg-red-50 disabled:opacity-50">
              {deleting ? 'Deleting...' : 'Delete User'}
            </button>
          )}
        </div>
      </form>
    </div>
  )
}
