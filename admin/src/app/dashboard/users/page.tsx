import { supabaseAdmin } from '@/lib/supabase-admin'
import { revalidatePath } from 'next/cache'
import Link from 'next/link'

type HotelRel = { name?: string } | { name?: string }[] | null
function hotelName(rel: HotelRel): string | undefined {
  if (!rel) return undefined
  return Array.isArray(rel) ? rel[0]?.name : rel.name
}

type UserRow = {
  id: string
  full_name: string | null
  email: string | null
  role: string | null
  is_active: boolean
  hotel_id: string | null
  hotel?: HotelRel
}

type HotelLite = { id: string; name: string; logo_url: string | null }

const ROLE_LABEL: Record<string, string> = {
  super_admin:    '👑 סופר אדמין',
  hotel_admin:    '🛡️ אדמין מלון',
  hotel_manager:  '👔 מנהל מלון',
  dept_manager:   '📋 מנהל מחלקה',
  reception:      '📞 קבלה',
  maintenance:    '🔧 אחזקה',
  housekeeping:   '🧹 משק בית',
  security:       '🛡️ ביטחון',
  staff:          '👤 עובד',
}

function roleBadge(role: string | null) {
  if (!role) return '—'
  return ROLE_LABEL[role] ?? role
}

async function toggleActive(fd: FormData) {
  'use server'
  const id = fd.get('id') as string
  const active = fd.get('active') === 'true'
  await supabaseAdmin.from('users').update({ is_active: !active }).eq('id', id)
  revalidatePath('/dashboard/users')
}

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ hotel?: string; role?: string; q?: string }>
}) {
  const { hotel, role, q } = await searchParams

  let query = supabaseAdmin
    .from('users')
    .select('id, full_name, email, role, is_active, hotel_id, hotel:hotels(name)')
    .order('full_name', { ascending: true })

  if (hotel) query = query.eq('hotel_id', hotel)
  if (role)  query = query.eq('role', role)

  const { data: usersRaw } = await query
  let users: UserRow[] = (usersRaw ?? []) as UserRow[]

  if (q && q.trim()) {
    const needle = q.trim().toLowerCase()
    users = users.filter(u =>
      (u.full_name ?? '').toLowerCase().includes(needle) ||
      (u.email ?? '').toLowerCase().includes(needle),
    )
  }

  const { data: hotelsRaw } = await supabaseAdmin
    .from('hotels')
    .select('id, name, logo_url')
    .order('name', { ascending: true })
  const hotels: HotelLite[] = (hotelsRaw ?? []) as HotelLite[]

  const usersByHotel = new Map<string, UserRow[]>()
  const superAdmins: UserRow[] = []
  for (const u of users) {
    if (!u.hotel_id) {
      superAdmins.push(u)
      continue
    }
    if (!usersByHotel.has(u.hotel_id)) usersByHotel.set(u.hotel_id, [])
    usersByHotel.get(u.hotel_id)!.push(u)
  }

  const total = users.length
  const totalActive = users.filter(u => u.is_active).length

  return (
    <div dir="rtl">
      <div className="flex flex-wrap items-center justify-between gap-3 mb-6">
        <div>
          <h1 className="text-2xl font-bold">משתמשים — {total}</h1>
          <p className="text-sm text-gray-500 mt-1">
            פעילים: {totalActive} · לפי {hotels.length} מלונות
          </p>
        </div>
        <Link
          href="/dashboard/users/new"
          className="bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700"
        >
          + הוסף משתמש
        </Link>
      </div>

      <form className="bg-white border rounded-xl p-3 mb-6 flex flex-wrap items-center gap-3">
        <input
          name="q" defaultValue={q ?? ''}
          placeholder="חיפוש לפי שם או מייל…"
          className="flex-1 min-w-[200px] border rounded px-3 py-2 text-sm"
        />
        <select name="hotel" defaultValue={hotel ?? ''} className="border rounded px-3 py-2 text-sm">
          <option value="">כל המלונות</option>
          {hotels.map(h => (
            <option key={h.id} value={h.id}>{h.name}</option>
          ))}
        </select>
        <select name="role" defaultValue={role ?? ''} className="border rounded px-3 py-2 text-sm">
          <option value="">כל התפקידים</option>
          {Object.entries(ROLE_LABEL).map(([v, l]) => (
            <option key={v} value={v}>{l}</option>
          ))}
        </select>
        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded text-sm hover:bg-blue-700">
          סנן
        </button>
        {(q || hotel || role) && (
          <Link href="/dashboard/users" className="text-sm text-gray-500 hover:underline">
            איפוס
          </Link>
        )}
      </form>

      {superAdmins.length > 0 && (
        <HotelSection
          icon="👑"
          name="סופר אדמינים — גישה לכל המלונות"
          users={superAdmins}
          tone="purple"
        />
      )}

      {hotels
        .filter(h => usersByHotel.has(h.id))
        .map(h => (
          <HotelSection
            key={h.id}
            icon={h.logo_url ? undefined : '🏨'}
            logo={h.logo_url ?? undefined}
            name={h.name}
            hotelId={h.id}
            users={usersByHotel.get(h.id) ?? []}
            tone="blue"
          />
        ))}

      {Array.from(usersByHotel.keys())
        .filter(hid => !hotels.find(h => h.id === hid))
        .map(orphanHotelId => {
          const orphanUsers = usersByHotel.get(orphanHotelId) ?? []
          return (
            <HotelSection
              key={orphanHotelId}
              icon="⚠️"
              name={`מלון לא ידוע (${orphanHotelId.slice(0, 8)}…)`}
              users={orphanUsers}
              tone="amber"
            />
          )
        })}

      {total === 0 && (
        <div className="bg-white border rounded-xl p-12 text-center text-gray-500">
          לא נמצאו משתמשים מתאימים.{' '}
          <Link href="/dashboard/users/new" className="text-blue-600 hover:underline">
            הוסף משתמש חדש
          </Link>
        </div>
      )}
    </div>
  )
}

function HotelSection({
  icon, logo, name, hotelId, users, tone,
}: {
  icon?: string
  logo?: string
  name: string
  hotelId?: string
  users: UserRow[]
  tone: 'purple' | 'blue' | 'amber'
}) {
  const toneCls = {
    purple: 'from-purple-50 to-indigo-50 border-purple-200',
    blue:   'from-blue-50 to-sky-50 border-blue-200',
    amber:  'from-amber-50 to-orange-50 border-amber-200',
  }[tone]

  return (
    <section className={`bg-gradient-to-r ${toneCls} border-2 rounded-xl mb-5 overflow-hidden`}>
      <header className="flex items-center justify-between gap-3 px-5 py-3 bg-white/40 backdrop-blur-sm">
        <div className="flex items-center gap-3">
          {logo ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={logo} alt={name} className="w-10 h-10 rounded-lg object-cover border" />
          ) : (
            <span className="text-2xl">{icon}</span>
          )}
          <div>
            <h2 className="font-bold text-gray-900">{name}</h2>
            <p className="text-xs text-gray-500">{users.length} משתמשים</p>
          </div>
        </div>
        {hotelId && (
          <Link
            href={`/dashboard/hotels/${hotelId}`}
            className="text-xs text-blue-700 hover:underline"
          >
            → ניהול המלון
          </Link>
        )}
      </header>

      <div className="bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-y border-gray-200 text-xs">
            <tr>
              <th className="px-4 py-2 text-right font-medium text-gray-500">שם</th>
              <th className="px-4 py-2 text-right font-medium text-gray-500">מייל</th>
              <th className="px-4 py-2 text-right font-medium text-gray-500">תפקיד</th>
              <th className="px-4 py-2 text-right font-medium text-gray-500">סטטוס</th>
              <th className="px-4 py-2 text-right font-medium text-gray-500">פעולות</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {users.map(u => (
              <tr key={u.id} className="hover:bg-gray-50">
                <td className="px-4 py-2.5 font-medium">{u.full_name ?? '—'}</td>
                <td className="px-4 py-2.5 text-gray-600" dir="ltr">{u.email ?? '—'}</td>
                <td className="px-4 py-2.5">
                  <span className="bg-gray-100 text-xs px-2 py-1 rounded-full">{roleBadge(u.role)}</span>
                </td>
                <td className="px-4 py-2.5">
                  <span className={`text-xs px-2 py-1 rounded-full ${
                    u.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {u.is_active ? 'פעיל' : 'מושעה'}
                  </span>
                </td>
                <td className="px-4 py-2.5 flex items-center gap-3">
                  <Link href={`/dashboard/users/${u.id}`} className="text-sm text-blue-600 hover:underline">
                    ערוך
                  </Link>
                  <form action={toggleActive}>
                    <input type="hidden" name="id" value={u.id} />
                    <input type="hidden" name="active" value={String(u.is_active)} />
                    <button type="submit" className="text-sm text-gray-500 hover:underline">
                      {u.is_active ? 'השעה' : 'הפעל'}
                    </button>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}
