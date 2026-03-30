import { NextResponse } from 'next/server'
import { requireSuperAdmin } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

const ALLOWED = ['title', 'description', 'recurrence', 'assigned_role', 'next_run_at', 'is_active'] as const

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  await requireSuperAdmin()
  const { id } = await params
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

export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  await requireSuperAdmin()
  const { id } = await params
  const { error } = await supabaseAdmin.from('scheduled_tasks').delete().eq('id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return new NextResponse(null, { status: 204 })
}
