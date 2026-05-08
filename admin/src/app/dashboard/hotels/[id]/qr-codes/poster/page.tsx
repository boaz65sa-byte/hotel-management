import { supabaseAdmin } from '@/lib/supabase-admin'
import { notFound } from 'next/navigation'
import QRCode from 'qrcode'
import { PrintButton } from './print-button'

const FALLBACK_PWA_BASE_URL = 'https://exquisite-cocada-7966bd.netlify.app'

export default async function HotelPosterPage({
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

  const baseUrl =
    (hotel.guest_pwa_url as string | null)?.trim() || FALLBACK_PWA_BASE_URL
  const url = `${baseUrl}/#/?hotel=${hotel.id}`

  const qrDataUrl = await QRCode.toDataURL(url, {
    width: 600,
    margin: 1,
    errorCorrectionLevel: 'H',
    color: { dark: '#0a1628', light: '#ffffff' },
  })

  return (
    <div className="min-h-screen bg-gray-100 print:bg-white">
      <style>{`
        @media print {
          @page { size: A4 portrait; margin: 0; }
          body { margin: 0; }
          .no-print { display: none !important; }
        }
      `}</style>

      <div className="no-print sticky top-0 bg-white border-b shadow-sm p-4 flex items-center justify-between">
        <a
          href={`/dashboard/hotels/${id}/qr-codes`}
          className="text-sm text-blue-600 hover:underline"
        >
          ← חזרה
        </a>
        <PrintButton />
      </div>

      <div className="mx-auto bg-white shadow-lg my-8 print:my-0 print:shadow-none flex flex-col items-center justify-between"
           style={{ width: '210mm', minHeight: '297mm', padding: '20mm' }}
      >
        <div className="text-center">
          {hotel.logo_url && (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={hotel.logo_url as string}
              alt="Hotel logo"
              className="mx-auto mb-6 object-contain"
              style={{ maxHeight: '40mm', maxWidth: '60mm' }}
            />
          )}
          <h1 className="text-5xl font-bold text-gray-900 mb-3">{hotel.name}</h1>
          <p className="text-2xl text-gray-700">ברוכים הבאים</p>
          <p className="text-lg text-gray-500 mt-1">Welcome · أهلاً وسهلاً · Добро пожаловать</p>
        </div>

        <div className="my-6">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={qrDataUrl}
            alt="Guest QR"
            style={{ width: '120mm', height: '120mm' }}
          />
        </div>

        <div className="text-center max-w-prose">
          <p className="text-3xl font-bold text-gray-900 mb-3">סרקו לשירות אורחים</p>
          <div className="text-base text-gray-600 leading-relaxed space-y-1" dir="auto">
            <p dir="rtl">📱 פתחו את המצלמה בטלפון וסרקו את ה-QR</p>
            <p dir="ltr">📱 Open your phone camera and scan the QR code</p>
            <p dir="rtl">📱 افتح كاميرا الهاتف وامسح رمز الاستجابة السريعة</p>
            <p dir="ltr">📱 Откройте камеру и отсканируйте QR-код</p>
          </div>
          <p className="text-sm text-gray-400 mt-6">
            בקשות · משוב · שירותים · ועוד
          </p>
        </div>

        <div className="text-xs text-gray-300 mt-4 text-center" dir="ltr">
          {url}
        </div>
      </div>
    </div>
  )
}
