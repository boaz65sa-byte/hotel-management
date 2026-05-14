// api/hotels/route.ts — list hotels for dropdowns
import { authGuard } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'
import { NextRequest, NextResponse } from 'next/server'

export async function GET(req: NextRequest) {
  const session = await authGuard(req)
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!session.isSuperAdmin) {
    if (!session.hotelId) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    const { data } = await supabaseAdmin
      .from('hotels')
      .select('id, name')
      .eq('id', session.hotelId)
      .order('name')
    return NextResponse.json(data ?? [])
  }

  const { data } = await supabaseAdmin.from('hotels').select('id, name').order('name')
  return NextResponse.json(data ?? [])
}
