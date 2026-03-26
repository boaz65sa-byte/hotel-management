import { supabaseAdmin } from '@/lib/supabase-admin'
import Link from 'next/link'
import { ThemePicker } from '@/components/theme-picker'

export default async function HotelsPage() {
  const { data: hotels } = await supabaseAdmin
    .from('hotels')
    .select('id, name, subscription_plan, is_active, created_at, theme')
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
              {['Name', 'Plan', 'Status', 'Theme', 'Created', 'Actions'].map(h => (
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
                <td className="px-4 py-3">
                  <ThemePicker hotel={{ id: hotel.id, theme: hotel.theme }} />
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
