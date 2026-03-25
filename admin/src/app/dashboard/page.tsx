import { supabaseAdmin } from '@/lib/supabase-admin'
import { OverviewCards } from './overview-cards'

async function getStats() {
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
    openTickets: tickets.filter(t => !['resolved','closed'].includes(t.status)).length,
  }
}

export default async function DashboardPage() {
  const stats = await getStats()
  return <OverviewCards {...stats} />
}
