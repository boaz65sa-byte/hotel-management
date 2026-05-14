import { supabaseAdmin } from '@/lib/supabase-admin'
import { notFound } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { RoomsManager } from './rooms-manager'

export default async function HotelRoomsPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .eq('id', id)
    .single()
  if (!hotel) notFound()

  const { data: rooms } = await supabaseAdmin
    .from('rooms')
    .select('id, room_number, floor, room_type, status')
    .eq('hotel_id', id)
    .order('floor', { ascending: true })
    .order('room_number', { ascending: true })

  async function createRoom(formData: FormData) {
    'use server'
    const room_number = String(formData.get('room_number') ?? '').trim()
    const floor = formData.get('floor')
    const room_type = String(formData.get('room_type') ?? '').trim()
    const status = String(formData.get('status') ?? 'available')
    if (!room_number) return
    await supabaseAdmin.from('rooms').insert({
      hotel_id: id,
      room_number,
      floor: floor ? Number(floor) : null,
      room_type: room_type || null,
      status,
    })
    revalidatePath(`/dashboard/hotels/${id}/rooms`)
  }

  async function updateRoom(formData: FormData) {
    'use server'
    const roomId = String(formData.get('room_id') ?? '')
    if (!roomId) return
    const room_number = String(formData.get('room_number') ?? '').trim()
    const floor = formData.get('floor')
    const room_type = String(formData.get('room_type') ?? '').trim()
    const status = String(formData.get('status') ?? 'available')
    await supabaseAdmin
      .from('rooms')
      .update({
        room_number,
        floor: floor ? Number(floor) : null,
        room_type: room_type || null,
        status,
      })
      .eq('id', roomId)
    revalidatePath(`/dashboard/hotels/${id}/rooms`)
  }

  async function deleteRoom(formData: FormData) {
    'use server'
    const roomId = String(formData.get('room_id') ?? '')
    if (!roomId) return
    await supabaseAdmin.from('rooms').delete().eq('id', roomId)
    revalidatePath(`/dashboard/hotels/${id}/rooms`)
  }

  async function bulkAddRooms(
    formData: FormData,
  ): Promise<{ ok: boolean; created: number; skipped: number; error?: string }> {
    'use server'
    const floors           = Math.max(1, Number(formData.get('floors')        ?? 1))
    const rooms_per_floor  = Math.max(1, Number(formData.get('rooms_per_floor') ?? 1))
    const start_per_floor  = Math.max(1, Number(formData.get('start_per_floor') ?? 1))
    const skip_raw         = String(formData.get('skip_numbers') ?? '').trim()
    const room_type        = String(formData.get('room_type') ?? '').trim()

    const skip_numbers: number[] = skip_raw
      ? skip_raw.split(/[\s,]+/).map((n) => Number(n)).filter((n) => Number.isFinite(n))
      : []
    const skipSet = new Set(skip_numbers)

    const planned: string[] = []
    for (let f = 1; f <= floors; f++) {
      for (let r = 0; r < rooms_per_floor; r++) {
        const idx = start_per_floor + r
        if (skipSet.has(idx)) continue
        planned.push(`${f}${String(idx).padStart(2, '0')}`)
      }
    }
    if (planned.length === 0) {
      return { ok: false, created: 0, skipped: 0, error: 'No rooms to add' }
    }

    const { data: existing } = await supabaseAdmin
      .from('rooms')
      .select('room_number')
      .eq('hotel_id', id)
      .in('room_number', planned)
    const existingSet = new Set((existing ?? []).map((r) => r.room_number as string))

    const rows = planned
      .filter((n) => !existingSet.has(n))
      .map((n) => ({
        hotel_id:    id,
        room_number: n,
        floor:       Number(n.charAt(0)),
        room_type:   room_type || null,
        status:      'available',
      }))

    if (rows.length > 0) {
      const { error } = await supabaseAdmin.from('rooms').insert(rows)
      if (error) {
        return { ok: false, created: 0, skipped: planned.length, error: error.message }
      }
    }

    revalidatePath(`/dashboard/hotels/${id}/rooms`)
    return { ok: true, created: rows.length, skipped: planned.length - rows.length }
  }

  return (
    <div className="p-6" dir="rtl">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">חדרים — {hotel.name}</h1>
          <p className="text-sm text-gray-500 mt-1">
            הוסיפו חדרים, עדכנו סטטוס או מחקו חדרים שהוסרו מהמלון.
          </p>
        </div>
        <a
          href={`/dashboard/hotels/${id}`}
          className="text-sm text-blue-600 hover:underline"
        >
          ← חזרה למלון
        </a>
      </div>

      <RoomsManager
        hotelId={id}
        rooms={rooms ?? []}
        createRoom={createRoom}
        updateRoom={updateRoom}
        deleteRoom={deleteRoom}
        bulkAddRooms={bulkAddRooms}
      />
    </div>
  )
}
