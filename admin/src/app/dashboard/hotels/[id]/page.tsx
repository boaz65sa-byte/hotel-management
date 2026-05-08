import { supabaseAdmin } from '@/lib/supabase-admin'
import { HotelForm } from '@/components/hotel-form'
import { redirect, notFound } from 'next/navigation'
import { DeleteHotelButton } from './delete-hotel-button'

export default async function EditHotelPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('*')
    .eq('id', id)
    .single()

  if (!hotel) notFound()

  async function updateHotel(fd: FormData) {
    'use server'
    const guestPwaUrl = ((fd.get('guest_pwa_url') as string) ?? '').trim()
    await supabaseAdmin.from('hotels').update({
      name:              fd.get('name') as string,
      subscription_plan: fd.get('subscription_plan') as string,
      default_sla_hours: Number(fd.get('default_sla_hours')),
      default_language:  fd.get('default_language') as string,
      theme:             (fd.get('theme') as string) || 'clean_blue',
      is_active:         fd.get('is_active') === 'on',
      stay_threshold:    Number(fd.get('stay_threshold')) || 3,
      ...(guestPwaUrl ? { guest_pwa_url: guestPwaUrl } : {}),
    }).eq('id', id)
    redirect('/dashboard/hotels')
  }

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
          🔲 QR Codes לחדרים
        </a>
        <DeleteHotelButton hotelId={hotel.id} hotelName={hotel.name} />
      </div>
      <HotelForm hotel={{
        id: hotel.id,
        name: hotel.name,
        subscription_plan: hotel.subscription_plan,
        default_sla_hours: hotel.default_sla_hours,
        default_language: hotel.default_language,
        is_active: hotel.is_active,
        theme: hotel.theme,
        stay_threshold: hotel.stay_threshold ?? 3,
        guest_pwa_url: hotel.guest_pwa_url ?? null,
      }} action={updateHotel} />
    </div>
  )
}
