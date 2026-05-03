# Phase 11a — Push Edge Function + SQL Tables Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `send-push` Supabase Edge Function that sends OneSignal push notifications when guest requests and tickets change.

**Architecture:** Supabase Database Webhooks POST to a Deno Edge Function. The function calls the OneSignal REST API with tag-based filters to target the right audience. No token storage tables needed — OneSignal manages subscriptions. Only the SQL for the one-time webhook secret setup is manual.

**Tech Stack:** Deno + Supabase Edge Functions + OneSignal REST API

---

## ⚠️ Prerequisites (Manual — Developer Must Do First)

1. Create OneSignal account at [onesignal.com](https://onesignal.com)
2. Create new App → add platforms: Google Android + Apple iOS + Web Push
3. Copy **App ID** and **REST API Key** from OneSignal → Settings → Keys & IDs
4. In Supabase Dashboard → Settings → Edge Function Secrets, add:
   - `ONESIGNAL_APP_ID` = your App ID
   - `ONESIGNAL_REST_API_KEY` = your REST API Key
   - `WEBHOOK_SECRET` = any random string (run `openssl rand -hex 32` to generate)

---

## File Map

| Action | File |
|--------|------|
| Create | `supabase/functions/send-push/index.ts` |
| Manual (Supabase Dashboard) | 4 Database Webhooks + secrets |

---

### Task 1: Create `send-push` Edge Function

**Files:**
- Create: `supabase/functions/send-push/index.ts`

- [ ] **Step 1: Create directory**

```bash
mkdir -p "/Users/boazsaada/manegmant resapceon/supabase/functions/send-push"
```

- [ ] **Step 2: Create the function**

Create `supabase/functions/send-push/index.ts`:

```typescript
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
        // Also notify managers (reception dept handles escalation)
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
        // Need ticket title — fetch from DB
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
```

- [ ] **Step 3: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add supabase/functions/send-push/ && git commit -m "feat: add send-push Edge Function using OneSignal REST API"
```

---

### Task 2: Configure Database Webhooks (Manual — Supabase Dashboard)

After deploying the function, configure 4 webhooks in Supabase Dashboard → Database → Webhooks.

URL for all webhooks: `{your-supabase-url}/functions/v1/send-push`

- [ ] **Webhook 1: New guest request**
  - Name: `push_guest_request_insert`
  - Table: `guest_requests` | Event: INSERT
  - Headers: `x-webhook-secret: <your WEBHOOK_SECRET>`, `x-event-type: guest_request_insert`

- [ ] **Webhook 2: Guest request status update**
  - Name: `push_guest_request_update`
  - Table: `guest_requests` | Event: UPDATE
  - Headers: `x-webhook-secret: <your WEBHOOK_SECRET>`, `x-event-type: guest_request_status`

- [ ] **Webhook 3: New ticket**
  - Name: `push_ticket_insert`
  - Table: `tickets` | Event: INSERT
  - Headers: `x-webhook-secret: <your WEBHOOK_SECRET>`, `x-event-type: ticket_insert`

- [ ] **Webhook 4: Ticket assigned**
  - Name: `push_ticket_assigned`
  - Table: `ticket_assignments` | Event: INSERT
  - Headers: `x-webhook-secret: <your WEBHOOK_SECRET>`, `x-event-type: ticket_assigned`

- [ ] **Test:** Insert a row in `guest_requests` → check Edge Function logs → should see `200 ok`
