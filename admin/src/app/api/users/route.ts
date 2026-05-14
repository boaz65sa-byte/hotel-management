// api/users/route.ts — proxies create/update/delete to manage-user edge function
import { authGuard } from '@/lib/auth-guard'
import { NextRequest, NextResponse } from 'next/server'

const SUPABASE_URL = process.env.SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY!

export async function POST(req: NextRequest) {
  const session = await authGuard(req)
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const body = await req.json()
  const { action } = body as { action?: string }

  if (!session.isSuperAdmin && session.hotelId) {
    if (action === 'create') {
      if (body.hotel_id !== session.hotelId) {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
    }
    if (action === 'update') {
      if (typeof body.role === 'string' && body.role === 'super_admin') {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
      if (
        typeof body.hotel_id === 'string' &&
        body.hotel_id.length > 0 &&
        body.hotel_id !== session.hotelId
      ) {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
    }
  }

  const res = await fetch(`${SUPABASE_URL}/functions/v1/manage-user`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${session.access_token}`,
      'apikey': SUPABASE_ANON_KEY,
    },
    body: JSON.stringify(body),
  })

  const data = await res.json()
  return NextResponse.json(data, { status: res.status })
}
