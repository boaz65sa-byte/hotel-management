import { supabaseAdmin } from '@/lib/supabase-admin'

type Rel<T> = T | T[] | null

function pickName<T extends { name?: string; full_name?: string }>(rel: Rel<T>): string | undefined {
  if (!rel) return undefined
  const r = Array.isArray(rel) ? rel[0] : rel
  return r?.name ?? r?.full_name
}

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
                <td className="px-4 py-3">{pickName(log.hotel as Rel<{ name?: string }>) ?? '—'}</td>
                <td className="px-4 py-3">{pickName(log.user as Rel<{ full_name?: string }>) ?? '—'}</td>
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
