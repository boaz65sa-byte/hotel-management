import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'

import { authGuard } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

const PLANS = ['basic', 'pro', 'enterprise'] as const

function generateSerial(): string {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789' // no 0/O/1/I ambiguity
  const group = () =>
    Array.from({ length: 4 }, () => alphabet[Math.floor(Math.random() * alphabet.length)]).join('')
  return `ROXN-${group()}-${group()}-${group()}`
}

export async function GET(req: NextRequest) {
  const session = await authGuard(req)
  if (!session || !session.isSuperAdmin) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const { data, error } = await supabaseAdmin
    .from('hotel_licenses')
    .select('*, hotels(name)')
    .order('issued_at', { ascending: false })

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function POST(req: NextRequest) {
  const session = await authGuard(req)
  if (!session || !session.isSuperAdmin) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const body = await req.json().catch(() => ({}))
  const plan = PLANS.includes(body.plan) ? body.plan : 'basic'
  const notes: string | null = typeof body.notes === 'string' ? body.notes.trim() || null : null

  // Extremely unlikely to collide, but retry once on unique-constraint conflict.
  for (let attempt = 0; attempt < 3; attempt++) {
    const { data, error } = await supabaseAdmin
      .from('hotel_licenses')
      .insert({
        serial_code: generateSerial(),
        plan,
        issued_by: session.userId,
        notes,
      })
      .select()
      .single()

    if (!error) return NextResponse.json(data, { status: 201 })
    if (!error.message.includes('duplicate')) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }
  }

  return NextResponse.json({ error: 'Failed to generate a unique code, try again' }, { status: 500 })
}
