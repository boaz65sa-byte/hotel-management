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
