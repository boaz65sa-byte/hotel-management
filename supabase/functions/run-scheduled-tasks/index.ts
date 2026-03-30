// supabase/functions/run-scheduled-tasks/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

function nextRunAt(recurrence: string): string {
  const now = new Date()
  switch (recurrence) {
    case 'daily':     now.setDate(now.getDate() + 1); break
    case 'weekly':    now.setDate(now.getDate() + 7); break
    case 'monthly':   now.setMonth(now.getMonth() + 1); break
    case 'quarterly': now.setMonth(now.getMonth() + 3); break
  }
  return now.toISOString()
}

Deno.serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  const cronSecret = Deno.env.get('CRON_SECRET')
  if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
    return new Response('Unauthorized', { status: 401 })
  }

  const now = new Date().toISOString()

  const { data: dueTasks, error: fetchError } = await supabase
    .from('scheduled_tasks')
    .select('*')
    .eq('is_active', true)
    .lte('next_run_at', now)

  if (fetchError) return new Response(fetchError.message, { status: 500 })
  if (!dueTasks || dueTasks.length === 0) {
    return new Response(JSON.stringify({ created: 0 }), { status: 200 })
  }

  let created = 0
  for (const task of dueTasks) {
    const { error: insertError } = await supabase.from('tickets').insert({
      hotel_id: task.hotel_id,
      room_id: task.room_id,
      title: task.title,
      description: task.description,
      assigned_dept: task.assigned_role,
      priority: 'normal',
      status: 'open',
      opened_by: task.hotel_id,
    })

    if (!insertError) {
      await supabase.from('scheduled_tasks').update({
        last_run_at: now,
        next_run_at: nextRunAt(task.recurrence),
      }).eq('id', task.id)
      created++
    }
  }

  return new Response(JSON.stringify({ created }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
})
