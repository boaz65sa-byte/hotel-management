// supabase/functions/send-push/index.ts
// Receives Supabase Database Webhooks and sends push notifications via OneSignal REST API.
//
// Required Supabase secrets:
//   ONESIGNAL_APP_ID        — OneSignal App ID
//   ONESIGNAL_REST_API_KEY  — OneSignal REST API Key
//   WEBHOOK_SECRET          — shared secret to authenticate webhook calls

const ONESIGNAL_URL = 'https://onesignal.com/api/v1/notifications'

const CATEGORY_HE: Record<string, string> = {
  housekeeping: 'חדרניות',
  maintenance:  'תחזוקה',
  reception:    'קבלה',
}

const STATUS_HE: Record<string, string> = {
  in_progress: 'בטיפול',
  resolved:    'טופלה',
  assigned:    'הוקצתה',
  cancelled:   'בוטלה',
}

const PRIORITY_HE: Record<string, string> = {
  low:      'נמוכה',
  medium:   'בינונית',
  high:     'גבוהה',
  critical: 'קריטית',
}

// role → OneSignal tag value for "dept"
const ROLE_TO_DEPT: Record<string, string> = {
  housekeeping:         'housekeeping',
  housekeeping_manager: 'housekeeping',
  maintenance:          'maintenance',
  maintenance_manager:  'maintenance',
  maintenance_tech:     'maintenance',
  receptionist:         'reception',
  reception_manager:    'reception',
  hotel_admin:          'reception',
}

interface OneSignalFilter {
  field?: string
  key?: string
  relation?: string
  value?: string
  operator?: 'AND' | 'OR'
}

async function sendNotification(
  appId: string,
  restKey: string,
  filters: OneSignalFilter[],
  titleHe: string,
  bodyHe: string,
) {
  const res = await fetch(ONESIGNAL_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${restKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      app_id:   appId,
      filters,
      headings: { en: titleHe, he: titleHe },
      contents: { en: bodyHe,  he: bodyHe },
      ios_sound: 'default',
      android_sound: 'default',
    }),
  })
  if (!res.ok) {
    const err = await res.text()
    console.error(`OneSignal API error: ${err}`)
  }
}

function tagFilter(key: string, value: string): OneSignalFilter {
  return { field: 'tag', key, relation: '=', value }
}
const AND: OneSignalFilter = { operator: 'AND' }

Deno.serve(async (req) => {
  // Authenticate webhook call
  const secret = Deno.env.get('WEBHOOK_SECRET') ?? ''
  if (req.headers.get('x-webhook-secret') !== secret) {
    return new Response('Unauthorized', { status: 401 })
  }

  const appId   = Deno.env.get('ONESIGNAL_APP_ID') ?? ''
  const restKey = Deno.env.get('ONESIGNAL_REST_API_KEY') ?? ''
  if (!appId || !restKey) {
    console.error('Missing OneSignal secrets')
    return new Response('Server error', { status: 500 })
  }

  const eventType = req.headers.get('x-event-type') ?? ''
  const payload = await req.json()
  const record    = payload.record    ?? {}
  const oldRecord = payload.old_record ?? {}

  try {
    switch (eventType) {

      // ── New guest request ────────────────────────────────────────────────
      case 'guest_request_insert': {
        const { hotel_id, room_number, category, assigned_dept } = record
        const dept = ROLE_TO_DEPT[assigned_dept ?? category] ?? (assigned_dept ?? category)
        const catHe = CATEGORY_HE[category] ?? category

        // Notify the relevant dept staff
        await sendNotification(appId, restKey,
          [tagFilter('hotel_id', hotel_id), AND, tagFilter('dept', dept)],
          `בקשה חדשה · חדר ${room_number}`,
          catHe,
        )
        // Also notify managers
        await sendNotification(appId, restKey,
          [tagFilter('hotel_id', hotel_id), AND, tagFilter('dept', 'managers')],
          `בקשה חדשה · חדר ${room_number}`,
          catHe,
        )
        break
      }

      // ── Guest request status changed ─────────────────────────────────────
      case 'guest_request_status': {
        const newStatus = record.status
        const oldStatus = oldRecord.status
        if (newStatus === oldStatus) break
        if (!['in_progress', 'resolved', 'cancelled'].includes(newStatus)) break

        const { hotel_id, room_number } = record
        const statusHe = STATUS_HE[newStatus] ?? newStatus

        // Notify the guest (PWA, tagged by hotel_id + room_number + type=guest)
        await sendNotification(appId, restKey,
          [
            tagFilter('hotel_id',    hotel_id),
            AND,
            tagFilter('room_number', room_number),
            AND,
            tagFilter('type', 'guest'),
          ],
          `הבקשה שלך ${statusHe}`,
          `חדר ${room_number}`,
        )
        break
      }

      // ── New ticket ───────────────────────────────────────────────────────
      case 'ticket_insert': {
        const { hotel_id, title, assigned_dept, priority } = record
        const dept = ROLE_TO_DEPT[assigned_dept] ?? assigned_dept
        const priorityHe = PRIORITY_HE[priority] ?? priority

        await sendNotification(appId, restKey,
          [tagFilter('hotel_id', hotel_id), AND, tagFilter('dept', dept)],
          `קריאה חדשה · ${priorityHe}`,
          title ?? '',
        )
        await sendNotification(appId, restKey,
          [tagFilter('hotel_id', hotel_id), AND, tagFilter('dept', 'managers')],
          `קריאה חדשה · ${priorityHe}`,
          title ?? '',
        )
        break
      }

      // ── Ticket assigned to specific user ─────────────────────────────────
      case 'ticket_assigned': {
        const supabaseUrl = Deno.env.get('SUPABASE_URL')!
        const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
        const ticketRes   = await fetch(
          `${supabaseUrl}/rest/v1/tickets?id=eq.${record.ticket_id}&select=title`,
          { headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` } }
        )
        const tickets = await ticketRes.json()
        const ticketTitle = tickets[0]?.title ?? ''

        await sendNotification(appId, restKey,
          [tagFilter('user_id', record.assigned_to)],
          'קריאה הוקצתה לך',
          ticketTitle,
        )
        break
      }

      default:
        console.warn(`Unknown event type: ${eventType}`)
    }
  } catch (err) {
    console.error('send-push error:', err)
    return new Response('Internal error', { status: 500 })
  }

  return new Response('ok', { status: 200 })
})
