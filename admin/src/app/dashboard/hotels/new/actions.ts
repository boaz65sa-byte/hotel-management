'use server'

import { supabaseAdmin } from '@/lib/supabase-admin'
import { revalidatePath } from 'next/cache'

export type WizardInput = {
  hotel: {
    name: string
    subscription_plan: string
    default_sla_hours: number
    default_language: string
    theme: string
    is_active: boolean
    stay_threshold: number
    guest_pwa_url?: string
    logo_url?: string
    address?: string
    city?: string
    country?: string
    phone?: string
    email?: string
  }
  rooms: {
    floors: number
    rooms_per_floor: number
    start_per_floor: number
    skip_numbers?: number[]
  } | null
  users: Array<{ full_name: string; email: string; role: string }>
}

export type WizardResult = {
  ok: boolean
  hotelId?: string
  roomsCreated?: number
  errors?: { step: 'hotel' | 'rooms' | 'users'; message: string; userIndex?: number }[]
}

export async function setupHotelAction(input: WizardInput): Promise<WizardResult> {
  const errors: WizardResult['errors'] = []

  // 1. Insert hotel
  const storageQuota =
    input.hotel.subscription_plan === 'enterprise' ? 200
    : input.hotel.subscription_plan === 'pro' ? 50
    : 10

  const hotelPayload = {
    name: input.hotel.name,
    subscription_plan: input.hotel.subscription_plan,
    default_sla_hours: input.hotel.default_sla_hours,
    default_language: input.hotel.default_language,
    theme: input.hotel.theme || 'clean_blue',
    is_active: input.hotel.is_active,
    stay_threshold: input.hotel.stay_threshold,
    storage_quota_gb: storageQuota,
    ...(input.hotel.guest_pwa_url?.trim() ? { guest_pwa_url: input.hotel.guest_pwa_url.trim() } : {}),
    ...(input.hotel.logo_url?.trim()      ? { logo_url:      input.hotel.logo_url.trim()      } : {}),
    ...(input.hotel.address?.trim()       ? { address:       input.hotel.address.trim()       } : {}),
    ...(input.hotel.city?.trim()          ? { city:          input.hotel.city.trim()          } : {}),
    ...(input.hotel.country?.trim()       ? { country:       input.hotel.country.trim()       } : {}),
    ...(input.hotel.phone?.trim()         ? { phone:         input.hotel.phone.trim()         } : {}),
    ...(input.hotel.email?.trim()         ? { email:         input.hotel.email.trim()         } : {}),
  }

  const { data: hotelRow, error: hotelErr } = await supabaseAdmin
    .from('hotels')
    .insert(hotelPayload)
    .select('id')
    .single()

  if (hotelErr || !hotelRow) {
    return {
      ok: false,
      errors: [{ step: 'hotel', message: hotelErr?.message ?? 'Failed to create hotel' }],
    }
  }

  const hotelId = hotelRow.id
  let roomsCreated = 0

  // 2. Bulk insert rooms
  if (input.rooms) {
    const { floors, rooms_per_floor, start_per_floor, skip_numbers = [] } = input.rooms
    const skipSet = new Set(skip_numbers)
    const roomRows: { hotel_id: string; room_number: string; floor: number }[] = []

    for (let f = 1; f <= floors; f++) {
      for (let r = 0; r < rooms_per_floor; r++) {
        const roomIndex = start_per_floor + r
        if (skipSet.has(roomIndex)) continue
        const pad = String(roomIndex).padStart(2, '0')
        const roomNumber = `${f}${pad}`
        roomRows.push({ hotel_id: hotelId, room_number: roomNumber, floor: f })
      }
    }

    if (roomRows.length > 0) {
      const { error: roomsErr } = await supabaseAdmin.from('rooms').insert(roomRows)
      if (roomsErr) {
        errors.push({ step: 'rooms', message: roomsErr.message })
      } else {
        roomsCreated = roomRows.length
      }
    }
  }

  // 3. Invite users
  for (let i = 0; i < input.users.length; i++) {
    const { full_name, email, role } = input.users[i]
    try {
      const { data: inviteData, error: inviteErr } = await supabaseAdmin.auth.admin.inviteUserByEmail(
        email,
        {
          data: { full_name, role, hotel_id: hotelId },
          redirectTo: process.env.INVITE_REDIRECT_URL,
        },
      )
      if (inviteErr || !inviteData?.user) {
        errors.push({ step: 'users', message: inviteErr?.message ?? 'Invite failed', userIndex: i })
        continue
      }
      await supabaseAdmin.from('users').upsert({
        id: inviteData.user.id,
        hotel_id: hotelId,
        full_name,
        email,
        role,
        is_active: true,
      })
    } catch (e) {
      errors.push({
        step: 'users',
        message: e instanceof Error ? e.message : 'Unknown error',
        userIndex: i,
      })
    }
  }

  revalidatePath('/dashboard/hotels')

  return {
    ok: true,
    hotelId,
    roomsCreated,
    errors: errors.length ? errors : undefined,
  }
}
