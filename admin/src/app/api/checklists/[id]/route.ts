import { NextResponse } from 'next/server'
import { requireSuperAdmin } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

const ALLOWED = ['name', 'type', 'is_vip'] as const

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  await requireSuperAdmin()
  const { id } = await params
  const { data: template, error } = await supabaseAdmin
    .from('checklist_templates')
    .select('*')
    .eq('id', id)
    .single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })

  const { data: items } = await supabaseAdmin
    .from('checklist_items')
    .select('id, order_index, title_he, title_en, requires_photo')
    .eq('template_id', id)
    .order('order_index')

  return NextResponse.json({ template, items: items ?? [] })
}

export async function PATCH(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  await requireSuperAdmin()
  const { id } = await params
  const body = await req.json()
  const safe: Record<string, unknown> = {}
  for (const key of ALLOWED) if (key in body) safe[key] = body[key]
  const { data, error } = await supabaseAdmin
    .from('checklist_templates')
    .update(safe)
    .eq('id', id)
    .select()
    .single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function DELETE(
  _req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  await requireSuperAdmin()
  const { id } = await params
  const { error } = await supabaseAdmin
    .from('checklist_templates')
    .delete()
    .eq('id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return new NextResponse(null, { status: 204 })
}
