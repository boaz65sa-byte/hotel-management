'use client'

import { useEffect, useMemo, useState } from 'react'
import { useRouter } from 'next/navigation'

import { ROLES, type Role } from '@/lib/roles'

type Hotel = { id: string; name: string }

const TIER_HEADERS: Record<Role['tier'], string> = {
  super_admin:  '🟣 פלטפורמה',
  hotel_admin:  '🟦 ניהול המלון (גישה מלאה למלון אחד)',
  dept_manager: '🟢 מנהלי מחלקות',
  staff:        '⚪ צוות מבצעי',
}

export default function NewUserClient({ lockedHotelId }: { lockedHotelId?: string | null }) {
  const router = useRouter()
  const [form, setForm] = useState({
    full_name: '',
    email: '',
    password: '',
    role: 'ceo',
    hotel_id: lockedHotelId ?? '',
  })
  const [hotels, setHotels] = useState<Hotel[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (lockedHotelId) {
      setForm((f) => ({ ...f, hotel_id: lockedHotelId }))
    }
  }, [lockedHotelId])

  useEffect(() => {
    fetch('/api/hotels')
      .then((r) => r.json())
      .then((data) => setHotels(Array.isArray(data) ? data : []))
      .catch(() => setHotels([]))
  }, [])

  const grouped = useMemo(() => {
    const m = new Map<Role['tier'], Role[]>()
    for (const r of ROLES) {
      if (!m.has(r.tier)) m.set(r.tier, [])
      m.get(r.tier)!.push(r)
    }
    return m
  }, [])

  const currentRole = ROLES.find(r => r.value === form.role)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const hotel_id = lockedHotelId ?? form.hotel_id.trim()
    if (!hotel_id) {
      setError('בחרו מלון')
      return
    }
    setLoading(true)
    setError('')
    try {
      const res = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'create', ...form, hotel_id }),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error ?? 'שגיאה')
      router.push('/dashboard/users')
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl" dir="rtl">
      <h1 className="text-2xl font-bold mb-2">הוספת משתמש חדש</h1>
      <p className="text-sm text-gray-500 mb-6">
        {lockedHotelId
          ? 'יצירת משתמשים עבור המלון המקושר לחשבונכם.'
          : 'כאן יוצרים מנכל / מנהל תוכנה / מנהלי מחלקות / צוות עבור מלון ספציפי. סופר אדמין נוצר ב-SQL בלבד.'}
      </p>

      <form onSubmit={handleSubmit} className="space-y-5 bg-white p-6 rounded-xl border">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">שם מלא *</label>
            <input required className="w-full border rounded-lg px-3 py-2 text-sm"
              value={form.full_name}
              onChange={(e) => setForm((f) => ({ ...f, full_name: e.target.value }))}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">מייל *</label>
            <input required type="email" dir="ltr"
              className="w-full border rounded-lg px-3 py-2 text-sm"
              value={form.email}
              onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">סיסמה ראשונית *</label>
          <input required type="password" minLength={8}
            className="w-full border rounded-lg px-3 py-2 text-sm"
            value={form.password}
            onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
            placeholder="לפחות 8 תווים"
          />
          <p className="text-xs text-gray-400 mt-1">
            המשתמש יוכל לשנות לאחר ההתחברות הראשונה.
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">תפקיד *</label>
          <select required className="w-full border rounded-lg px-3 py-2 text-sm bg-white"
            value={form.role}
            onChange={(e) => setForm((f) => ({ ...f, role: e.target.value }))}>
            {(['hotel_admin','dept_manager','staff'] as Role['tier'][]).map((tier) => (
              <optgroup key={tier} label={TIER_HEADERS[tier]}>
                {(grouped.get(tier) ?? []).map((r) => (
                  <option key={r.value} value={r.value}>
                    {r.icon} {r.label}
                  </option>
                ))}
              </optgroup>
            ))}
          </select>
          {currentRole?.description && (
            <p className="text-xs text-gray-500 mt-1">{currentRole.description}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">מלון *</label>
          <select
            required
            disabled={!!lockedHotelId}
            className="w-full border rounded-lg px-3 py-2 text-sm bg-white disabled:bg-gray-100"
            value={form.hotel_id}
            onChange={(e) => setForm((f) => ({ ...f, hotel_id: e.target.value }))}>
            {!lockedHotelId && <option value="">בחרו מלון…</option>}
            {hotels.map(h => (
              <option key={h.id} value={h.id}>{h.name}</option>
            ))}
          </select>
          <p className="text-xs text-gray-500 mt-1">
            המשתמש יראה רק נתונים של המלון הזה.
          </p>
        </div>

        {error && <p className="text-red-600 text-sm">{error}</p>}

        <div className="flex gap-3 pt-2 border-t">
          <button type="submit" disabled={loading}
            className="bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700 disabled:opacity-50">
            {loading ? 'יוצר…' : 'צור משתמש'}
          </button>
          <button type="button" onClick={() => router.back()}
            className="border px-4 py-2 rounded-lg text-sm hover:bg-gray-50">
            ביטול
          </button>
        </div>
      </form>
    </div>
  )
}
