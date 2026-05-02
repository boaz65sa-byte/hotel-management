import { supabaseAdmin } from '@/lib/supabase-admin'

const STATUS_LABELS: Record<string, string> = {
  open:        'פתוחה',
  assigned:    'הוקצתה',
  in_progress: 'בטיפול',
  resolved:    'טופלה',
  cancelled:   'בוטלה',
}

const STATUS_COLORS: Record<string, string> = {
  open:        'bg-red-100 text-red-700',
  assigned:    'bg-orange-100 text-orange-700',
  in_progress: 'bg-amber-100 text-amber-700',
  resolved:    'bg-green-100 text-green-700',
  cancelled:   'bg-gray-100 text-gray-500',
}

const CATEGORY_LABELS: Record<string, string> = {
  housekeeping: 'חדרניות',
  maintenance:  'תחזוקה',
  reception:    'קבלה',
}

function fmtDate(iso: string) {
  const d = new Date(iso)
  return d.toLocaleDateString('he-IL') + ' ' + d.toLocaleTimeString('he-IL', { hour: '2-digit', minute: '2-digit' })
}

export default async function GuestRequestsAdminPage({
  searchParams,
}: {
  searchParams: Promise<{ hotel?: string; status?: string; from?: string; to?: string }>
}) {
  const params = await searchParams
  const { hotel: hotelFilter, status: statusFilter, from: fromFilter, to: toFilter } = params

  const { data: hotels } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .order('name')

  let query = supabaseAdmin
    .from('guest_requests')
    .select('id, hotel_id, room_number, guest_name, category, status, description, assigned_dept, created_by, created_at')
    .order('created_at', { ascending: false })
    .limit(200)

  if (hotelFilter) query = query.eq('hotel_id', hotelFilter)
  if (statusFilter) query = query.eq('status', statusFilter)
  if (fromFilter)   query = query.gte('created_at', fromFilter)
  if (toFilter)     query = query.lte('created_at', toFilter + 'T23:59:59')

  const { data: requests } = await query

  const hotelMap = Object.fromEntries((hotels ?? []).map(h => [h.id, h.name]))

  const statuses = ['open', 'assigned', 'in_progress', 'resolved', 'cancelled']

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-6">🛎️ בקשות אורחים</h1>

      {/* Filters */}
      <form method="GET" className="flex flex-wrap gap-3 mb-6 bg-gray-50 p-4 rounded-xl border">
        <select name="hotel" defaultValue={hotelFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm">
          <option value="">כל המלונות</option>
          {(hotels ?? []).map(h => (
            <option key={h.id} value={h.id}>{h.name}</option>
          ))}
        </select>

        <select name="status" defaultValue={statusFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm">
          <option value="">כל הסטטוסים</option>
          {statuses.map(s => (
            <option key={s} value={s}>{STATUS_LABELS[s]}</option>
          ))}
        </select>

        <div className="flex items-center gap-2 text-sm">
          <span className="text-gray-500">מ-</span>
          <input type="date" name="from" defaultValue={fromFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm" />
          <span className="text-gray-500">עד</span>
          <input type="date" name="to" defaultValue={toFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm" />
        </div>

        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">
          סנן
        </button>
        <a href="/dashboard/guest-requests" className="text-sm text-gray-500 hover:text-gray-800 py-2 px-2">
          נקה
        </a>
      </form>

      {/* Summary pills */}
      <div className="flex gap-3 mb-4 flex-wrap">
        <span className="bg-blue-50 text-blue-700 px-3 py-1 rounded-full text-sm font-medium">
          סה&quot;כ: {requests?.length ?? 0}
        </span>
        <span className="bg-red-50 text-red-700 px-3 py-1 rounded-full text-sm font-medium">
          פתוחות: {requests?.filter(r => r.status === 'open' || r.status === 'assigned').length ?? 0}
        </span>
        <span className="bg-amber-50 text-amber-700 px-3 py-1 rounded-full text-sm font-medium">
          בטיפול: {requests?.filter(r => r.status === 'in_progress').length ?? 0}
        </span>
        <span className="bg-green-50 text-green-700 px-3 py-1 rounded-full text-sm font-medium">
          טופלו: {requests?.filter(r => r.status === 'resolved').length ?? 0}
        </span>
      </div>

      {/* Table */}
      {!requests || requests.length === 0 ? (
        <p className="text-gray-500 py-12 text-center">אין בקשות</p>
      ) : (
        <div className="overflow-x-auto rounded-xl border">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">מלון</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">חדר</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">אורח</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">קטגוריה</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">סטטוס</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תיאור</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תאריך</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {requests.map(r => (
                <tr key={r.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-gray-700">{hotelMap[r.hotel_id] ?? r.hotel_id.slice(0, 8)}</td>
                  <td className="px-4 py-3 font-medium">{r.room_number}</td>
                  <td className="px-4 py-3 text-gray-700">{r.guest_name}</td>
                  <td className="px-4 py-3">{CATEGORY_LABELS[r.category] ?? r.category}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${STATUS_COLORS[r.status] ?? 'bg-gray-100 text-gray-500'}`}>
                      {STATUS_LABELS[r.status] ?? r.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-500 max-w-xs truncate">{r.description ?? '—'}</td>
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">{fmtDate(r.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
