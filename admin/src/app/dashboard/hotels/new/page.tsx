import { supabaseAdmin } from '@/lib/supabase-admin'
import { HotelForm } from '@/components/hotel-form'
import { redirect } from 'next/navigation'

async function createHotel(fd: FormData) {
  'use server'
  const guestPwaUrl = ((fd.get('guest_pwa_url') as string) ?? '').trim()
  await supabaseAdmin.from('hotels').insert({
    name:              fd.get('name') as string,
    subscription_plan: fd.get('subscription_plan') as string,
    default_sla_hours: Number(fd.get('default_sla_hours')),
    default_language:  fd.get('default_language') as string,
    theme:             (fd.get('theme') as string) || 'clean_blue',
    is_active:         fd.get('is_active') === 'on',
    stay_threshold:    Number(fd.get('stay_threshold')) || 3,
    storage_quota_gb:  fd.get('subscription_plan') === 'enterprise' ? 200
                     : fd.get('subscription_plan') === 'pro' ? 50 : 10,
    ...(guestPwaUrl ? { guest_pwa_url: guestPwaUrl } : {}),
  })
  redirect('/dashboard/hotels')
}

export default function NewHotelPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">New Hotel</h1>
      <HotelForm
        hotel={{ name: '', subscription_plan: 'basic', default_sla_hours: 4,
                 default_language: 'he', is_active: true, theme: 'clean_blue' }}
        action={createHotel}
      />
    </div>
  )
}
