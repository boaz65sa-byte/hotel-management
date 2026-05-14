// supabase/functions/manage-user/index.ts
// Handles: create, update, delete users
// Called by: Super Admin (Next.js) and Hotel Admin (Flutter)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const managerRoles = [
  'ceo',
  'software_manager',
  'hotel_admin',
  'reception_manager',
  'maintenance_manager',
  'housekeeping_manager',
  'security_manager',
  'super_admin',
]

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Verify caller
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return new Response('Unauthorized', { status: 401 })

  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace('Bearer ', '')
  )
  if (authError || !user) return new Response('Unauthorized', { status: 401 })

  const { data: caller } = await supabase
    .from('users').select('hotel_id, role').eq('id', user.id).single()

  if (!caller || !managerRoles.includes(caller.role)) {
    return new Response('Forbidden', { status: 403 })
  }

  const isSuperAdmin = caller.role === 'super_admin'

  const body = await req.json()
  const { action } = body  // 'create' | 'update' | 'delete'

  // ── CREATE ──────────────────────────────────────────────────
  if (action === 'create') {
    const { email, full_name, password, role, hotel_id } = body

    if (!email || !full_name || !password || !role || !hotel_id) {
      return json({ error: 'Missing fields' }, 400)
    }

    if (role === 'super_admin' && !isSuperAdmin) {
      return new Response('Forbidden', { status: 403 })
    }

    // Hotel admins can only create for their own hotel
    if (!isSuperAdmin && caller.hotel_id !== hotel_id) {
      return new Response('Forbidden', { status: 403 })
    }

    const { data: created, error: createErr } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name },
      app_metadata: { role, hotel_id },
    })

    if (createErr) return json({ error: createErr.message }, 400)

    await supabase.from('users').upsert({
      id: created.user.id,
      hotel_id,
      full_name,
      email,
      role,
      is_active: true,
    }, { onConflict: 'id' })

    return json({ id: created.user.id })
  }

  // ── UPDATE ──────────────────────────────────────────────────
  if (action === 'update') {
    const { user_id, full_name, role, hotel_id, is_active } = body

    if (!user_id) return json({ error: 'user_id required' }, 400)

    // Fetch target user to enforce hotel isolation
    const { data: target } = await supabase
      .from('users').select('hotel_id').eq('id', user_id).single()

    if (!target) return json({ error: 'User not found' }, 404)
    if (!isSuperAdmin && target.hotel_id !== caller.hotel_id) {
      return new Response('Forbidden', { status: 403 })
    }

    const updates: Record<string, unknown> = {}
    if (full_name !== undefined) updates.full_name = full_name
    if (role !== undefined) {
      if (!isSuperAdmin && role === 'super_admin') {
        return new Response('Forbidden', { status: 403 })
      }
      updates.role = role
    }
    if (hotel_id  !== undefined && isSuperAdmin) updates.hotel_id = hotel_id
    if (is_active !== undefined) updates.is_active  = is_active

    await supabase.from('users').update(updates).eq('id', user_id)

    // Sync app_metadata so JWT reflects changes on next login
    if (role !== undefined || hotel_id !== undefined) {
      const meta: Record<string, unknown> = {}
      if (role     !== undefined) meta.role     = role
      if (hotel_id !== undefined) meta.hotel_id = hotel_id
      await supabase.auth.admin.updateUserById(user_id, { app_metadata: meta })
    }

    return json({ ok: true })
  }

  // ── DELETE ──────────────────────────────────────────────────
  if (action === 'delete') {
    const { user_id } = body
    if (!user_id) return json({ error: 'user_id required' }, 400)

    // Only super_admin can delete
    if (!isSuperAdmin) return new Response('Forbidden', { status: 403 })

    await supabase.from('users').delete().eq('id', user_id)
    await supabase.auth.admin.deleteUser(user_id)

    return json({ ok: true })
  }

  return json({ error: 'Unknown action' }, 400)
})

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
