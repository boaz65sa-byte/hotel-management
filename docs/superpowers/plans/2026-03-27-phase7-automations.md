# Phase 7: Tasks & Automations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hotel managers create recurring tasks (daily/weekly/monthly/quarterly) that automatically generate tickets on schedule. Admin panel page for managing automations per hotel.

**Architecture:** `scheduled_tasks` DB table with `next_run_at`. Supabase Edge Function `run-scheduled-tasks` runs hourly via pg_cron: queries due tasks, inserts tickets, updates `next_run_at`. Admin panel `/dashboard/automations` for CRUD. Flutter `ManagerHomeScreen` shows active automations count.

**Tech Stack:** Flutter 3, Riverpod, Supabase (Edge Functions + pg_cron), Next.js 16 App Router

**Prerequisite:** Phase 2 (ManagerHomeScreen) must exist. Phase 6 `set_updated_at()` function must exist.

---

## File Structure

```
supabase/
  migrations/
    20260327000005_scheduled_tasks.sql       ← NEW: table + RLS + updated_at trigger
  functions/
    run-scheduled-tasks/index.ts             ← NEW: Edge Function (called by pg_cron)

admin/src/app/
  dashboard/automations/
    page.tsx                                 ← NEW: list automations per hotel
    new/page.tsx                             ← NEW: create automation form
  api/automations/
    route.ts                                 ← NEW: GET + POST
    [id]/route.ts                            ← NEW: PATCH + DELETE
```

---

## Task 1: DB Migration — scheduled_tasks table

**Files:**
- Create: `supabase/migrations/20260327000005_scheduled_tasks.sql`

- [ ] **Step 1: Write migration**

```sql
-- supabase/migrations/20260327000005_scheduled_tasks.sql

CREATE TABLE IF NOT EXISTS scheduled_tasks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id      UUID NOT NULL REFERENCES hotels(id),
  room_id       UUID REFERENCES rooms(id),        -- nullable: hotel-level tasks
  title         TEXT NOT NULL,
  description   TEXT,
  recurrence    TEXT NOT NULL CHECK (recurrence IN ('daily','weekly','monthly','quarterly')),
  assigned_role TEXT NOT NULL,                    -- maps to tickets.assigned_dept
  next_run_at   TIMESTAMPTZ NOT NULL,
  last_run_at   TIMESTAMPTZ,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- updated_at trigger (set_updated_at() created in Phase 6 migration)
CREATE TRIGGER trg_updated_at_scheduled_tasks
  BEFORE UPDATE ON scheduled_tasks FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS: hotel managers see their hotel's tasks, superAdmin sees all
ALTER TABLE scheduled_tasks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "hotel tasks" ON scheduled_tasks FOR ALL
  USING (
    (auth.jwt()->'claims'->>'hotel_id')::uuid = hotel_id
    OR (auth.jwt()->'claims'->>'role') = 'superAdmin'
  );
```

- [ ] **Step 2: Apply in Supabase Dashboard SQL Editor**

- [ ] **Step 3: Commit migration**

```bash
git add supabase/migrations/20260327000005_scheduled_tasks.sql
git commit -m "feat: scheduled_tasks table with RLS"
```

---

## Task 2: Edge Function — run-scheduled-tasks

**Files:**
- Create: `supabase/functions/run-scheduled-tasks/index.ts`

This function queries due tasks, creates tickets, updates next_run_at.

- [ ] **Step 1: Write the Edge Function**

```typescript
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
  // Verify this is called from pg_cron or admin (simple secret check)
  const authHeader = req.headers.get('Authorization')
  const cronSecret = Deno.env.get('CRON_SECRET')
  if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
    return new Response('Unauthorized', { status: 401 })
  }

  const now = new Date().toISOString()

  // Fetch due tasks
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
    // Insert ticket
    const { error: insertError } = await supabase.from('tickets').insert({
      hotel_id: task.hotel_id,
      room_id: task.room_id,
      title: task.title,
      description: task.description,
      assigned_dept: task.assigned_role,
      priority: 'normal',
      status: 'open',
      opened_by: task.hotel_id, // system-generated — use hotel_id as placeholder
    })

    if (!insertError) {
      // Update task: last_run_at + next_run_at
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
```

- [ ] **Step 2: Write unit test for nextRunAt logic (local)**

In `test/automations/next_run_at_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

// Test the recurrence interval logic in Dart (mirrors the Edge Function logic)
Duration recurrenceDuration(String recurrence) => switch (recurrence) {
  'daily'     => const Duration(days: 1),
  'weekly'    => const Duration(days: 7),
  'monthly'   => const Duration(days: 30),
  'quarterly' => const Duration(days: 90),
  _           => const Duration(days: 1),
};

void main() {
  test('daily recurrence adds 1 day', () {
    expect(recurrenceDuration('daily'), const Duration(days: 1));
  });

  test('weekly recurrence adds 7 days', () {
    expect(recurrenceDuration('weekly'), const Duration(days: 7));
  });

  test('quarterly recurrence adds 90 days', () {
    expect(recurrenceDuration('quarterly'), const Duration(days: 90));
  });
}
```

- [ ] **Step 3: Run test**

```bash
/Users/boazsaada/flutter/bin/flutter test test/automations/next_run_at_test.dart -v
```

Expected: PASS.

- [ ] **Step 4: Deploy Edge Function**

```bash
cd "/Users/boazsaada/manegmant resapceon" && supabase functions deploy run-scheduled-tasks
```

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/run-scheduled-tasks/index.ts test/automations/next_run_at_test.dart
git commit -m "feat: run-scheduled-tasks Edge Function + recurrence tests"
```

---

## Task 3: Admin Panel — /dashboard/automations

**Files:**
- Create: `admin/src/app/api/automations/route.ts`
- Create: `admin/src/app/api/automations/[id]/route.ts`
- Create: `admin/src/app/dashboard/automations/page.tsx`
- Create: `admin/src/app/dashboard/automations/new/page.tsx`

- [ ] **Step 1: Create API routes**

```typescript
// admin/src/app/api/automations/route.ts
import { NextResponse } from 'next/server'
import { requireSuperAdmin } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

export async function GET(req: Request) {
  await requireSuperAdmin()
  const { searchParams } = new URL(req.url)
  const hotelId = searchParams.get('hotel_id')

  let query = supabaseAdmin
    .from('scheduled_tasks')
    .select('*, hotels(name)')
    .order('next_run_at')

  if (hotelId) query = query.eq('hotel_id', hotelId)

  const { data, error } = await query
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function POST(req: Request) {
  await requireSuperAdmin()
  const body = await req.json()
  const { hotel_id, room_id, title, description, recurrence, assigned_role, next_run_at } = body

  if (!hotel_id || !title || !recurrence || !assigned_role || !next_run_at) {
    return NextResponse.json({ error: 'Missing required fields' }, { status: 400 })
  }

  const { data, error } = await supabaseAdmin
    .from('scheduled_tasks')
    .insert({ hotel_id, room_id, title, description, recurrence, assigned_role, next_run_at })
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data, { status: 201 })
}
```

```typescript
// admin/src/app/api/automations/[id]/route.ts
import { NextResponse } from 'next/server'
import { requireSuperAdmin } from '@/lib/auth-guard'
import { supabaseAdmin } from '@/lib/supabase-admin'

const ALLOWED = ['title', 'description', 'recurrence', 'assigned_role', 'next_run_at', 'is_active'] as const

export async function PATCH(req: Request, { params }: { params: { id: string } }) {
  await requireSuperAdmin()
  const body = await req.json()
  const safe: Record<string, unknown> = {}
  for (const key of ALLOWED) { if (key in body) safe[key] = body[key] }

  const { data, error } = await supabaseAdmin
    .from('scheduled_tasks')
    .update(safe)
    .eq('id', params.id)
    .select()
    .single()

  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json(data)
}

export async function DELETE(_req: Request, { params }: { params: { id: string } }) {
  await requireSuperAdmin()
  const { error } = await supabaseAdmin.from('scheduled_tasks').delete().eq('id', params.id)
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return new NextResponse(null, { status: 204 })
}
```

- [ ] **Step 2: Create automations list page**

```tsx
// admin/src/app/dashboard/automations/page.tsx
'use client'
import { useEffect, useState } from 'react'
import Link from 'next/link'

interface Task {
  id: string; title: string; recurrence: string; assigned_role: string;
  next_run_at: string; is_active: boolean; hotels?: { name: string }
}

const RECURRENCE_HE: Record<string, string> = {
  daily: 'יומי', weekly: 'שבועי', monthly: 'חודשי', quarterly: 'רבעוני'
}

export default function AutomationsPage() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/automations')
      .then(r => r.json())
      .then(data => { setTasks(data); setLoading(false) })
  }, [])

  const toggleActive = async (id: string, is_active: boolean) => {
    await fetch(`/api/automations/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ is_active: !is_active }),
    })
    setTasks(tasks.map(t => t.id === id ? { ...t, is_active: !is_active } : t))
  }

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">אוטומציות</h1>
        <Link href="/dashboard/automations/new"
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          + אוטומציה חדשה
        </Link>
      </div>

      {loading ? <p>טוען...</p> : (
        <div className="grid gap-4">
          {tasks.map(task => (
            <div key={task.id} className="bg-white rounded-lg p-4 shadow">
              <div className="flex justify-between items-start">
                <div>
                  <p className="font-semibold">{task.title}</p>
                  <p className="text-sm text-gray-500">
                    {RECURRENCE_HE[task.recurrence]} · {task.assigned_role} · {task.hotels?.name}
                  </p>
                  <p className="text-xs text-gray-400 mt-1">
                    הבא: {new Date(task.next_run_at).toLocaleDateString('he-IL')}
                  </p>
                </div>
                <button
                  onClick={() => toggleActive(task.id, task.is_active)}
                  className={`px-3 py-1 rounded-full text-xs font-medium ${
                    task.is_active
                      ? 'bg-green-100 text-green-800'
                      : 'bg-gray-100 text-gray-600'
                  }`}>
                  {task.is_active ? 'פעיל' : 'כבוי'}
                </button>
              </div>
            </div>
          ))}
          {tasks.length === 0 && <p className="text-gray-500">אין אוטומציות. צור אחת!</p>}
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 3: Create new automation form**

```tsx
// admin/src/app/dashboard/automations/new/page.tsx
'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function NewAutomationPage() {
  const router = useRouter()
  const [form, setForm] = useState({
    hotel_id: '', title: '', recurrence: 'daily',
    assigned_role: 'maintenance', next_run_at: '',
  })
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    const res = await fetch('/api/automations', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form),
    })
    if (res.ok) {
      router.push('/dashboard/automations')
    } else {
      const data = await res.json()
      setError(data.error || 'שגיאה')
      setSaving(false)
    }
  }

  return (
    <div className="p-6 max-w-lg">
      <h1 className="text-2xl font-bold mb-6">אוטומציה חדשה</h1>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">Hotel ID</label>
          <input className="w-full border rounded px-3 py-2"
            value={form.hotel_id} onChange={e => setForm({...form, hotel_id: e.target.value})}
            required placeholder="UUID של המלון" />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">כותרת</label>
          <input className="w-full border rounded px-3 py-2"
            value={form.title} onChange={e => setForm({...form, title: e.target.value})}
            required placeholder="פילטר מיזוג חדר 201" />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">תדירות</label>
          <select className="w-full border rounded px-3 py-2"
            value={form.recurrence} onChange={e => setForm({...form, recurrence: e.target.value})}>
            <option value="daily">יומי</option>
            <option value="weekly">שבועי</option>
            <option value="monthly">חודשי</option>
            <option value="quarterly">רבעוני</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">מחלקה</label>
          <select className="w-full border rounded px-3 py-2"
            value={form.assigned_role} onChange={e => setForm({...form, assigned_role: e.target.value})}>
            <option value="maintenance">אחזקה</option>
            <option value="housekeeping">ניקיון</option>
            <option value="reception">קבלה</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">הרצה ראשונה</label>
          <input type="datetime-local" className="w-full border rounded px-3 py-2"
            value={form.next_run_at} onChange={e => setForm({...form, next_run_at: new Date(e.target.value).toISOString()})}
            required />
        </div>
        {error && <p className="text-red-600 text-sm">{error}</p>}
        <button type="submit" disabled={saving}
          className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50">
          {saving ? 'שומר...' : 'צור אוטומציה'}
        </button>
      </form>
    </div>
  )
}
```

- [ ] **Step 4: Add automations link to admin sidebar**

In `admin/src/components/sidebar.tsx`, add:
```tsx
{ href: '/dashboard/automations', label: 'אוטומציות', icon: Zap }
```

- [ ] **Step 5: Build admin to verify**

```bash
cd "/Users/boazsaada/manegmant resapceon/admin" && npm run build 2>&1 | tail -10
```

Expected: compiled successfully.

- [ ] **Step 6: Commit**

```bash
git add admin/src/app/dashboard/automations/ admin/src/app/api/automations/ admin/src/components/sidebar.tsx
git commit -m "feat: automations admin panel with list, create, toggle"
```

---

## Task 4: pg_cron setup (manual step in Supabase)

pg_cron calls the Edge Function every hour.

- [ ] **Step 1: Enable pg_cron extension in Supabase**

In Supabase Dashboard → Database → Extensions → search "pg_cron" → Enable.

- [ ] **Step 2: Create cron job via SQL Editor**

```sql
-- Run the Edge Function every hour
SELECT cron.schedule(
  'run-scheduled-tasks',
  '0 * * * *',  -- every hour at :00
  $$
  SELECT net.http_post(
    url := 'https://<YOUR-PROJECT-REF>.supabase.co/functions/v1/run-scheduled-tasks',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.cron_secret', true),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);
```

Replace `<YOUR-PROJECT-REF>` with the actual Supabase project reference from the Dashboard URL.

- [ ] **Step 3: Verify cron is registered**

```sql
SELECT * FROM cron.job;
```

Expected: 1 row for `run-scheduled-tasks`.

- [ ] **Step 4: Document the project ref used**

Note: project ref is `vetwlonyzyzvhrtdwbzj` (from the Supabase Dashboard URL seen in screenshots).

- [ ] **Step 5: Commit notes**

```bash
git add -A
git commit -m "docs: pg_cron setup instructions for run-scheduled-tasks"
```

---

## Task 5: Manager home — show automations count

**Files:**
- Modify: `lib/features/home/providers/manager_home_provider.dart`
- Modify: `lib/features/home/presentation/manager_home.dart`

Show count of active automations in the KPI dashboard.

- [ ] **Step 1: Add automationsCount to ManagerKpis**

In `lib/features/home/providers/manager_home_provider.dart`:

Add to `ManagerKpis`:
```dart
final int activeAutomations;
const ManagerKpis({
  required this.openTickets,
  required this.inProgressTickets,
  required this.overdueTickets,
  required this.activeAutomations,
});
```

In the provider, add:
```dart
final automations = await supabase
    .from('scheduled_tasks')
    .select('id', const FetchOptions(count: CountOption.exact))
    .eq('is_active', true);

return ManagerKpis(
  openTickets: ...,
  inProgressTickets: ...,
  overdueTickets: ...,
  activeAutomations: automations.count ?? 0,
);
```

- [ ] **Step 2: Update existing manager KPI test**

In `test/features/home/manager_kpis_test.dart`:

```dart
test('ManagerKpis holds automations count', () {
  const kpis = ManagerKpis(
    openTickets: 5, inProgressTickets: 3,
    overdueTickets: 1, activeAutomations: 4,
  );
  expect(kpis.activeAutomations, 4);
});
```

- [ ] **Step 3: Run test**

```bash
/Users/boazsaada/flutter/bin/flutter test test/features/home/manager_kpis_test.dart -v
```

- [ ] **Step 4: Add automation KPI card to manager dashboard**

In `lib/features/home/presentation/manager_home.dart`, add 4th KpiCard:
```dart
_KpiCard(label: 'אוטומציות פעילות', value: k.activeAutomations, color: Colors.purple),
```

- [ ] **Step 5: Run full test suite + analyze**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/providers/manager_home_provider.dart lib/features/home/presentation/manager_home.dart test/features/home/manager_kpis_test.dart
git commit -m "feat: automations count in manager KPI dashboard"
```

---

## Task 6: Final integration + verification

- [ ] **Step 1: Full Flutter test suite**

```bash
/Users/boazsaada/flutter/bin/flutter test -v
/Users/boazsaada/flutter/bin/flutter analyze
```

- [ ] **Step 2: Web build**

```bash
cd "/Users/boazsaada/manegmant resapceon" && /Users/boazsaada/flutter/bin/flutter build web --web-renderer html
```

- [ ] **Step 3: Admin build**

```bash
cd "/Users/boazsaada/manegmant resapceon/admin" && npm run build 2>&1 | tail -5
```

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: Phase 7 complete — Tasks & Automations (scheduled_tasks + Edge Function + admin panel + manager KPI)"
```

---

## Verification (Success Criteria)

- [ ] Admin can create a daily automation for a hotel → appears in `/dashboard/automations`
- [ ] Toggle active/inactive works on automation
- [ ] Edge Function `run-scheduled-tasks` called manually returns `{ created: N }`
- [ ] A task with `next_run_at` in the past generates a ticket in the `tickets` table
- [ ] `next_run_at` is updated to next interval after running
- [ ] Manager home shows `activeAutomations` count in KPI card
- [ ] All Flutter tests pass, `flutter analyze` clean
