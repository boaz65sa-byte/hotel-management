import { NextResponse } from 'next/server'
import { requireSuperAdmin } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

export async function GET() {
  await requireSuperAdmin()
  const { data, error } = await supabaseAdmin
    .from('checklist_templates')
    .select('*, checklist_items(count)')
    .order('name')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function POST(req: Request) {
  await requireSuperAdmin()
  const { name, type, is_vip } = await req.json()
  if (!name || !type) return NextResponse.json({ error: 'name and type required' }, { status: 400 })
  const { data, error } = await supabaseAdmin
    .from('checklist_templates')
    .insert({ name, type, is_vip: is_vip ?? false })
    .select()
    .single()
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data, { status: 201 })
}
