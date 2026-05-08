import { supabaseAdmin } from '@/lib/supabase-admin'
import { revalidatePath } from 'next/cache'
import Link from 'next/link'

type HotelRel = { name?: string } | { name?: string }[] | null
function hotelName(rel: HotelRel): string | undefined {
  if (!rel) return undefined
  return Array.isArray(rel) ? rel[0]?.name : rel.name
}

export default async function UsersPage({
  searchParams,
}: {
  searchParams: Promise<{ hotel?: string; role?: string }>
}) {
  const { hotel, role } = await searchParams
  let query = supabaseAdmin
    .from('users')
    .select('*, hotel:hotels(name)')
    .order('created_at', { ascending: false })

  if (hotel) query = query.eq('hotel_id', hotel)
  if (role)  query = query.eq('role', role)

  const { data: users } = await query

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">All Users ({users?.length ?? 0})</h1>
        <Link href="/dashboard/users/new"
          className="bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700">
          + Create User
        </Link>
      </div>
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
                <td className="px-4 py-3 text-sm">{hotelName(user.hotel as HotelRel) ?? '—'}</td>
                <td className="px-4 py-3">
                  <span className="bg-gray-100 text-xs px-2 py-1 rounded-full">{user.role}</span>
                </td>
                <td className="px-4 py-3">
                  <span className={`text-xs px-2 py-1 rounded-full ${user.is_active
                    ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                    {user.is_active ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td className="px-4 py-3 flex items-center gap-3">
                  <Link href={`/dashboard/users/${user.id}`}
                    className="text-sm text-blue-600 hover:underline">Edit</Link>
                  <form action={async (fd: FormData) => {
                    'use server'
                    const id = fd.get('id') as string
                    const active = fd.get('active') === 'true'
                    await supabaseAdmin.from('users').update({ is_active: !active }).eq('id', id)
                    revalidatePath('/dashboard/users')
                  }}>
                    <input type="hidden" name="id" value={user.id} />
                    <input type="hidden" name="active" value={String(user.is_active)} />
                    <button type="submit" className="text-sm text-gray-500 hover:underline">
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
