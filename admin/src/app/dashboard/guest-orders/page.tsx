import { supabaseAdmin } from '@/lib/supabase-admin'
import {
  assertHotelMutationAllowed,
  requireDashboardViewer,
  verifyDashboardViewerForAction,
} from '@/lib/auth-guard'
import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'

const STATUS_LABELS: Record<string, string> = {
  open:      'חדשה',
  confirmed: 'אושרה',
  delivered: 'נמסרה',
  cancelled: 'בוטלה',
}

const STATUS_COLORS: Record<string, string> = {
  open:      'bg-red-100 text-red-700',
  confirmed: 'bg-amber-100 text-amber-700',
  delivered: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-100 text-gray-500',
}

const CATEGORY_LABELS: Record<string, string> = {
  restaurant:   '🍽️ מסעדה',
  spa:          '💆 ספא',
  room_service: '🛎️ רום סרוויס',
}

function fmtDate(iso: string) {
  const d = new Date(iso)
  return d.toLocaleDateString('he-IL') + ' ' + d.toLocaleTimeString('he-IL', { hour: '2-digit', minute: '2-digit' })
}

export default async function GuestOrdersAdminPage({
  searchParams,
}: {
  searchParams: Promise<{ hotel?: string; status?: string }>
}) {
  const raw = await searchParams
  let { hotel: hotelFilter } = raw
  const { status: statusFilter } = raw

  const viewer = await requireDashboardViewer()

  if (viewer.isHotelTierAdmin && viewer.hotelId) {
    hotelFilter = viewer.hotelId
  }

  let hotelsQuery = supabaseAdmin.from('hotels').select('id, name').order('name')
  if (viewer.isHotelTierAdmin && viewer.hotelId) {
    hotelsQuery = hotelsQuery.eq('id', viewer.hotelId)
  }
  const { data: hotels } = await hotelsQuery

  let query = supabaseAdmin
    .from('amenity_orders')
    .select('id, hotel_id, room_number, guest_name, quantity, status, notes, created_at, hotel_amenities(name, category, price, currency)')
    .order('created_at', { ascending: false })
    .limit(200)

  if (hotelFilter) query = query.eq('hotel_id', hotelFilter)
  if (statusFilter) query = query.eq('status', statusFilter)

  const { data: orders } = await query

  const hotelMap = Object.fromEntries((hotels ?? []).map(h => [h.id, h.name]))
  const statuses = ['open', 'confirmed', 'delivered', 'cancelled']

  async function updateOrderStatus(fd: FormData) {
    'use server'
    const viewerAction = await verifyDashboardViewerForAction()
    if (!viewerAction) redirect('/login')

    const id = fd.get('id') as string
    const status = fd.get('status') as string
    if (!id || !status) return

    const { data: row } = await supabaseAdmin
      .from('amenity_orders')
      .select('hotel_id')
      .eq('id', id)
      .maybeSingle()
    if (!row?.hotel_id) return
    assertHotelMutationAllowed(viewerAction, row.hotel_id)

    await supabaseAdmin
      .from('amenity_orders')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', id)
    revalidatePath('/dashboard/guest-orders')
  }

  const hotelTier = viewer.isHotelTierAdmin && viewer.hotelId

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-6">🍽️ הזמנות אורחים</h1>

      <form method="GET" className="flex flex-wrap gap-3 mb-6 bg-gray-50 p-4 rounded-xl border">
        <select
          name="hotel"
          defaultValue={hotelFilter ?? ''}
          className="border rounded-lg px-3 py-2 text-sm"
          disabled={!!hotelTier}
        >
          {!hotelTier && <option value="">כל המלונות</option>}
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

        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">
          סנן
        </button>
        <a href="/dashboard/guest-orders" className="text-sm text-gray-500 hover:text-gray-800 py-2 px-2">
          נקה
        </a>
      </form>

      {!orders || orders.length === 0 ? (
        <p className="text-gray-500 py-12 text-center">אין הזמנות</p>
      ) : (
        <div className="overflow-x-auto rounded-xl border">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">מלון</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">חדר</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">אורח</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">פריט</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">כמות</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">מחיר</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">סטטוס</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">עדכן ל-</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תאריך</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {orders.map(o => {
                const amenity = Array.isArray(o.hotel_amenities) ? o.hotel_amenities[0] : o.hotel_amenities
                return (
                  <tr key={o.id} className="hover:bg-gray-50 align-top">
                    <td className="px-4 py-3 text-gray-700">{hotelMap[o.hotel_id] ?? o.hotel_id.slice(0, 8)}</td>
                    <td className="px-4 py-3 font-medium">{o.room_number}</td>
                    <td className="px-4 py-3 text-gray-700">{o.guest_name}</td>
                    <td className="px-4 py-3">
                      {amenity ? `${CATEGORY_LABELS[amenity.category] ?? amenity.category} · ${amenity.name}` : '—'}
                    </td>
                    <td className="px-4 py-3">{o.quantity}</td>
                    <td className="px-4 py-3 text-gray-700">
                      {amenity?.price != null ? `${amenity.price * o.quantity} ${amenity.currency}` : '—'}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${STATUS_COLORS[o.status] ?? 'bg-gray-100 text-gray-500'}`}>
                        {STATUS_LABELS[o.status] ?? o.status}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <form action={updateOrderStatus} className="flex items-center gap-2">
                        <input type="hidden" name="id" value={o.id} />
                        <select name="status" defaultValue={o.status} className="border rounded px-2 py-1 text-xs">
                          {statuses.map(s => (
                            <option key={s} value={s}>{STATUS_LABELS[s]}</option>
                          ))}
                        </select>
                        <button type="submit" className="text-xs bg-gray-900 text-white px-2 py-1 rounded hover:bg-gray-700">
                          ✓
                        </button>
                      </form>
                    </td>
                    <td className="px-4 py-3 text-gray-500 whitespace-nowrap">{fmtDate(o.created_at)}</td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
