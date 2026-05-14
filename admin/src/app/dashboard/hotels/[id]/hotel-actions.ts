'use server'

import { redirect } from 'next/navigation'

import { verifyDashboardViewerForAction } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

/** Hotel-tier admins cannot change billing plan / active toggle. */
export async function updateHotelScoped(hotelId: string, fd: FormData) {
  const viewer = await verifyDashboardViewerForAction()
  if (!viewer) redirect('/login')

  if (!viewer.isSuperAdmin) {
    if (!viewer.hotelId || viewer.hotelId !== hotelId) {
      throw new Error('Forbidden')
    }
  }

  const guestPwaUrlRaw = ((fd.get('guest_pwa_url') as string) ?? '').trim()
  const logoUrl = ((fd.get('logo_url') as string) ?? '').trim()

  const payload: Record<string, unknown> = {
    name: fd.get('name') as string,
    default_sla_hours: Number(fd.get('default_sla_hours')),
    default_language: fd.get('default_language') as string,
    theme: (fd.get('theme') as string) || 'clean_blue',
    stay_threshold: Number(fd.get('stay_threshold')) || 3,
    logo_url: logoUrl || null,
  }

  if (guestPwaUrlRaw)
    payload.guest_pwa_url = guestPwaUrlRaw

  if (viewer.isSuperAdmin) {
    payload.subscription_plan = fd.get('subscription_plan') as string
    payload.is_active = fd.get('is_active') === 'on'
  }

  await supabaseAdmin.from('hotels').update(payload).eq('id', hotelId)

  if (viewer.isSuperAdmin) redirect('/dashboard/hotels')
  redirect(`/dashboard/hotels/${hotelId}`)
}
