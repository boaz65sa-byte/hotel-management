import { DeleteHotelButton } from './delete-hotel-button'
import { HotelForm } from '@/components/hotel-form'
import { assertHotelAccess, requireDashboardViewer } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'
import { notFound } from 'next/navigation'
import { updateHotelScoped } from './hotel-actions'

export default async function EditHotelPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const viewer = await requireDashboardViewer()
  assertHotelAccess(viewer, id)

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('*')
    .eq('id', id)
    .single()

  if (!hotel) notFound()

  const boundUpdate = updateHotelScoped.bind(null, id)

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Edit Hotel: {hotel.name}</h1>
      <div className="mb-6 flex flex-wrap items-center gap-3">
        <a
          href={`/dashboard/hotels/${hotel.id}/rooms`}
          className="inline-flex items-center gap-2 bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700"
        >
          🛏️ נהל חדרים
        </a>
        <a
          href={`/dashboard/hotels/${hotel.id}/qr-codes`}
          className="inline-flex items-center gap-2 bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700"
        >
          🔲 QR למלון + לחדרים
        </a>
        <a
          href={`/dashboard/hotels/${hotel.id}/qr-codes/poster`}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 bg-amber-500 text-white px-4 py-2 rounded-lg text-sm hover:bg-amber-600"
        >
          🖨️ פוסטר קבלה (A4)
        </a>
        {viewer.isSuperAdmin && (
          <DeleteHotelButton hotelId={hotel.id} hotelName={hotel.name} />
        )}
      </div>
      <HotelForm
        hotel={{
          id: hotel.id,
          name: hotel.name,
          subscription_plan: hotel.subscription_plan,
          default_sla_hours: hotel.default_sla_hours,
          default_language: hotel.default_language,
          is_active: hotel.is_active,
          theme: hotel.theme,
          stay_threshold: hotel.stay_threshold ?? 3,
          guest_pwa_url: hotel.guest_pwa_url ?? null,
          logo_url: hotel.logo_url ?? null,
        }}
        action={boundUpdate}
        variant={viewer.isSuperAdmin ? 'super' : 'hotel'}
      />
    </div>
  )
}
