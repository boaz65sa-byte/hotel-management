// Server-side helper: checks if the request has a valid super_admin session
import { cookies } from 'next/headers'
import { createClient } from '@supabase/supabase-js'
import { redirect } from 'next/navigation'

export async function requireSuperAdmin() {
  const cookieStore = await cookies()
  const accessToken = cookieStore.get('sb-access-token')?.value
  const refreshToken = cookieStore.get('sb-refresh-token')?.value

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
