// admin/src/app/api/hotels/[id]/route.ts
import { supabaseAdmin } from '@/lib/supabase-admin'
import { requireSuperAdmin } from '@/lib/auth-guard'

const ALLOWED_FIELDS = ['theme', 'name', 'is_active'] as const
type AllowedField = typeof ALLOWED_FIELDS[number]

export async function PATCH(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  await requireSuperAdmin()
  const body = await req.json()

  // Whitelist — never allow arbitrary DB writes
  const safe: Partial<Record<AllowedField, unknown>> = {}
  for (const key of ALLOWED_FIELDS) {
    if (key in body) safe[key] = body[key]
  }

  const { id } = await params

  const { data, error } = await supabaseAdmin
    .from('hotels')
    .update(safe)
    .eq('id', id)
    .select()
    .single()

  if (error) return Response.json({ error: error.message }, { status: 400 })
  return Response.json(data)
}
