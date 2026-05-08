// Server-side helper: checks if the request has a valid super_admin session
import { cookies } from 'next/headers'
import { NextRequest } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { redirect } from 'next/navigation'

// For API routes — returns session or null (no redirect)
export async function authGuard(req: NextRequest): Promise<{ access_token: string } | null> {
  const cookieHeader = req.headers.get('cookie') ?? ''
  const match = cookieHeader.match(/sb-access-token=([^;]+)/)
  const accessToken = match?.[1]
  if (!accessToken) return null

  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  )
  const { data: { user }, error } = await supabase.auth.getUser(accessToken)
  if (error || !user) return null

  const { data: profile } = await supabase
    .from('users').select('role').eq('id', user.id).single()
  if (profile?.role !== 'super_admin') return null

  return { access_token: accessToken }
}

export async function requireSuperAdmin() {
  const cookieStore = await cookies()
  const accessToken = cookieStore.get('sb-access-token')?.value
  // refreshToken is intentionally not used here — the client refreshes on its own
  // and we only need a fresh access token to verify role on each request.

  if (!accessToken) redirect('/login')

  // Verify token using service role (to check role claim)
  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  )

  const { data: { user }, error } = await supabase.auth.getUser(accessToken)
  if (error || !user) redirect('/login')

  // Check role from DB (not JWT, for server-side accuracy)
  const { data: profile } = await supabase
    .from('users').select('role').eq('id', user.id).single()

  if (profile?.role !== 'super_admin') redirect('/login')

  return user
}
