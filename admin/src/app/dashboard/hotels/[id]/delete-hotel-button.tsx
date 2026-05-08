'use client'

import { useState } from 'react'
import { deleteHotel } from './actions'

export function DeleteHotelButton({
  hotelId,
  hotelName,
}: {
  hotelId: string
  hotelName: string
}) {
  const [open, setOpen] = useState(false)
  const [confirm, setConfirm] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleConfirm() {
    setBusy(true)
    setError(null)
    try {
      const result = await deleteHotel(hotelId, confirm)
      if (!result.ok) {
        setError(result.error ?? 'Delete failed')
      }
      // Successful deletes redirect from the server action.
    } catch (e) {
      // Server-action redirects throw a NEXT_REDIRECT — that's expected,
      // surface only real errors.
      const msg = e instanceof Error ? e.message : ''
      if (!msg.includes('NEXT_REDIRECT')) setError(msg || 'Delete failed')
    } finally {
      setBusy(false)
    }
  }

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="ml-auto inline-flex items-center gap-2 text-red-600 border border-red-200 px-4 py-2 rounded-lg text-sm hover:bg-red-50"
      >
        🗑️ מחק מלון
      </button>
    )
  }

  return (
    <div className="ml-auto p-4 border border-red-200 rounded-lg bg-red-50 max-w-md">
      <p className="text-sm font-medium text-red-900 mb-2">
        מחיקת מלון <strong>{hotelName}</strong> תמחק לצמיתות את כל החדרים, הקריאות,
        בקשות האורחים והמשובים שלו. פעולה זו לא ניתנת לביטול.
      </p>
      <label className="block text-xs text-red-800 mb-1">
        כתבו את שם המלון לאישור: <code className="bg-white px-1">{hotelName}</code>
      </label>
      <input
        type="text"
        value={confirm}
        onChange={(e) => setConfirm(e.target.value)}
        className="w-full border rounded px-3 py-2 text-sm mb-2"
      />
      {error && <p className="text-red-700 text-sm mb-2">{error}</p>}
      <div className="flex gap-2">
        <button
          type="button"
          disabled={busy || confirm !== hotelName}
          onClick={handleConfirm}
          className="bg-red-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-red-700 disabled:opacity-50"
        >
          {busy ? '...מוחק' : 'מחק לצמיתות'}
        </button>
        <button
          type="button"
          onClick={() => { setOpen(false); setConfirm(''); setError(null) }}
          disabled={busy}
          className="border px-4 py-2 rounded-lg text-sm hover:bg-white"
        >
          ביטול
        </button>
      </div>
    </div>
  )
}
