import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'

import { authGuard } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

export async function GET(req: NextRequest) {
  const session = await authGuard(req)
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { searchParams } = new URL(req.url)
  let hotelId = searchParams.get('hotel_id')

  if (!session.isSuperAdmin) {
    if (!session.hotelId) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    hotelId = session.hotelId
  }

  let query = supabaseAdmin
    .from('scheduled_tasks')
    .select('*, hotels(name)')
    .order('next_run_at')

  if (hotelId) query = query.eq('hotel_id', hotelId)

  const { data, error } = await query
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function POST(req: NextRequest) {
  const session = await authGuard(req)
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const body = await req.json()
  const { hotel_id, room_id, title, description, recurrence, assigned_role, next_run_at } = body

  if (!hotel_id || !title || !recurrence || !assigned_role || !next_run_at) {
    return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
  }

  if (!session.isSuperAdmin) {
    if (!session.hotelId || hotel_id !== session.hotelId) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }
  }

  const { data, error } = await supabaseAdmin
    .from('scheduled_tasks')
    .insert({ hotel_id, room_id, title, description, recurrence, assigned_role, next_run_at })
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data, { status: 201 })
}
