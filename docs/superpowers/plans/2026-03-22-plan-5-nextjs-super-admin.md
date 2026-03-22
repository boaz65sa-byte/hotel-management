# Hotel Management App - Plan 5: Next.js Super Admin Panel

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Super Admin web panel in Next.js — separate from the hotel app, uses Supabase service role key server-side, accessible only to the app owner. Covers hotel management (create/edit/theme), global user management, global analytics, and audit logs.

**Architecture:** Next.js 14 App Router with Server Components. All Supabase calls use service role key in server actions / API routes — never exposed to client. Separate login with 2FA (Supabase MFA). Deployed independently from the Flutter app.

**Tech Stack:** Next.js 14, TypeScript, Tailwind CSS, Supabase JS (service role, server-side only), shadcn/ui components, Recharts for graphs

---

## Prerequisites

- Plan 1 (Supabase Backend) complete
- Node.js 18+ installed

---

## File Structure

```
admin/                                  # Next.js app in its own directory
├── .env.local                          # SUPABASE_SERVICE_ROLE_KEY (never committed)
├── .env.example
├── next.config.js
├── tailwind.config.ts
├── package.json
├── src/
│   ├── app/
│   │   ├── layout.tsx                  # Root layout + auth check
│   │   ├── login/
│   │   │   └── page.tsx               # Admin login page
│   │   ├── dashboard/
│   │   │   ├── layout.tsx             # Sidebar + nav
│   │   │   ├── page.tsx               # Overview dashboard
│   │   │   ├── hotels/
│   │   │   │   ├── page.tsx           # Hotel list
│   │   │   │   ├── [id]/page.tsx      # Hotel detail + edit
│   │   │   │   └── new/page.tsx       # Create hotel
│   │   │   ├── users/
│   │   │   │   └── page.tsx           # Global user list
│   │   │   ├── analytics/
│   │   │   │   └── page.tsx           # Cross-hotel analytics
│   │   │   └── logs/
│   │   │       └── page.tsx           # Audit logs
│   ├── lib/
│   │   ├── supabase-admin.ts          # Service role client (server only)
│   │   └── auth-guard.ts              # Server-side auth check
│   └── components/
│       ├── sidebar.tsx
│       ├── hotel-form.tsx
│       ├── theme-picker.tsx
│       └── stats-card.tsx
```

---

## Task 1: Next.js Project Setup

**Files:**
- Create: `admin/package.json` (via create-next-app)
- Create: `admin/.env.example`
- Create: `admin/src/lib/supabase-admin.ts`

- [ ] **Step 1: Create Next.js project**

```bash
cd "/Users/boazsaada/manegmant resapceon"
npx create-next-app@latest admin \
  --typescript --tailwind --eslint --app --src-dir \
  --import-alias "@/*" --no-git
cd admin
```

- [ ] **Step 2: Install dependencies**

```bash
npm install @supabase/supabase-js recharts
npx shadcn@latest init  # select: New York style, Neutral color
npx shadcn@latest add button card input label table badge switch tabs
```

- [ ] **Step 3: Create .env.example**

```bash
cat > .env.example << 'EOF'
# Server-side only (never NEXT_PUBLIC_)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Client-side (safe to expose — anon key only)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
EOF
```

- [ ] **Step 3b: Install Jest for testing**

```bash
npm install -D jest @types/jest ts-jest
cat > jest.config.js << 'EOF'
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  moduleNameMapper: { '^@/(.*)$': '<rootDir>/src/$1' },
  testMatch: ['**/__tests__/**/*.test.ts'],
}
EOF
```

- [ ] **Step 4: Create Supabase admin client (server-side only)**

```typescript
// src/lib/supabase-admin.ts
// IMPORTANT: This file must only be imported in server components, server actions, or API routes.
// The service role key bypasses ALL RLS. Never expose to client.

import { createClient } from '@supabase/supabase-js'

if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Missing Supabase env vars — check .env.local')
}

export const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
)
```

- [ ] **Step 5: Write test for client init**

```typescript
// src/lib/__tests__/supabase-admin.test.ts
// Run with: npx jest
describe('supabaseAdmin', () => {
  it('throws if env vars are missing', () => {
    const originalUrl = process.env.SUPABASE_URL
    delete process.env.SUPABASE_URL
    expect(() => require('../supabase-admin')).toThrow('Missing Supabase env vars')
    process.env.SUPABASE_URL = originalUrl
  })
})
```

- [ ] **Step 6: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon"
git add admin/
git commit -m "feat: initialize next.js super admin project"
```

---

## Task 2: Auth Guard + Login Page

**Files:**
- Create: `admin/src/lib/auth-guard.ts`
- Create: `admin/src/app/login/page.tsx`
- Modify: `admin/src/app/layout.tsx`

- [ ] **Step 1: Write auth guard**

```typescript
// src/lib/auth-guard.ts
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
```

- [ ] **Step 2: Write login page**

```typescript
// src/app/login/page.tsx
'use client'
import { useState } from 'react'
import { createClient } from '@supabase/supabase-js'
import { useRouter } from 'next/navigation'

// Client-side only for login (uses anon key just for auth)
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [mfaCode, setMfaCode] = useState('')
  const [step, setStep] = useState<'credentials' | 'mfa'>('credentials')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true); setError('')
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error

      // Check if MFA is required
      if (data.session) {
        // Check for MFA factors
        const { data: factors } = await supabase.auth.mfa.listFactors()
        if (factors?.totp?.length) {
          setStep('mfa')
        } else {
          router.push('/dashboard')
        }
      }
    } catch (e: any) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  async function handleMfa(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true); setError('')
    try {
      const { data: { totp } } = await supabase.auth.mfa.listFactors()
      const factorId = totp![0].id
      const { data: challenge } = await supabase.auth.mfa.challenge({ factorId })
      await supabase.auth.mfa.verify({ factorId, challengeId: challenge!.id, code: mfaCode })
      router.push('/dashboard')
    } catch (e: any) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="bg-white p-8 rounded-xl shadow w-full max-w-sm">
        <h1 className="text-2xl font-bold mb-6">Super Admin</h1>

        {step === 'credentials' ? (
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">Email</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)}
                className="w-full border rounded px-3 py-2" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Password</label>
              <input type="password" value={password} onChange={e => setPassword(e.target.value)}
                className="w-full border rounded px-3 py-2" required />
            </div>
            {error && <p className="text-red-500 text-sm">{error}</p>}
            <button type="submit" disabled={loading}
              className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 disabled:opacity-50">
              {loading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>
        ) : (
          <form onSubmit={handleMfa} className="space-y-4">
            <p className="text-sm text-gray-600">Enter your authenticator code:</p>
            <input value={mfaCode} onChange={e => setMfaCode(e.target.value)}
              className="w-full border rounded px-3 py-2 text-center text-2xl tracking-widest"
              maxLength={6} placeholder="000000" required />
            {error && <p className="text-red-500 text-sm">{error}</p>}
            <button type="submit" disabled={loading}
              className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 disabled:opacity-50">
              {loading ? 'Verifying...' : 'Verify'}
            </button>
          </form>
        )}
      </div>
    </div>
  )
}
```

Also add to `.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

- [ ] **Step 3: Add logout API route**

```typescript
// src/app/api/logout/route.ts
import { createClient } from '@supabase/supabase-js'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import { NextResponse } from 'next/server'

export async function GET() {
  const cookieStore = await cookies()
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
  await supabase.auth.signOut()
  // Clear auth cookies
  cookieStore.delete('sb-access-token')
  cookieStore.delete('sb-refresh-token')
  return NextResponse.redirect(new URL('/login', process.env.NEXT_PUBLIC_SUPABASE_URL))
}
```

- [ ] **Step 4: Enforce MFA on login (block if not enrolled)**

Update `login/page.tsx` — after password login succeeds, check if user has MFA:

```typescript
// Replace the MFA check block with:
const { data: factors } = await supabase.auth.mfa.listFactors()
if (!factors?.totp?.length) {
  // MFA not enrolled — sign them out and show error
  await supabase.auth.signOut()
  setError('MFA is required. Please enroll TOTP via Supabase dashboard first.')
  setLoading(false)
  return
}
setStep('mfa')
```

- [ ] **Step 5: Commit**

```bash
git add admin/src/app/login/ admin/src/app/api/ admin/src/lib/auth-guard.ts
git commit -m "feat: add super admin login with MFA enforcement and logout"
```

---

## Task 3: Dashboard Layout + Sidebar

**Files:**
- Create: `admin/src/app/dashboard/layout.tsx`
- Create: `admin/src/components/sidebar.tsx`

- [ ] **Step 1: Write sidebar**

```typescript
// src/components/sidebar.tsx
'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'

const nav = [
  { href: '/dashboard',           label: 'Overview',   icon: '📊' },
  { href: '/dashboard/hotels',    label: 'Hotels',     icon: '🏨' },
  { href: '/dashboard/users',     label: 'Users',      icon: '👥' },
  { href: '/dashboard/analytics', label: 'Analytics',  icon: '📈' },
  { href: '/dashboard/logs',      label: 'Audit Logs', icon: '📋' },
]

export function Sidebar() {
  const pathname = usePathname()
  return (
    <aside className="w-56 bg-gray-900 text-white min-h-screen p-4 flex flex-col">
      <div className="text-xl font-bold mb-8 px-2">Super Admin</div>
      <nav className="space-y-1 flex-1">
        {nav.map(item => (
          <Link key={item.href} href={item.href}
            className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors
              ${pathname === item.href
                ? 'bg-blue-600 text-white'
                : 'text-gray-300 hover:bg-gray-800 hover:text-white'}`}>
            <span>{item.icon}</span>
            {item.label}
          </Link>
        ))}
      </nav>
      <a href="/api/logout" className="text-gray-400 hover:text-white text-sm px-3 py-2">
        Sign Out
      </a>
    </aside>
  )
}
```

- [ ] **Step 2: Write dashboard layout**

```typescript
// src/app/dashboard/layout.tsx
import { requireSuperAdmin } from '@/lib/auth-guard'
import { Sidebar } from '@/components/sidebar'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  await requireSuperAdmin() // Server-side auth check — redirects if not super_admin

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 p-8 overflow-auto">
        {children}
      </main>
    </div>
  )
}
```

- [ ] **Step 3: Write overview dashboard page**

```typescript
// src/app/dashboard/page.tsx
import { supabaseAdmin } from '@/lib/supabase-admin'

async function getStats() {
  const [hotels, users, tickets] = await Promise.all([
    supabaseAdmin.from('hotels').select('id, is_active').then(r => r.data ?? []),
    supabaseAdmin.from('users').select('id, is_active').then(r => r.data ?? []),
    supabaseAdmin.from('tickets').select('id, status').then(r => r.data ?? []),
  ])
  return {
    totalHotels: hotels.length,
    activeHotels: hotels.filter(h => h.is_active).length,
    totalUsers: users.length,
    activeUsers: users.filter(u => u.is_active).length,
    openTickets: tickets.filter(t => !['resolved','closed'].includes(t.status)).length,
  }
}

export default async function DashboardPage() {
  const stats = await getStats()

  const cards = [
    { label: 'Total Hotels',  value: stats.totalHotels,  sub: `${stats.activeHotels} active` },
    { label: 'Total Users',   value: stats.totalUsers,   sub: `${stats.activeUsers} active` },
    { label: 'Open Tickets',  value: stats.openTickets,  sub: 'across all hotels' },
  ]

  return (
    <div>
      <h1 className="text-2xl font-bold mb-8">Overview</h1>
      <div className="grid grid-cols-3 gap-6">
        {cards.map(c => (
          <div key={c.label} className="bg-white rounded-xl p-6 shadow-sm border">
            <div className="text-3xl font-bold text-blue-600">{c.value}</div>
            <div className="font-medium mt-1">{c.label}</div>
            <div className="text-sm text-gray-500">{c.sub}</div>
          </div>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 4: Run locally**

```bash
cd admin && npm run dev
```
Visit http://localhost:3000 → redirects to /login → login with super_admin credentials → see dashboard.

- [ ] **Step 5: Commit**

```bash
git add admin/src/
git commit -m "feat: add dashboard layout with sidebar and overview stats"
```

---

## Task 4: Hotels Management

**Files:**
- Create: `admin/src/app/dashboard/hotels/page.tsx`
- Create: `admin/src/app/dashboard/hotels/new/page.tsx`
- Create: `admin/src/app/dashboard/hotels/[id]/page.tsx`
- Create: `admin/src/components/hotel-form.tsx`
- Create: `admin/src/components/theme-picker.tsx`

- [ ] **Step 1: Write hotel list page**

```typescript
// src/app/dashboard/hotels/page.tsx
import { supabaseAdmin } from '@/lib/supabase-admin'
import Link from 'next/link'

export default async function HotelsPage() {
  const { data: hotels } = await supabaseAdmin
    .from('hotels')
    .select('id, name, subscription_plan, is_active, created_at')
    .order('name')

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Hotels</h1>
        <Link href="/dashboard/hotels/new"
          className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
          + New Hotel
        </Link>
      </div>
      <div className="bg-white rounded-xl border overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              {['Name','Plan','Status','Created','Actions'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-sm font-medium text-gray-500">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y">
            {(hotels ?? []).map(hotel => (
              <tr key={hotel.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{hotel.name}</td>
                <td className="px-4 py-3">
                  <span className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full capitalize">
                    {hotel.subscription_plan}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <span className={`text-xs px-2 py-1 rounded-full ${hotel.is_active
                    ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                    {hotel.is_active ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">
                  {new Date(hotel.created_at).toLocaleDateString()}
                </td>
                <td className="px-4 py-3">
                  <Link href={`/dashboard/hotels/${hotel.id}`}
                    className="text-blue-600 hover:underline text-sm">Edit</Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Write theme picker component**

```typescript
// src/components/theme-picker.tsx
'use client'
type Props = { value: { primary: string; secondary: string; accent: string }
               onChange: (v: Props['value']) => void }

export function ThemePicker({ value, onChange }: Props) {
  const fields: Array<keyof Props['value']> = ['primary', 'secondary', 'accent']
  return (
    <div className="flex gap-6">
      {fields.map(field => (
        <div key={field}>
          <label className="block text-sm font-medium capitalize mb-1">{field}</label>
          <div className="flex items-center gap-2">
            <input type="color" value={value[field]}
              onChange={e => onChange({ ...value, [field]: e.target.value })}
              className="h-10 w-16 rounded cursor-pointer border" />
            <span className="text-sm font-mono text-gray-500">{value[field]}</span>
          </div>
        </div>
      ))}
    </div>
  )
}
```

- [ ] **Step 3: Write hotel form (new + edit)**

```typescript
// src/components/hotel-form.tsx
'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { ThemePicker } from './theme-picker'

type Hotel = { id?: string; name: string; subscription_plan: string
               default_sla_hours: number; default_language: string
               is_active: boolean; theme_colors: { primary: string; secondary: string; accent: string } }

export function HotelForm({ hotel, action }: { hotel: Hotel; action: (fd: FormData) => Promise<void> }) {
  const [data, setData] = useState(hotel)
  const router = useRouter()

  return (
    <form action={action} className="space-y-6 bg-white rounded-xl p-6 border max-w-2xl">
      <input type="hidden" name="id" value={data.id ?? ''} />
      <input type="hidden" name="theme_colors" value={JSON.stringify(data.theme_colors)} />

      <div>
        <label className="block text-sm font-medium mb-1">Hotel Name *</label>
        <input name="name" value={data.name} onChange={e => setData({...data, name: e.target.value})}
          className="w-full border rounded px-3 py-2" required />
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div>
          <label className="block text-sm font-medium mb-1">Plan</label>
          <select name="subscription_plan" value={data.subscription_plan}
            onChange={e => setData({...data, subscription_plan: e.target.value})}
            className="w-full border rounded px-3 py-2">
            <option value="basic">Basic (10GB)</option>
            <option value="pro">Pro (50GB)</option>
            <option value="enterprise">Enterprise (200GB)</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">SLA (hours)</label>
          <input type="number" name="default_sla_hours" value={data.default_sla_hours}
            onChange={e => setData({...data, default_sla_hours: +e.target.value})}
            className="w-full border rounded px-3 py-2" min={1} />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Default Language</label>
          <select name="default_language" value={data.default_language}
            onChange={e => setData({...data, default_language: e.target.value})}
            className="w-full border rounded px-3 py-2">
            <option value="he">Hebrew</option>
            <option value="en">English</option>
            <option value="ar">Arabic</option>
          </select>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium mb-2">Theme Colors</label>
        <ThemePicker value={data.theme_colors}
          onChange={colors => setData({...data, theme_colors: colors})} />
      </div>

      <div className="flex items-center gap-3">
        <input type="checkbox" name="is_active" id="is_active"
          checked={data.is_active} onChange={e => setData({...data, is_active: e.target.checked})} />
        <label htmlFor="is_active" className="text-sm font-medium">Active</label>
      </div>

      <div className="flex gap-3">
        <button type="submit"
          className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700">
          Save Hotel
        </button>
        <button type="button" onClick={() => router.back()}
          className="border px-6 py-2 rounded-lg hover:bg-gray-50">
          Cancel
        </button>
      </div>
    </form>
  )
}
```

- [ ] **Step 4: Write new hotel page with server action**

```typescript
// src/app/dashboard/hotels/new/page.tsx
import { supabaseAdmin } from '@/lib/supabase-admin'
import { HotelForm } from '@/components/hotel-form'
import { redirect } from 'next/navigation'

async function createHotel(fd: FormData) {
  'use server'
  await supabaseAdmin.from('hotels').insert({
    name:              fd.get('name') as string,
    subscription_plan: fd.get('subscription_plan') as string,
    default_sla_hours: Number(fd.get('default_sla_hours')),
    default_language:  fd.get('default_language') as string,
    theme_colors:      JSON.parse(fd.get('theme_colors') as string),
    is_active:         fd.get('is_active') === 'on',
    storage_quota_gb:  fd.get('subscription_plan') === 'enterprise' ? 200
                     : fd.get('subscription_plan') === 'pro' ? 50 : 10,
  })
  redirect('/dashboard/hotels')
}

export default function NewHotelPage() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">New Hotel</h1>
      <HotelForm
        hotel={{ name: '', subscription_plan: 'basic', default_sla_hours: 4,
                 default_language: 'he', is_active: true,
                 theme_colors: { primary: '#1976D2', secondary: '#424242', accent: '#FF6F00' } }}
        action={createHotel}
      />
    </div>
  )
}
```

- [ ] **Step 5: Write hotel edit page**

```typescript
// src/app/dashboard/hotels/[id]/page.tsx
import { supabaseAdmin } from '@/lib/supabase-admin'
import { HotelForm } from '@/components/hotel-form'
import { redirect } from 'next/navigation'
import { notFound } from 'next/navigation'

export default async function EditHotelPage({ params }: { params: { id: string } }) {
  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('*')
    .eq('id', params.id)
    .single()

  if (!hotel) notFound()

  async function updateHotel(fd: FormData) {
    'use server'
    await supabaseAdmin.from('hotels').update({
      name:              fd.get('name') as string,
      subscription_plan: fd.get('subscription_plan') as string,
      default_sla_hours: Number(fd.get('default_sla_hours')),
      default_language:  fd.get('default_language') as string,
      theme_colors:      JSON.parse(fd.get('theme_colors') as string),
      is_active:         fd.get('is_active') === 'on',
    }).eq('id', params.id)
    redirect('/dashboard/hotels')
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Edit Hotel: {hotel.name}</h1>
      <HotelForm hotel={{
        id: hotel.id,
        name: hotel.name,
        subscription_plan: hotel.subscription_plan,
        default_sla_hours: hotel.default_sla_hours,
        default_language: hotel.default_language,
        is_active: hotel.is_active,
        theme_colors: hotel.theme_colors,
      }} action={updateHotel} />
    </div>
  )
}
```

- [ ] **Step 6: Commit**

```bash
git add admin/src/
git commit -m "feat: add hotels management with theme picker and edit page"
```

---

## Task 5: Global Users + Audit Logs

**Files:**
- Create: `admin/src/app/dashboard/users/page.tsx`
- Create: `admin/src/app/dashboard/logs/page.tsx`

- [ ] **Step 1: Write global users page**

```typescript
// src/app/dashboard/users/page.tsx
import { supabaseAdmin } from '@/lib/supabase-admin'

export default async function UsersPage({
  searchParams,
}: {
  searchParams: { hotel?: string; role?: string }
}) {
  let query = supabaseAdmin
    .from('users')
    .select('*, hotel:hotels(name)')
    .order('created_at', { ascending: false })

  if (searchParams.hotel) query = query.eq('hotel_id', searchParams.hotel) as any
  if (searchParams.role)  query = query.eq('role', searchParams.role) as any

  const { data: users } = await query

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">All Users ({users?.length ?? 0})</h1>
      <div className="bg-white rounded-xl border overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              {['Name','Email','Hotel','Role','Status','Actions'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-sm font-medium text-gray-500">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y">
            {(users ?? []).map(user => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{user.full_name}</td>
                <td className="px-4 py-3 text-sm text-gray-600">{user.email}</td>
                <td className="px-4 py-3 text-sm">{(user.hotel as any)?.name ?? '—'}</td>
                <td className="px-4 py-3">
                  <span className="bg-gray-100 text-xs px-2 py-1 rounded-full">{user.role}</span>
                </td>
                <td className="px-4 py-3">
                  <span className={`text-xs px-2 py-1 rounded-full ${user.is_active
                    ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                    {user.is_active ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <form action={async (fd: FormData) => {
                    'use server'
                    const id = fd.get('id') as string
                    const active = fd.get('active') === 'true'
                    await supabaseAdmin.from('users').update({ is_active: !active }).eq('id', id)
                  }}>
                    <input type="hidden" name="id" value={user.id} />
                    <input type="hidden" name="active" value={String(user.is_active)} />
                    <button type="submit" className="text-sm text-blue-600 hover:underline">
                      {user.is_active ? 'Deactivate' : 'Activate'}
                    </button>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Write audit logs page**

```typescript
// src/app/dashboard/logs/page.tsx
import { supabaseAdmin } from '@/lib/supabase-admin'

export default async function LogsPage() {
  const { data: logs } = await supabaseAdmin
    .from('ticket_updates')
    .select('*, user:users(full_name, hotel_id), hotel:hotels(name)')
    .order('created_at', { ascending: false })
    .limit(200)

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Audit Logs (last 200)</h1>
      <div className="bg-white rounded-xl border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              {['Time','Hotel','User','Action','Details'].map(h => (
                <th key={h} className="px-4 py-3 text-left font-medium text-gray-500">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y">
            {(logs ?? []).map(log => (
              <tr key={log.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                  {new Date(log.created_at).toLocaleString()}
                </td>
                <td className="px-4 py-3">{(log.hotel as any)?.name ?? '—'}</td>
                <td className="px-4 py-3">{(log.user as any)?.full_name ?? '—'}</td>
                <td className="px-4 py-3">
                  <span className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">
                    {log.update_type}
                  </span>
                </td>
                <td className="px-4 py-3 text-gray-600 max-w-xs truncate">{log.message ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
git add admin/src/app/dashboard/
git commit -m "feat: add global users and audit logs pages"
```

---

## Task 6: Global Analytics

**Files:**
- Create: `admin/src/app/dashboard/analytics/page.tsx`

- [ ] **Step 1: Write analytics page**

```typescript
// src/app/dashboard/analytics/page.tsx
import { supabaseAdmin } from '@/lib/supabase-admin'

export default async function AnalyticsPage() {
  const { data: hotels } = await supabaseAdmin
    .from('hotels')
    .select(`
      id, name,
      tickets:tickets(count),
      open_tickets:tickets(count).filter(status.eq.open),
      resolved_tickets:tickets(count).filter(status.in.(resolved,closed))
    `)
    .eq('is_active', true)

  // Fallback: simple query if nested aggregates not supported
  const { data: ticketsByHotel } = await supabaseAdmin
    .from('tickets')
    .select('hotel_id, status, hotels(name)')

  const hotelMap: Record<string, { name: string; total: number; open: number; resolved: number }> = {}
  for (const t of ticketsByHotel ?? []) {
    const id = t.hotel_id
    const name = (t.hotels as any)?.name ?? id
    if (!hotelMap[id]) hotelMap[id] = { name, total: 0, open: 0, resolved: 0 }
    hotelMap[id].total++
    if (['resolved','closed'].includes(t.status)) hotelMap[id].resolved++
    else hotelMap[id].open++
  }

  const rows = Object.values(hotelMap).sort((a, b) => b.total - a.total)

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Global Analytics</h1>
      <div className="bg-white rounded-xl border overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              {['Hotel','Total Tickets','Open','Resolved','Resolution Rate'].map(h => (
                <th key={h} className="px-4 py-3 text-left text-sm font-medium text-gray-500">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y">
            {rows.map(h => (
              <tr key={h.name} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{h.name}</td>
                <td className="px-4 py-3">{h.total}</td>
                <td className="px-4 py-3 text-orange-600">{h.open}</td>
                <td className="px-4 py-3 text-green-600">{h.resolved}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <div className="w-24 bg-gray-200 rounded-full h-2">
                      <div className="bg-green-500 h-2 rounded-full"
                        style={{ width: `${h.total ? (h.resolved / h.total) * 100 : 0}%` }} />
                    </div>
                    <span className="text-sm">
                      {h.total ? Math.round((h.resolved / h.total) * 100) : 0}%
                    </span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/src/app/dashboard/analytics/
git commit -m "feat: add global analytics page"
```

---

## Task 7: Build + Deploy

- [ ] **Step 1: Test production build**

```bash
cd admin && npm run build
```
Expected: No errors. `.next/` directory created.

- [ ] **Step 2: Test locally**

```bash
npm start
```
Visit http://localhost:3000 → verify all pages work.

- [ ] **Step 3: Deploy to Vercel (recommended)**

```bash
npm install -g vercel
vercel --prod
```
Set environment variables in Vercel dashboard:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY` (mark as sensitive)
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

- [ ] **Step 4: Verify deployment**

Visit the Vercel URL → login → all pages load with live Supabase data.

- [ ] **Step 5: Update PROGRESS.md**

Mark all 5 plans as complete.

- [ ] **Step 6: Commit**

```bash
cd "/Users/boazsaada/manegmant resapceon"
git add .
git commit -m "feat: complete super admin panel - all 5 plans done"
```

---

## Verification Checklist

Before declaring complete:

- [ ] `npm run build` passes with no errors
- [ ] Login with MFA works (enroll via Supabase dashboard first)
- [ ] Hotels page lists all hotels + create new works
- [ ] Theme picker saves colors and Flutter app reflects them on next login
- [ ] Global users page shows users from all hotels
- [ ] Deactivate/Activate user updates DB
- [ ] Audit logs show recent ticket_updates across all hotels
- [ ] Global analytics shows per-hotel resolution rates
- [ ] Service role key is NOT in any client-side bundle (run: `grep -r "service_role" .next/` → 0 results)
