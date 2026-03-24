// supabase/functions/invite-user/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return new Response('Unauthorized', { status: 401 })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Verify caller is a manager
  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace('Bearer ', '')
  )
  if (authError || !user) return new Response('Unauthorized', { status: 401 })

  const { data: profile } = await supabase
    .from('users')
    .select('hotel_id, role')
    .eq('id', user.id)
    .single()

  const managerRoles = ['ceo', 'reception_manager', 'maintenance_manager',
                        'housekeeping_manager', 'security_manager', 'super_admin']
  if (!profile || !managerRoles.includes(profile.role)) {
    return new Response('Forbidden', { status: 403 })
  }

  const { email, full_name, role, hotel_id } = await req.json()
  if (!email || !full_name || !role || !hotel_id) {
    return new Response('Missing fields', { status: 400 })
  }

  // Hotel managers can only invite users to their own hotel
  if (profile.role !== 'super_admin' && profile.hotel_id !== hotel_id) {
    return new Response('Forbidden', { status: 403 })
  }

  // Invite via Supabase Auth — sends email with magic link
  const { data: invited, error: inviteError } = await supabase.auth.admin.inviteUserByEmail(
    email,
    {
      data: { full_name, role, hotel_id },
      redirectTo: Deno.env.get('INVITE_REDIRECT_URL') ?? undefined,
    }
  )
  if (inviteError) {
    return new Response(JSON.stringify({ error: inviteError.message }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Upsert into users table (trigger may also handle this, but be explicit)
  await supabase.from('users').upsert({
    id: invited.user.id,
    hotel_id,
    full_name,
    email,
    role,
    is_active: true,
  }, { onConflict: 'id' })

  return new Response(JSON.stringify({ id: invited.user.id }), {
    status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
