import { supabaseAdmin } from '@/lib/supabase-admin'
import { notFound } from 'next/navigation'
import QRCode from 'qrcode'
import { DownloadZipButton } from './download-zip-button'
import { HotelQrActions } from './hotel-qr-actions'

const FALLBACK_PWA_BASE_URL = 'https://exquisite-cocada-7966bd.netlify.app'

async function generateQrDataUrl(url: string, size = 200): Promise<string> {
  return QRCode.toDataURL(url, {
    width: size,
    margin: 2,
    color: { dark: '#0a1628', light: '#ffffff' },
  })
}

export default async function HotelQrCodesPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('id, name, logo_url, guest_pwa_url')
    .eq('id', id)
    .single()

  if (!hotel) notFound()

  const baseUrl = (hotel.guest_pwa_url as string | null)?.trim() || FALLBACK_PWA_BASE_URL

  // Hotel-wide QR (lobby / reception). No room param → guest fills it manually.
  const hotelUrl = `${baseUrl}/#/?hotel=${hotel.id}`
  const hotelQrDataUrl = await generateQrDataUrl(hotelUrl, 320)

  const { data: rooms } = await supabaseAdmin
    .from('rooms')
    .select('id, room_number')
    .eq('hotel_id', id)
    .order('room_number')

  const roomsWithQr = await Promise.all(
    (rooms ?? []).map(async (room) => {
      const url = `${baseUrl}/#/?hotel=${hotel.id}&room=${room.room_number}`
      const qrDataUrl = await generateQrDataUrl(url)
      return { ...room, url, qrDataUrl }
    })
  )

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">QR Codes — {hotel.name}</h1>
          <p className="text-gray-500 text-sm mt-1">
            QR לקבלה (כללי) + QR נפרד לכל חדר
          </p>
        </div>
        <a
          href={`/dashboard/hotels/${id}`}
          className="text-sm text-blue-600 hover:underline"
        >
          ← חזרה למלון
        </a>
      </div>

      <section className="bg-gradient-to-br from-blue-50 to-amber-50 border-2 border-amber-200 rounded-2xl p-6 mb-8">
        <div className="flex items-start gap-2 mb-4">
          <span className="text-2xl">🏨</span>
          <div>
            <h2 className="text-xl font-bold text-gray-900">QR לקבלה / לובי</h2>
            <p className="text-sm text-gray-600">
              קוד אחד לכל המלון — האורח סורק בכניסה, ממלא שם וחדר ידנית, ויכול לשלוח בקשות מהאפליקציה.
            </p>
          </div>
        </div>

        <div className="flex flex-col md:flex-row items-center gap-6">
          <div className="bg-white rounded-xl p-4 shadow-sm border">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={hotelQrDataUrl}
              alt={`QR ${hotel.name}`}
              width={260}
              height={260}
            />
          </div>
          <div className="flex-1 space-y-4 w-full">
            <div>
              <p className="text-xs uppercase font-bold text-gray-500 mb-1">קישור</p>
              <p className="text-xs text-gray-700 break-all bg-white border rounded-lg p-2" dir="ltr">
                {hotelUrl}
              </p>
            </div>
            <HotelQrActions
              url={hotelUrl}
              qrDataUrl={hotelQrDataUrl}
              hotelName={hotel.name as string}
              hotelId={id}
            />
            <p className="text-xs text-gray-500">
              לחיצה על "פוסטר להדפסה" פותחת עמוד A4 מוכן עם הלוגו ושם המלון — מתאים להדפסה בקבלה.
            </p>
          </div>
        </div>
      </section>

      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold text-gray-900">🚪 QR לכל חדר ({roomsWithQr.length})</h2>
        <DownloadZipButton hotelId={id} />
      </div>

      {roomsWithQr.length === 0 ? (
        <p className="text-gray-500">אין חדרים מוגדרים למלון זה.</p>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          {roomsWithQr.map((room) => (
            <div
              key={room.id}
              className="border rounded-xl p-4 flex flex-col items-center gap-3 bg-white shadow-sm"
            >
              <p className="font-bold text-lg">חדר {room.room_number}</p>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={room.qrDataUrl}
                alt={`QR חדר ${room.room_number}`}
                width={160}
                height={160}
              />
              <p className="text-xs text-gray-400 text-center break-all">
                {room.url}
              </p>
              <a
                href={room.qrDataUrl}
                download={`qr-room-${room.room_number}.png`}
                className="text-sm bg-blue-600 text-white px-3 py-1.5 rounded-lg hover:bg-blue-700"
              >
                הורד PNG
              </a>
            </div>
          ))}
        </div>
      )}

      <div className="mt-8 p-4 bg-blue-50 rounded-lg text-sm text-blue-800">
        <strong>איך לבחור?</strong>
        <ul className="list-disc list-inside mt-2 space-y-1">
          <li><strong>QR קבלה</strong> — להציב בלובי / קבלה / חדר אוכל. האורח סורק וממלא חדר ידנית.</li>
          <li><strong>QR לחדר</strong> — להדביק על שלט החדר. מספר החדר מולא אוטומטית — פחות טעויות.</li>
          <li>אפשר וגם רצוי <strong>להשתמש בשניהם</strong>.</li>
        </ul>
      </div>
    </div>
  )
}
