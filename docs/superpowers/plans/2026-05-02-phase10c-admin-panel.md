# Phase 10c — Admin Panel (Guest Requests + Feedback + Hotel Settings) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add guest requests management, feedback overview, and `stay_threshold` hotel setting to the existing Next.js admin panel.

**Architecture:** All new pages are async Server Components following the existing pattern (`supabaseAdmin` for data, Server Actions for mutations, URL `searchParams` for filter state). No client-side state. Sidebar gets two new nav items. One DB migration adds `stay_threshold` to the `hotels` table.

**Tech Stack:** Next.js 16 App Router + Server Actions + `supabaseAdmin` (existing pattern)

---

## File Map

| Action | File |
|--------|------|
| SQL | Supabase dashboard — `ALTER TABLE hotels ADD COLUMN stay_threshold INT DEFAULT 3` |
| Create | `admin/src/app/dashboard/guest-requests/page.tsx` |
| Create | `admin/src/app/dashboard/guest-feedback/page.tsx` |
| Modify | `admin/src/app/dashboard/hotels/[id]/page.tsx` — add `stay_threshold` field |
| Modify | `admin/src/components/sidebar.tsx` — add two nav items |

---

### Task 1: DB migration — stay_threshold

**Files:** SQL run in Supabase dashboard

- [ ] **Step 1: Run in Supabase SQL Editor**

```sql
ALTER TABLE hotels
  ADD COLUMN IF NOT EXISTS stay_threshold INT NOT NULL DEFAULT 3;
```

- [ ] **Step 2: Verify**

In Supabase Table Editor → `hotels` table → confirm `stay_threshold` column exists with default 3.

---

### Task 2: Guest Requests page

**Files:**
- Create: `admin/src/app/dashboard/guest-requests/page.tsx`

- [ ] **Step 1: Create the page**

```tsx
// admin/src/app/dashboard/guest-requests/page.tsx
import { supabaseAdmin } from '@/lib/supabase-admin'

const STATUS_LABELS: Record<string, string> = {
  open:        'פתוחה',
  assigned:    'הוקצתה',
  in_progress: 'בטיפול',
  resolved:    'טופלה',
  cancelled:   'בוטלה',
}

const STATUS_COLORS: Record<string, string> = {
  open:        'bg-red-100 text-red-700',
  assigned:    'bg-orange-100 text-orange-700',
  in_progress: 'bg-amber-100 text-amber-700',
  resolved:    'bg-green-100 text-green-700',
  cancelled:   'bg-gray-100 text-gray-500',
}

const CATEGORY_LABELS: Record<string, string> = {
  housekeeping: 'חדרניות',
  maintenance:  'תחזוקה',
  reception:    'קבלה',
}

function fmtDate(iso: string) {
  const d = new Date(iso)
  return d.toLocaleDateString('he-IL') + ' ' + d.toLocaleTimeString('he-IL', { hour: '2-digit', minute: '2-digit' })
}

export default async function GuestRequestsAdminPage({
  searchParams,
}: {
  searchParams: Promise<{ hotel?: string; status?: string; from?: string; to?: string }>
}) {
  const params = await searchParams
  const { hotel: hotelFilter, status: statusFilter, from: fromFilter, to: toFilter } = params

  const { data: hotels } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .order('name')

  let query = supabaseAdmin
    .from('guest_requests')
    .select('id, hotel_id, room_number, guest_name, category, status, description, assigned_dept, created_by, created_at')
    .order('created_at', { ascending: false })
    .limit(200)

  if (hotelFilter) query = query.eq('hotel_id', hotelFilter)
  if (statusFilter) query = query.eq('status', statusFilter)
  if (fromFilter)   query = query.gte('created_at', fromFilter)
  if (toFilter)     query = query.lte('created_at', toFilter + 'T23:59:59')

  const { data: requests } = await query

  const hotelMap = Object.fromEntries((hotels ?? []).map(h => [h.id, h.name]))

  const statuses = ['open', 'assigned', 'in_progress', 'resolved', 'cancelled']

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-6">🛎️ בקשות אורחים</h1>

      {/* Filters */}
      <form method="GET" className="flex flex-wrap gap-3 mb-6 bg-gray-50 p-4 rounded-xl border">
        <select name="hotel" defaultValue={hotelFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm">
          <option value="">כל המלונות</option>
          {(hotels ?? []).map(h => (
            <option key={h.id} value={h.id}>{h.name}</option>
          ))}
        </select>

        <select name="status" defaultValue={statusFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm">
          <option value="">כל הסטטוסים</option>
          {statuses.map(s => (
            <option key={s} value={s}>{STATUS_LABELS[s]}</option>
          ))}
        </select>

        <div className="flex items-center gap-2 text-sm">
          <span className="text-gray-500">מ-</span>
          <input type="date" name="from" defaultValue={fromFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm" />
          <span className="text-gray-500">עד</span>
          <input type="date" name="to" defaultValue={toFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm" />
        </div>

        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">
          סנן
        </button>
        <a href="/dashboard/guest-requests" className="text-sm text-gray-500 hover:text-gray-800 py-2 px-2">
          נקה
        </a>
      </form>

      {/* Summary pills */}
      <div className="flex gap-3 mb-4 flex-wrap">
        <span className="bg-blue-50 text-blue-700 px-3 py-1 rounded-full text-sm font-medium">
          סה"כ: {requests?.length ?? 0}
        </span>
        <span className="bg-red-50 text-red-700 px-3 py-1 rounded-full text-sm font-medium">
          פתוחות: {requests?.filter(r => r.status === 'open' || r.status === 'assigned').length ?? 0}
        </span>
        <span className="bg-amber-50 text-amber-700 px-3 py-1 rounded-full text-sm font-medium">
          בטיפול: {requests?.filter(r => r.status === 'in_progress').length ?? 0}
        </span>
        <span className="bg-green-50 text-green-700 px-3 py-1 rounded-full text-sm font-medium">
          טופלו: {requests?.filter(r => r.status === 'resolved').length ?? 0}
        </span>
      </div>

      {/* Table */}
      {!requests || requests.length === 0 ? (
        <p className="text-gray-500 py-12 text-center">אין בקשות</p>
      ) : (
        <div className="overflow-x-auto rounded-xl border">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">מלון</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">חדר</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">אורח</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">קטגוריה</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">סטטוס</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תיאור</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תאריך</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {requests.map(r => (
                <tr key={r.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-gray-700">{hotelMap[r.hotel_id] ?? r.hotel_id.slice(0, 8)}</td>
                  <td className="px-4 py-3 font-medium">{r.room_number}</td>
                  <td className="px-4 py-3 text-gray-700">{r.guest_name}</td>
                  <td className="px-4 py-3">{CATEGORY_LABELS[r.category] ?? r.category}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${STATUS_COLORS[r.status] ?? 'bg-gray-100 text-gray-500'}`}>
                      {STATUS_LABELS[r.status] ?? r.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-500 max-w-xs truncate">{r.description ?? '—'}</td>
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">{fmtDate(r.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add admin/src/app/dashboard/guest-requests/ && git commit -m "feat: add guest requests admin page"
```

---

### Task 3: Guest Feedback page

**Files:**
- Create: `admin/src/app/dashboard/guest-feedback/page.tsx`

- [ ] **Step 1: Create the page**

```tsx
// admin/src/app/dashboard/guest-feedback/page.tsx
import { supabaseAdmin } from '@/lib/supabase-admin'

function Stars({ rating }: { rating: number }) {
  return (
    <span className="text-yellow-500">
      {'★'.repeat(rating)}{'☆'.repeat(5 - rating)}
    </span>
  )
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('he-IL')
}

export default async function GuestFeedbackAdminPage({
  searchParams,
}: {
  searchParams: Promise<{ hotel?: string }>
}) {
  const params = await searchParams
  const { hotel: hotelFilter } = params

  const { data: hotels } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .order('name')

  let fbQuery = supabaseAdmin
    .from('guest_feedback')
    .select('id, hotel_id, room_number, guest_name, rating, comment, created_at')
    .order('created_at', { ascending: false })
    .limit(300)

  if (hotelFilter) fbQuery = fbQuery.eq('hotel_id', hotelFilter)

  const { data: feedback } = await fbQuery

  const hotelMap = Object.fromEntries((hotels ?? []).map(h => [h.id, h.name]))

  // Average rating per hotel
  const ratingByHotel: Record<string, { total: number; count: number; name: string }> = {}
  for (const f of feedback ?? []) {
    if (!ratingByHotel[f.hotel_id]) {
      ratingByHotel[f.hotel_id] = { total: 0, count: 0, name: hotelMap[f.hotel_id] ?? f.hotel_id }
    }
    ratingByHotel[f.hotel_id].total += f.rating
    ratingByHotel[f.hotel_id].count++
  }

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-6">⭐ משובי אורחים</h1>

      {/* Filter */}
      <form method="GET" className="flex gap-3 mb-6">
        <select name="hotel" defaultValue={hotelFilter ?? ''} className="border rounded-lg px-3 py-2 text-sm">
          <option value="">כל המלונות</option>
          {(hotels ?? []).map(h => (
            <option key={h.id} value={h.id}>{h.name}</option>
          ))}
        </select>
        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">סנן</button>
        <a href="/dashboard/guest-feedback" className="text-sm text-gray-500 hover:text-gray-800 py-2 px-2">נקה</a>
      </form>

      {/* Average per hotel */}
      {Object.keys(ratingByHotel).length > 0 && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-8">
          {Object.entries(ratingByHotel).map(([id, { name, total, count }]) => (
            <div key={id} className="border rounded-xl p-4 bg-white shadow-sm">
              <p className="font-semibold text-gray-700 mb-1">{name}</p>
              <p className="text-2xl font-bold text-yellow-500">
                {(total / count).toFixed(1)} ★
              </p>
              <p className="text-xs text-gray-400">{count} משובים</p>
            </div>
          ))}
        </div>
      )}

      {/* Table */}
      {!feedback || feedback.length === 0 ? (
        <p className="text-gray-500 py-12 text-center">אין משובים</p>
      ) : (
        <div className="overflow-x-auto rounded-xl border">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">מלון</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">חדר</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">אורח</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">דירוג</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תגובה</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תאריך</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {feedback.map(f => (
                <tr key={f.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-gray-700">{hotelMap[f.hotel_id] ?? f.hotel_id.slice(0, 8)}</td>
                  <td className="px-4 py-3 font-medium">{f.room_number}</td>
                  <td className="px-4 py-3">{f.guest_name}</td>
                  <td className="px-4 py-3"><Stars rating={f.rating} /></td>
                  <td className="px-4 py-3 text-gray-500 max-w-xs">{f.comment ?? '—'}</td>
                  <td className="px-4 py-3 text-gray-500 whitespace-nowrap">{fmtDate(f.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add admin/src/app/dashboard/guest-feedback/ && git commit -m "feat: add guest feedback admin page with per-hotel averages"
```

---

### Task 4: Add stay_threshold to hotel edit page

**Files:**
- Modify: `admin/src/app/dashboard/hotels/[id]/page.tsx`
- Modify: `admin/src/components/hotel-form.tsx` (if it exists and controls the form fields)

- [ ] **Step 1: Read hotel-form.tsx**

Read `admin/src/components/hotel-form.tsx` to understand the current form structure.

- [ ] **Step 2: Add stay_threshold field to HotelForm**

In `hotel-form.tsx`, find the form fields section. Add after `default_sla_hours` or at the end of the fields, before the submit button:

```tsx
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            ימי שהייה לפני משוב (stay_threshold)
          </label>
          <input
            type="number"
            name="stay_threshold"
            defaultValue={hotel.stay_threshold ?? 3}
            min={1}
            max={30}
            className="w-full border rounded-lg px-3 py-2 text-sm"
          />
          <p className="text-xs text-gray-400 mt-1">
            מספר ימים מכניסת האורח עד שמוצג banner המשוב ב-PWA (ברירת מחדל: 3)
          </p>
        </div>
```

- [ ] **Step 3: Update the HotelForm props type**

Add `stay_threshold?: number` to the hotel prop type in `hotel-form.tsx`.

- [ ] **Step 4: Update the Server Action in `/dashboard/hotels/[id]/page.tsx`**

In the `updateHotel` Server Action, add:
```ts
      stay_threshold: Number(fd.get('stay_threshold')) || 3,
```

And pass `stay_threshold` to the `HotelForm`:
```tsx
        stay_threshold: hotel.stay_threshold ?? 3,
```

- [ ] **Step 5: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add admin/src/app/dashboard/hotels/ admin/src/components/hotel-form.tsx && git commit -m "feat: add stay_threshold field to hotel settings"
```

---

### Task 5: Update sidebar navigation

**Files:**
- Modify: `admin/src/components/sidebar.tsx`

- [ ] **Step 1: Add two nav items to the `nav` array**

Current nav array:
```tsx
  const nav = [
    { href: '/dashboard',           label: t.overview,   icon: '📊' },
    { href: '/dashboard/hotels',    label: t.hotels,     icon: '🏨' },
    { href: '/dashboard/users',     label: t.users,      icon: '👥' },
    { href: '/dashboard/analytics', label: t.analytics,  icon: '📈' },
    { href: '/dashboard/logs',      label: t.auditLogs,  icon: '📋' },
    { href: '/dashboard/checklists',   label: 'צ׳קליסטים',  icon: '✅' },
    { href: '/dashboard/automations',  label: 'אוטומציות',   icon: '⚡' },
  ]
```

New (add two items after automations):
```tsx
  const nav = [
    { href: '/dashboard',                  label: t.overview,      icon: '📊' },
    { href: '/dashboard/hotels',           label: t.hotels,        icon: '🏨' },
    { href: '/dashboard/users',            label: t.users,         icon: '👥' },
    { href: '/dashboard/analytics',        label: t.analytics,     icon: '📈' },
    { href: '/dashboard/logs',             label: t.auditLogs,     icon: '📋' },
    { href: '/dashboard/checklists',       label: 'צ׳קליסטים',    icon: '✅' },
    { href: '/dashboard/automations',      label: 'אוטומציות',     icon: '⚡' },
    { href: '/dashboard/guest-requests',   label: 'בקשות אורחים', icon: '🛎️' },
    { href: '/dashboard/guest-feedback',   label: 'משובים',        icon: '⭐' },
  ]
```

- [ ] **Step 2: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon" && git add admin/src/components/sidebar.tsx && git commit -m "feat: add guest requests and feedback to admin sidebar"
```
