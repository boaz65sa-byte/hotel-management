import { requireDashboardViewer } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'
import { OverviewCards } from './overview-cards'

async function getStats(hotelScope: string | null) {
  if (!hotelScope) {
    const [hotels, users, tickets] = await Promise.all([
      supabaseAdmin.from('hotels').select('id, is_active').then(r => r.data ?? []),
      supabaseAdmin.from('users').select('id, is_active').then(r => r.data ?? []),
      supabaseAdmin.from('tickets').select('id, status').then(r => r.data ?? []),
    ])
    return {
      totalHotels: hotels.length,
      activeHotels: hotels.filter(h => h.is_active).length,
      totalUsers: users.length,
      activeUsers: users.filter(u => u.is_active).length,
      openTickets: tickets.filter(t => !['resolved', 'closed'].includes(t.status)).length,
    }
  }

  const [hotels, users, tickets] = await Promise.all([
    supabaseAdmin.from('hotels').select('id, is_active').eq('id', hotelScope).maybeSingle().then(r => (r.data ? [r.data] : [])),
    supabaseAdmin.from('users').select('id, is_active').eq('hotel_id', hotelScope).then(r => r.data ?? []),
    supabaseAdmin.from('tickets').select('id, status').eq('hotel_id', hotelScope).then(r => r.data ?? []),
  ])

  return {
    totalHotels: hotels.length ? 1 : 0,
    activeHotels: hotels.filter(h => h.is_active).length,
    totalUsers: users.length,
    activeUsers: users.filter(u => u.is_active).length,
    openTickets: tickets.filter(t => !['resolved', 'closed'].includes(t.status)).length,
  }
}

export default async function DashboardPage() {
  const viewer = await requireDashboardViewer()
  const hotelScope = viewer.isHotelTierAdmin ? viewer.hotelId : null
  const stats = await getStats(hotelScope)
  return <OverviewCards {...stats} hotelScoped={Boolean(hotelScope)} />
}
