'use client'

import { useState } from 'react'
import { buildHotelQrZipBase64 } from './actions'

export function DownloadZipButton({ hotelId }: { hotelId: string }) {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleClick() {
    setBusy(true)
    setError(null)
    try {
      const result = await buildHotelQrZipBase64(hotelId)
      if (!result) {
        setError('אין חדרים להוריד')
        return
      }
      // Convert base64 → Blob → download
      const byteString = atob(result.base64)
      const bytes = new Uint8Array(byteString.length)
      for (let i = 0; i < byteString.length; i++) bytes[i] = byteString.charCodeAt(i)
      const blob = new Blob([bytes], { type: 'application/zip' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = result.filename
      document.body.appendChild(a)
      a.click()
      a.remove()
      URL.revokeObjectURL(url)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'שגיאה')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="inline-flex items-center gap-3">
      <button
        type="button"
        onClick={handleClick}
        disabled={busy}
        className="inline-flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700 disabled:opacity-50"
      >
        {busy ? '...יוצר ZIP' : '⬇️ הורד הכל כ-ZIP'}
      </button>
      {error && <span className="text-red-600 text-sm">{error}</span>}
    </div>
  )
}
