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
        rooms={rooms ?? []}
        createRoom={createRoom}
        updateRoom={updateRoom}
        deleteRoom={deleteRoom}
      />
    </div>
  )
}
