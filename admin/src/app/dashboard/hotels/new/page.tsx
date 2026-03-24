import { supabaseAdmin } from '@/lib/supabase-admin'
import { HotelForm } from '@/components/hotel-form'
import { redirect } from 'next/navigation'

async function createHotel(fd: FormData) {
  'use server'
  await supabaseAdmin.from('hotels').insert({
    name:              fd.get('name') as string,
    subscription_plan: fd.get('subscription_plan') as string,
    default_sla_hours: Number(fd.get('default_sla_hours')),
    default_language:  fd.get('default_language') as string,
    theme_colors:      JSON.parse(fd.get('theme_colors') as string),
    is_active:         fd.get('is_active') === 'on',
    storage_quota_gb:  fd.get('subscription_plan') === 'enterprise' ? 200
                     : fd.get('subscription_plan') === 'pro' ? 50 : 10,
  })
  redirect('/dashboard/hotels')
}

export default function NewHotelPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">New Hotel</h1>
      <HotelForm
        hotel={{ name: '', subscription_plan: 'basic', default_sla_hours: 4,
                 default_language: 'he', is_active: true,
                 theme_colors: { primary: '#1976D2', secondary: '#424242', accent: '#FF6F00' } }}
        action={createHotel}
      />
    </div>
  )
}
