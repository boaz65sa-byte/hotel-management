import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'

import { authGuard } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

// Only revocation is supported here — activation happens exclusively via the
// redeem_hotel_license() RPC called from the hotel-creation wizard, never
// through this route, so an already-active code can't be tampered with.
export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const session = await authGuard(req)
  if (!session || !session.isSuperAdmin) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const { id } = await params
  const body = await req.json().catch(() => ({}))
  if (body.status !== 'revoked') {
    return NextResponse.json({ error: 'Only revoking is supported' }, { status: 400 })
  }

  const { data, error } = await supabaseAdmin
    .from('hotel_licenses')
    .update({ status: 'revoked' })
    .eq('id', id)
    .eq('status', 'unused') // can't revoke an already-active/redeemed license
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  if (!data) return NextResponse.json({ error: 'Not found or not revocable' }, { status: 409 })
  return NextResponse.json(data)
}
