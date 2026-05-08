import { supabaseAdmin } from '@/lib/supabase-admin'
import { notFound } from 'next/navigation'
import QRCode from 'qrcode'
import { DownloadZipButton } from './download-zip-button'

const FALLBACK_PWA_BASE_URL = 'https://zesty-queijadas-16c29.netlify.app'

async function generateQrDataUrl(url: string): Promise<string> {
  return QRCode.toDataURL(url, {
    width: 200,
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
    .select('id, name, guest_pwa_url')
    .eq('id', id)
    .single()

  if (!hotel) notFound()

  const baseUrl = (hotel.guest_pwa_url as string | null)?.trim() || FALLBACK_PWA_BASE_URL

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
            QR נפרד לכל חדר — יש להדביק בחדר
          </p>
        </div>
        <div className="flex items-center gap-3">
          <DownloadZipButton hotelId={id} />
          <a
            href={`/dashboard/hotels/${id}`}
            className="text-sm text-blue-600 hover:underline"
          >
            ← חזרה למלון
          </a>
        </div>
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
        <strong>כיצד להשתמש:</strong> הורידו את ה-QR של כל חדר והדביקו אותו בולט בחדר (על שלט, על
        הקיר ליד הדלת). האורח סורק → ממלא שם → שולח בקשות.
      </div>
    </div>
  )
}
