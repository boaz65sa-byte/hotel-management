import { NextResponse } from 'next/server'
import { requireSuperAdmin } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

export async function GET(req: Request) {
  await requireSuperAdmin()
  const { searchParams } = new URL(req.url)
  const hotelId = searchParams.get('hotel_id')

  let query = supabaseAdmin
    .from('scheduled_tasks')
    .select('*, hotels(name)')
    .order('next_run_at')

  if (hotelId) query = query.eq('hotel_id', hotelId)

  const { data, error } = await query
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function POST(req: Request) {
  await requireSuperAdmin()
  const body = await req.json()
  const { hotel_id, room_id, title, description, recurrence, assigned_role, next_run_at } = body

  if (!hotel_id || !title || !recurrence || !assigned_role || !next_run_at) {
    return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
  }

  const { data, error } = await supabaseAdmin
    .from('scheduled_tasks')
    .insert({ hotel_id, room_id, title, description, recurrence, assigned_role, next_run_at })
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data, { status: 201 })
}
