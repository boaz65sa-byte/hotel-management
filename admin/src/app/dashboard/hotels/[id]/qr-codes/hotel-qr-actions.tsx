'use client'
import { useState } from 'react'

type Props = {
  url: string
  qrDataUrl: string
  hotelName: string
  hotelId: string
}

export function HotelQrActions({ url, qrDataUrl, hotelName, hotelId }: Props) {
  const [copied, setCopied] = useState(false)

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(url)
      setCopied(true)
      setTimeout(() => setCopied(false), 1500)
    } catch {
      // ignore — older browsers may not support clipboard
    }
  }

  const subject = encodeURIComponent(`QR אורחים — ${hotelName}`)
  const body = encodeURIComponent(
    `שלום,\n\nמצורף קישור ה-QR של אורחי המלון.\nניתן להדפיס ולהציג בקבלה.\n\nקישור ישיר:\n${url}\n\nפוסטר להדפסה:\nhttps://hotel-management-rho-two.vercel.app/dashboard/hotels/${hotelId}/qr-codes/poster\n`,
  )
  const mailto = `mailto:?subject=${subject}&body=${body}`

  return (
    <div className="flex flex-wrap items-center gap-2">
      <a
        href={qrDataUrl}
        download={`qr-${hotelName.replace(/\s+/g, '-')}.png`}
        className="inline-flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700"
      >
        ⬇ הורד PNG
      </a>
      <a
        href={`/dashboard/hotels/${hotelId}/qr-codes/poster`}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-flex items-center gap-2 bg-amber-500 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-amber-600"
      >
        🖨️ פוסטר להדפסה
      </a>
      <button
        type="button"
        onClick={handleCopy}
        className="inline-flex items-center gap-2 border px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50"
      >
        {copied ? '✓ הקישור הועתק' : '🔗 העתק קישור'}
      </button>
      <a
        href={mailto}
        className="inline-flex items-center gap-2 border px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50"
      >
        ✉️ שלח במייל
      </a>
    </div>
  )
}
