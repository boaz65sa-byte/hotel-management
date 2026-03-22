// supabase/functions/export-excel/index.ts
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

  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace('Bearer ', '')
  )
  if (authError || !user) return new Response('Unauthorized', { status: 401 })

  const { data: profile } = await supabase
    .from('users')
    .select('hotel_id, role')
    .eq('id', user.id)
    .single()

  const managerRoles = ['ceo','reception_manager','maintenance_manager',
                        'housekeeping_manager','security_manager','super_admin']
  if (!profile || !managerRoles.includes(profile.role)) {
    return new Response('Forbidden', { status: 403 })
  }

  const { hotel_id } = profile
  const body = await req.json().catch(() => ({}))
  const { from_date, to_date } = body

  let query = supabase
    .from('tickets')
    .select(`
      id, title, assigned_dept, priority, status, resolution_type,
      sla_deadline, created_at, resolved_at,
      opened_by:users!tickets_opened_by_fkey(full_name),
      claimed_by:users!tickets_claimed_by_fkey(full_name),
      room:rooms(room_number, floor)
    `)
    .eq('hotel_id', hotel_id)
    .order('created_at', { ascending: false })

  if (from_date) query = query.gte('created_at', from_date)
  if (to_date)   query = query.lte('created_at', to_date)

  const { data: tickets, error } = await query
  if (error) return new Response(JSON.stringify({ error }), { status: 500 })

  const headers = ['ID','Room','Floor','Department','Title','Priority',
                   'Status','Resolution','Opened By','Claimed By',
                   'Created','Resolved','SLA Deadline']
  const rows = (tickets ?? []).map((t: any) => [
    t.id, t.room?.room_number, t.room?.floor, t.assigned_dept, t.title,
    t.priority, t.status, t.resolution_type ?? '',
    t.opened_by?.full_name ?? '', t.claimed_by?.full_name ?? '',
    t.created_at, t.resolved_at ?? '', t.sla_deadline ?? ''
  ])

  const csv = [headers, ...rows].map(r => r.join(',')).join('\n')

  return new Response(csv, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/csv',
      'Content-Disposition': 'attachment; filename=tickets-export.csv'
    }
  })
})
