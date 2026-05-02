import { supabaseAdmin } from '@/lib/supabase-admin'

function Stars({ rating }: { rating: number }) {
  return (
    <span className="text-yellow-500">
      {'★'.repeat(rating)}{'☆'.repeat(5 - rating)}
    </span>
  )
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('he-IL')
}

export default async function GuestFeedbackAdminPage({
  searchParams,
}: {
  searchParams: Promise<{ hotel?: string }>
}) {
  const params = await searchParams
  const { hotel: hotelFilter } = params

  const { data: hotels } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .order('name')

  let fbQuery = supabaseAdmin
    .from('guest_feedback')
    .select('id, hotel_id, room_number, guest_name, rating, comment, created_at')
    .order('created_at', { ascending: false })
    .limit(300)

  if (hotelFilter) fbQuery = fbQuery.eq('hotel_id', hotelFilter)

  const { data: feedback } = await fbQuery

  const hotelMap = Object.fromEntries((hotels ?? []).map(h => [h.id, h.name]))

  const ratingByHotel: Record<string, { total: number; count: number; name: string }> = {}
  for (const f of feedback ?? []) {
    if (!ratingByHotel[f.hotel_id]) {
      ratingByHotel[f.hotel_id] = { total: 0, count: 0, name: hotelMap[f.hotel_id] ?? f.hotel_id }
    }
    ratingByHotel[f.hotel_id].total += f.rating
    ratingByHotel[f.hotel_id].count++
  }

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-6">⭐ משובי אורחים</h1>

      {/* Filter */}
      <form method="GET" className="flex gap-3 mb-6">
        <select name="hotel" defaultValue={hotelFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm">
          <option value="">כל המלונות</option>
          {(hotels ?? []).map(h => (
            <option key={h.id} value={h.id}>{h.name}</option>
          ))}
        </select>
        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">סנן</button>
        <a href="/dashboard/guest-feedback" className="text-sm text-gray-500 hover:text-gray-800 py-2 px-2">נקה</a>
      </form>

      {/* Average per hotel */}
      {Object.keys(ratingByHotel).length > 0 && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-8">
          {Object.entries(ratingByHotel).map(([id, { name, total, count }]) => (
            <div key={id} className="border rounded-xl p-4 bg-white shadow-sm">
              <p className="font-semibold text-gray-700 mb-1">{name}</p>
              <p className="text-2xl font-bold text-yellow-500">
                {(total / count).toFixed(1)} ★
              </p>
              <p className="text-xs text-gray-400">{count} משובים</p>
            </div>
          ))}
        </div>
      )}

      {/* Table */}
      {!feedback || feedback.length === 0 ? (
        <p className="text-gray-500 py-12 text-center">אין משובים</p>
      ) : (
        <div className="overflow-x-auto rounded-xl border">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">מלון</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">חדר</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">אורח</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">דירוג</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תגובה</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תאריך</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {feedback.map(f => (
                <tr key={f.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-gray-700">{hotelMap[f.hotel_id] ?? f.hotel_id.slice(0, 8)}</td>
                  <td className="px-4 py-3 font-medium">{f.room_number}</td>
                  <td className="px-4 py-3">{f.guest_name}</td>
                  <td className="px-4 py-3"><Stars rating={f.rating} /></td>
                  <td className="px-4 py-3 text-gray-500 max-w-xs">{f.comment ?? '—'}</td>
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">{fmtDate(f.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
