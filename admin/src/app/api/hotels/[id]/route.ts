// admin/src/app/api/hotels/[id]/route.ts — theme/name for hotel-tier; full patch for super.
import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'

import { authGuard } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

const SUPER_FIELDS = ['theme', 'name', 'is_active'] as const
const HOTEL_TIER_FIELDS = ['theme', 'name'] as const

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await authGuard(req)
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const body = await req.json()
  const { id } = await params

  const keys = session.isSuperAdmin ? SUPER_FIELDS : HOTEL_TIER_FIELDS
  if (!session.isSuperAdmin) {
    if (!session.hotelId || session.hotelId !== id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }
  }

  const safe: Record<string, unknown> = {}
  for (const key of keys) {
    if (key in body) safe[key] = body[key]
  }

  const { data, error } = await supabaseAdmin
    .from('hotels')
    .update(safe)
    .eq('id', id)
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json(data)
}
