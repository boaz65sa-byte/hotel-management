'use client'
import { useCallback, useEffect, useState } from 'react'

interface License {
  id: string
  serial_code: string
  plan: 'basic' | 'pro' | 'enterprise'
  status: 'unused' | 'active' | 'revoked'
  issued_at: string
  activated_at: string | null
  notes: string | null
  hotels?: { name: string } | null
}

const STATUS_LABEL: Record<License['status'], string> = {
  unused: 'לא נוצל',
  active: 'פעיל',
  revoked: 'בוטל',
}

const STATUS_COLOR: Record<License['status'], string> = {
  unused: 'bg-gray-100 text-gray-700',
  active: 'bg-green-100 text-green-700',
  revoked: 'bg-red-100 text-red-700',
}

function LicensesPage() {
  const [licenses, setLicenses] = useState<License[]>([])
  const [loading, setLoading] = useState(true)
  const [generating, setGenerating] = useState(false)
  const [plan, setPlan] = useState<License['plan']>('basic')
  const [notes, setNotes] = useState('')
  const [justGenerated, setJustGenerated] = useState<string | null>(null)
  const [busyId, setBusyId] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    const res = await fetch('/api/licenses')
    const data = await res.json()
    setLicenses(Array.isArray(data) ? data : [])
    setLoading(false)
  }, [])

  useEffect(() => {
    let cancelled = false
    void (async () => {
      const res = await fetch('/api/licenses')
      if (cancelled) return
      const data = await res.json()
      if (cancelled) return
      setLicenses(Array.isArray(data) ? data : [])
      setLoading(false)
    })()
    return () => { cancelled = true }
  }, [])

  async function generate() {
    setGenerating(true)
    setJustGenerated(null)
    const res = await fetch('/api/licenses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ plan, notes }),
    })
    if (res.ok) {
      const created: License = await res.json()
      setJustGenerated(created.serial_code)
      setNotes('')
      await refresh()
    }
    setGenerating(false)
  }

  async function revoke(id: string) {
    if (!confirm('לבטל את קוד הרישיון הזה? לא ניתן לשחזר.')) return
    setBusyId(id)
    const res = await fetch(`/api/licenses/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'revoked' }),
    })
    if (res.ok) await refresh()
    setBusyId(null)
  }

  async function copy(code: string) {
    try { await navigator.clipboard.writeText(code) } catch { /* clipboard unavailable, ignore */ }
  }

  return (
    <div className="space-y-6" dir="rtl">
      <h1 className="text-xl font-bold text-gray-800">רישיונות מלונות</h1>

      <div className="bg-white rounded-xl border p-6 space-y-4">
        <h2 className="text-sm font-semibold text-gray-700">יצירת קוד רישיון חדש</h2>
        <div className="flex flex-wrap items-end gap-4">
          <div>
            <label className="block text-xs font-medium mb-1">מסלול</label>
            <select
              value={plan}
              onChange={e => setPlan(e.target.value as License['plan'])}
              className="border rounded px-3 py-2 text-sm"
            >
              <option value="basic">Basic</option>
              <option value="pro">Pro</option>
              <option value="enterprise">Enterprise</option>
            </select>
          </div>
          <div className="flex-1 min-w-[200px]">
            <label className="block text-xs font-medium mb-1">הערה (למי זה, וכו׳)</label>
            <input
              value={notes}
              onChange={e => setNotes(e.target.value)}
              className="w-full border rounded px-3 py-2 text-sm"
              placeholder="לדוג׳: מלון דן תל אביב"
            />
          </div>
          <button
            type="button"
            onClick={generate}
            disabled={generating}
            className="bg-blue-600 text-white px-5 py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 text-sm font-semibold"
          >
            {generating ? 'יוצר...' : '+ צור קוד'}
          </button>
        </div>

        {justGenerated && (
          <div className="flex items-center gap-3 bg-green-50 border border-green-300 rounded-lg px-4 py-3">
            <span className="text-green-700 text-sm">נוצר:</span>
            <code className="font-mono text-sm font-bold tracking-wider">{justGenerated}</code>
            <button
              type="button"
              onClick={() => copy(justGenerated)}
              className="text-xs text-blue-600 underline"
            >
              העתק
            </button>
          </div>
        )}
      </div>

      <div className="bg-white rounded-xl border overflow-hidden">
        {loading ? (
          <div className="p-6 text-sm text-gray-500">טוען...</div>
        ) : licenses.length === 0 ? (
          <div className="p-6 text-sm text-gray-500">אין עדיין קודי רישיון.</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-600 text-xs">
              <tr>
                <th className="text-right px-4 py-2 font-medium">קוד</th>
                <th className="text-right px-4 py-2 font-medium">מסלול</th>
                <th className="text-right px-4 py-2 font-medium">סטטוס</th>
                <th className="text-right px-4 py-2 font-medium">מלון</th>
                <th className="text-right px-4 py-2 font-medium">נוצר</th>
                <th className="text-right px-4 py-2 font-medium">הערה</th>
                <th className="px-4 py-2"></th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {licenses.map(l => (
                <tr key={l.id}>
                  <td className="px-4 py-2 font-mono tracking-wider">{l.serial_code}</td>
                  <td className="px-4 py-2 capitalize">{l.plan}</td>
                  <td className="px-4 py-2">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${STATUS_COLOR[l.status]}`}>
                      {STATUS_LABEL[l.status]}
                    </span>
                  </td>
                  <td className="px-4 py-2">{l.hotels?.name ?? '—'}</td>
                  <td className="px-4 py-2 text-gray-500">{new Date(l.issued_at).toLocaleDateString('he-IL')}</td>
                  <td className="px-4 py-2 text-gray-500">{l.notes ?? '—'}</td>
                  <td className="px-4 py-2">
                    {l.status === 'unused' && (
                      <button
                        type="button"
                        onClick={() => revoke(l.id)}
                        disabled={busyId === l.id}
                        className="text-xs text-red-600 hover:underline disabled:opacity-50"
                      >
                        בטל
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
export default LicensesPage
