import { NextResponse } from 'next/server'
import { requireSuperAdmin } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

const ALLOWED = ['title_he', 'title_en', 'requires_photo', 'order_index'] as const

export async function PATCH(
  req: Request,
  { params }: { params: Promise<{ id: string; itemId: string }> },
) {
  await requireSuperAdmin()
  const { itemId } = await params
  const body = await req.json()
  const safe: Record<string, unknown> = {}
  for (const key of ALLOWED) if (key in body) safe[key] = body[key]
  const { data, error } = await supabaseAdmin
    .from('checklist_items')
    .update(safe)
    .eq('id', itemId)
    .select()
    .single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function DELETE(
  _req: Request,
  { params }: { params: Promise<{ id: string; itemId: string }> },
) {
  await requireSuperAdmin()
  const { itemId } = await params
  const { error } = await supabaseAdmin
    .from('checklist_items')
    .delete()
    .eq('id', itemId)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return new NextResponse(null, { status: 204 })
}
