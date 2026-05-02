# Phase 11a — Push Edge Function + DB Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `send-push` Supabase Edge Function that sends FCM notifications, plus the two token-storage tables.

**Architecture:** Supabase Database Webhooks POST to a Deno Edge Function. The function calls the FCM Legacy HTTP API using a Server Key stored as a Supabase secret. Two tables store device tokens: `user_push_tokens` for staff, `guest_push_tokens` for PWA guests.

**Tech Stack:** Deno + Supabase Edge Functions + FCM Legacy HTTP API

---

## ⚠️ Prerequisites (Manual — Developer Must Do First)

Before writing any code:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Project Settings → Cloud Messaging → **Server Key** (Legacy) → copy it
3. In Supabase Dashboard → Settings → Edge Functions secrets:
   - `FCM_SERVER_KEY` = the copied server key
   - `WEBHOOK_SECRET` = any random string (e.g. `openssl rand -hex 32`)
4. Configure 4 Database Webhooks (after the function is deployed) — instructions in Task 3

---

## File Map

| Action | File |
|--------|------|
| SQL (manual) | Supabase SQL Editor — create 2 tables |
| Create | `supabase/functions/send-push/index.ts` |
| Reference | `supabase/functions/invite-user/index.ts` — follow this pattern |

---

### Task 1: Create token storage tables (SQL — run in Supabase Dashboard)

- [ ] **Step 1: Run in Supabase SQL Editor**

```sql
-- Staff FCM tokens (one per user, upserted on login)
CREATE TABLE IF NOT EXISTS user_push_tokens (
  user_id    UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token      TEXT        NOT NULL,
  platform   TEXT        NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id)
);

ALTER TABLE user_push_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users manage own token"
  ON user_push_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Guest PWA tokens (one per hotel+room combination)
CREATE TABLE IF NOT EXISTS guest_push_tokens (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id    UUID        NOT NULL,
  room_number TEXT        NOT NULL,
  token       TEXT        NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (hotel_id, room_number)
);

ALTER TABLE guest_push_tokens ENABLE ROW LEVEL SECURITY;

-- No public access — only Edge Functions (service_role) read/write
```

- [ ] **Step 2: Verify**

In Supabase Table Editor → confirm `user_push_tokens` and `guest_push_tokens` both exist.

---

### Task 2: Create `send-push` Edge Function

**Files:**
- Create: `supabase/functions/send-push/index.ts`

- [ ] **Step 1: Create the directory and file**

```bash
mkdir -p "/Users/boazsaada/manegmant resapceon/supabase/functions/send-push"
```

- [ ] **Step 2: Create the function**

Create `supabase/functions/send-push/index.ts` with the following content:

```typescript
// supabase/functions/send-push/index.ts
// Called by Supabase Database Webhooks when events occur on guest_requests, tickets, ticket_assignments.
// Sends FCM notifications via the FCM Legacy HTTP API.
//
// Required Supabase secrets:
//   FCM_SERVER_KEY   — Firebase project Server Key (Cloud Messaging settings)
//   WEBHOOK_SECRET   — shared secret to authenticate webhook calls
//   SUPABASE_URL     — auto-provided
//   SUPABASE_SERVICE_ROLE_KEY — auto-provided

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const FCM_URL = 'https://fcm.googleapis.com/fcm/send'

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

// dept → FCM topic suffix
const DEPT_TOPIC: Record<string, string> = {
  housekeeping: 'housekeeping',
  maintenance:  'maintenance',
  reception:    'reception',
}

// Roles that receive manager-level notifications
const MANAGER_ROLES = new Set([
  'reception_manager', 'hotel_admin', 'super_admin', 'housekeeping_manager', 'maintenance_manager',
])

async function sendToTopic(topic: string, title: string, body: string, serverKey: string) {
  const res = await fetch(FCM_URL, {
    method: 'POST',
    headers: {
      'Authorization': `key=${serverKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: `/topics/${topic}`,
      notification: { title, body },
      android: { priority: 'high' },
      apns: { headers: { 'apns-priority': '10' } },
    }),
  })
  if (!res.ok) {
    const err = await res.text()
    console.error(`FCM topic send failed: ${err}`)
  }
}

async function sendToToken(token: string, title: string, body: string, serverKey: string) {
  const res = await fetch(FCM_URL, {
    method: 'POST',
    headers: {
      'Authorization': `key=${serverKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: token,
      notification: { title, body },
      android: { priority: 'high' },
      apns: { headers: { 'apns-priority': '10' } },
    }),
  })
  if (!res.ok) {
    const err = await res.text()
    console.error(`FCM token send failed: ${err}`)
  }
}

Deno.serve(async (req) => {
  // Authenticate webhook
  const secret = Deno.env.get('WEBHOOK_SECRET') ?? ''
  if (req.headers.get('x-webhook-secret') !== secret) {
    return new Response('Unauthorized', { status: 401 })
  }

  const serverKey = Deno.env.get('FCM_SERVER_KEY') ?? ''
  if (!serverKey) {
    console.error('FCM_SERVER_KEY not set')
    return new Response('Server error', { status: 500 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const eventType = req.headers.get('x-event-type') ?? ''
  const payload = await req.json()
  const record = payload.record ?? {}
  const oldRecord = payload.old_record ?? {}

  try {
    switch (eventType) {

      // ── New guest request ────────────────────────────────────────────────
      case 'guest_request_insert': {
        const { hotel_id, room_number, category, assigned_dept } = record
        const dept = assigned_dept ?? category
        const topic = `hotel-${hotel_id}-${DEPT_TOPIC[dept] ?? dept}`
        const title = `בקשה חדשה · חדר ${room_number}`
        const body  = CATEGORY_HE[category] ?? category
        await sendToTopic(topic, title, body, serverKey)

        // Also notify managers
        await sendToTopic(`hotel-${hotel_id}-managers`, title, body, serverKey)
        break
      }

      // ── Guest request status updated ─────────────────────────────────────
      case 'guest_request_status': {
        const newStatus = record.status
        const oldStatus = oldRecord.status
        // Only notify on meaningful transitions
        if (newStatus === oldStatus) break
        if (!['in_progress', 'resolved', 'cancelled'].includes(newStatus)) break

        const { hotel_id, room_number } = record
        const { data: tokenRow } = await supabase
          .from('guest_push_tokens')
          .select('token')
          .eq('hotel_id', hotel_id)
          .eq('room_number', room_number)
          .maybeSingle()

        if (tokenRow?.token) {
          const statusHe = STATUS_HE[newStatus] ?? newStatus
          await sendToToken(
            tokenRow.token,
            `הבקשה שלך ${statusHe}`,
            `חדר ${room_number}`,
            serverKey
          )
        }
        break
      }

      // ── New ticket ───────────────────────────────────────────────────────
      case 'ticket_insert': {
        const { hotel_id, title, assigned_dept, priority } = record
        const topic = `hotel-${hotel_id}-${DEPT_TOPIC[assigned_dept] ?? assigned_dept}`
        const priorityHe = PRIORITY_HE[priority] ?? priority
        await sendToTopic(topic, `קריאה חדשה · ${priorityHe}`, title ?? '', serverKey)
        await sendToTopic(`hotel-${hotel_id}-managers`, `קריאה חדשה · ${priorityHe}`, title ?? '', serverKey)
        break
      }

      // ── Ticket assigned to specific user ─────────────────────────────────
      case 'ticket_assigned': {
        const { assigned_to, ticket_id } = record

        // Fetch ticket title
        const { data: ticket } = await supabase
          .from('tickets')
          .select('title')
          .eq('id', ticket_id)
          .maybeSingle()

        const { data: tokenRow } = await supabase
          .from('user_push_tokens')
          .select('token')
          .eq('user_id', assigned_to)
          .maybeSingle()

        if (tokenRow?.token) {
          await sendToToken(
            tokenRow.token,
            'קריאה הוקצתה לך',
            ticket?.title ?? '',
            serverKey
          )
        }
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
cd "/Users/boazsaada/manegmant resapceon" && git add supabase/functions/send-push/ && git commit -m "feat: add send-push Edge Function for FCM notifications"
```

---

### Task 3: Configure Database Webhooks (Manual — Supabase Dashboard)

After deploying the function (`supabase functions deploy send-push`), configure 4 webhooks in Supabase Dashboard → Database → Webhooks.

- [ ] **Step 1: For each webhook below, create a new webhook:**

**Webhook 1:**
- Name: `push_guest_request_insert`
- Table: `guest_requests`
- Events: INSERT
- URL: `{your-supabase-url}/functions/v1/send-push`
- HTTP Headers:
  - `x-webhook-secret`: your `WEBHOOK_SECRET` value
  - `x-event-type`: `guest_request_insert`

**Webhook 2:**
- Name: `push_guest_request_update`
- Table: `guest_requests`
- Events: UPDATE
- URL: `{your-supabase-url}/functions/v1/send-push`
- HTTP Headers:
  - `x-webhook-secret`: your `WEBHOOK_SECRET` value
  - `x-event-type`: `guest_request_status`

**Webhook 3:**
- Name: `push_ticket_insert`
- Table: `tickets`
- Events: INSERT
- URL: `{your-supabase-url}/functions/v1/send-push`
- HTTP Headers:
  - `x-webhook-secret`: your `WEBHOOK_SECRET` value
  - `x-event-type`: `ticket_insert`

**Webhook 4:**
- Name: `push_ticket_assigned`
- Table: `ticket_assignments`
- Events: INSERT
- URL: `{your-supabase-url}/functions/v1/send-push`
- HTTP Headers:
  - `x-webhook-secret`: your `WEBHOOK_SECRET` value
  - `x-event-type`: `ticket_assigned`

- [ ] **Step 2: Test**

In Supabase Table Editor, manually insert a row into `guest_requests` with a valid `hotel_id`. Check Supabase Edge Function logs → confirm `send-push` was invoked and returned `200 ok`.
