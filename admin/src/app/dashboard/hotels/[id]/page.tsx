import { supabaseAdmin } from '@/lib/supabase-admin'
import { HotelForm } from '@/components/hotel-form'
import { redirect, notFound } from 'next/navigation'

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
    await supabaseAdmin.from('hotels').update({
      name:              fd.get('name') as string,
      subscription_plan: fd.get('subscription_plan') as string,
      default_sla_hours: Number(fd.get('default_sla_hours')),
      default_language:  fd.get('default_language') as string,
      theme:             (fd.get('theme') as string) || 'clean_blue',
      is_active:         fd.get('is_active') === 'on',
    }).eq('id', id)
    redirect('/dashboard/hotels')
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Edit Hotel: {hotel.name}</h1>
      <HotelForm hotel={{
        id: hotel.id,
        name: hotel.name,
        subscription_plan: hotel.subscription_plan,
        default_sla_hours: hotel.default_sla_hours,
        default_language: hotel.default_language,
        is_active: hotel.is_active,
        theme: hotel.theme,
      }} action={updateHotel} />
    </div>
  )
}
