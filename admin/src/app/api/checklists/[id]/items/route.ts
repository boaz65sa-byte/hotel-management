import { NextResponse } from 'next/server'
import { requireSuperAdmin } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  await requireSuperAdmin()
  const { id } = await params
  const { data, error } = await supabaseAdmin
    .from('checklist_items')
    .select('id, order_index, title_he, title_en, requires_photo')
    .eq('template_id', id)
    .order('order_index')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function POST(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  await requireSuperAdmin()
  const { id } = await params
  const { title_he, title_en, requires_photo, order_index } = await req.json()
  if (!title_he) {
    return NextResponse.json({ error: 'title_he required' }, { status: 400 })
  }

  let nextOrder = order_index
  if (typeof nextOrder !== 'number') {
    const { data: max } = await supabaseAdmin
      .from('checklist_items')
      .select('order_index')
      .eq('template_id', id)
      .order('order_index', { ascending: false })
      .limit(1)
      .maybeSingle()
    nextOrder = (max?.order_index ?? 0) + 1
  }

  const { data, error } = await supabaseAdmin
    .from('checklist_items')
    .insert({
      template_id: id,
      title_he,
      title_en: title_en ?? null,
      requires_photo: !!requires_photo,
      order_index: nextOrder,
    })
    .select()
    .single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data, { status: 201 })
}
