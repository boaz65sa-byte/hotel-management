// api/hotel-departments/route.ts — list a hotel's custom departments for
// the user create/edit forms' department picker (only relevant when role
// is custom_dept_manager/custom_dept_staff).
import { authGuard } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'
import { NextRequest, NextResponse } from 'next/server'

export async function GET(req: NextRequest) {
  const session = await authGuard(req)
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const hotelId = req.nextUrl.searchParams.get('hotel_id')
  if (!hotelId) return NextResponse.json([])

  if (!session.isSuperAdmin && session.hotelId !== hotelId) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const { data } = await supabaseAdmin
    .from('hotel_departments')
    .select('id, key, label, icon, is_active')
    .eq('hotel_id', hotelId)
    .eq('is_active', true)
    .order('label')

  return NextResponse.json(data ?? [])
}
