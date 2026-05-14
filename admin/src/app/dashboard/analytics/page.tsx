import { requireDashboardViewer } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

export default async function AnalyticsPage() {
  const viewer = await requireDashboardViewer()

  let tq = supabaseAdmin.from('tickets').select('hotel_id, status, hotels(name)')
  if (viewer.isHotelTierAdmin && viewer.hotelId) {
    tq = tq.eq('hotel_id', viewer.hotelId)
  }
  const { data: ticketsByHotel } = await tq

  const hotelMap: Record<string, { name: string; total: number; open: number; resolved: number }> = {}
  for (const t of ticketsByHotel ?? []) {
    const hid = t.hotel_id as string
    const hotelRel = t.hotels as { name?: string } | { name?: string }[] | null
    const name = (Array.isArray(hotelRel) ? hotelRel[0]?.name : hotelRel?.name) ?? hid
    if (!hotelMap[hid]) hotelMap[hid] = { name, total: 0, open: 0, resolved: 0 }
    hotelMap[hid].total++
    if (['resolved', 'closed'].includes(t.status as string)) hotelMap[hid].resolved++
    else hotelMap[hid].open++
  }

  const rows = Object.values(hotelMap).sort((a, b) => b.total - a.total)

  const title = viewer.isSuperAdmin ? 'Global Analytics' : 'Analytics'

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">{title}</h1>
      <div className="bg-white rounded-xl border overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              {['Hotel', 'Total Tickets', 'Open', 'Resolved', 'Resolution Rate'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-sm font-medium text-gray-500">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y">
            {rows.map(h => (
              <tr key={h.name} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{h.name}</td>
                <td className="px-4 py-3">{h.total}</td>
                <td className="px-4 py-3 text-orange-600">{h.open}</td>
                <td className="px-4 py-3 text-green-600">{h.resolved}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <div className="w-24 bg-gray-200 rounded-full h-2">
                      <div className="bg-green-500 h-2 rounded-full"
                        style={{ width: `${h.total ? (h.resolved / h.total) * 100 : 0}%` }} />
                    </div>
                    <span className="text-sm">
                      {h.total ? Math.round((h.resolved / h.total) * 100) : 0}%
                    </span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
