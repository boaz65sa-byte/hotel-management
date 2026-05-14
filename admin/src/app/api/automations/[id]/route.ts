import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'

import { authGuard } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

const ALLOWED = ['title', 'description', 'recurrence', 'assigned_role', 'next_run_at', 'is_active'] as const

async function assertTaskAccess(session: NonNullable<Awaited<ReturnType<typeof authGuard>>>, taskId: string) {
  const { data: task, error } = await supabaseAdmin
    .from('scheduled_tasks')
    .select('hotel_id')
    .eq('id', taskId)
    .single()
  if (error || !task) return { error: NextResponse.json({ error: 'Not found' }, { status: 404 }) }
  if (!session.isSuperAdmin) {
    if (!session.hotelId || task.hotel_id !== session.hotelId) {
      return { error: NextResponse.json({ error: 'Forbidden' }, { status: 403 }) }
    }
  }
  return { task }
}

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const session = await authGuard(req)
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const { id } = await params
  const gate = await assertTaskAccess(session, id)
  if ('error' in gate && gate.error) return gate.error

  const body = await req.json()
  const safe: Record<string, unknown> = {}
  for (const key of ALLOWED) { if (key in body) safe[key] = body[key] }

  const { data, error } = await supabaseAdmin
    .from('scheduled_tasks')
    .update(safe)
    .eq('id', id)
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const session = await authGuard(req)
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  const { id } = await params
  const gate = await assertTaskAccess(session, id)
  if ('error' in gate && gate.error) return gate.error

  const { error } = await supabaseAdmin.from('scheduled_tasks').delete().eq('id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return new NextResponse(null, { status: 204 })
}
