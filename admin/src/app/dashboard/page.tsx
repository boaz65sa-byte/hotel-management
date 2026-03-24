import { supabaseAdmin } from '@/lib/supabase-admin'

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

  const cards = [
    { label: 'Total Hotels',  value: stats.totalHotels,  sub: `${stats.activeHotels} active` },
    { label: 'Total Users',   value: stats.totalUsers,   sub: `${stats.activeUsers} active` },
    { label: 'Open Tickets',  value: stats.openTickets,  sub: 'across all hotels' },
  ]

  return (
    <div>
      <h1 className="text-2xl font-bold mb-8">Overview</h1>
      <div className="grid grid-cols-3 gap-6">
        {cards.map(c => (
          <div key={c.label} className="bg-white rounded-xl p-6 shadow-sm border">
            <div className="text-3xl font-bold text-blue-600">{c.value}</div>
            <div className="font-medium mt-1">{c.label}</div>
            <div className="text-sm text-gray-500">{c.sub}</div>
          </div>
        ))}
      </div>
    </div>
  )
}
