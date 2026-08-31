import { supabaseAdmin } from '@/lib/supabase-admin'
import {
  assertHotelAccess,
  requireDashboardViewer,
  verifyDashboardViewerForAction,
} from '@/lib/auth-guard'
import { redirect, notFound } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { TicketVisibilityManager } from './ticket-visibility-manager'

export default async function HotelTicketVisibilityPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  const viewer = await requireDashboardViewer()
  assertHotelAccess(viewer, id)
  // Boaz: only the super admin decides whether a department manager sees
  // the whole hotel's tickets or just their own department's — same
  // restriction as the RLS policy on hotel_role_ticket_scope.
  if (!viewer.isSuperAdmin) notFound()

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .eq('id', id)
    .single()
  if (!hotel) notFound()

  const { data: overrides } = await supabaseAdmin
    .from('hotel_role_ticket_scope')
    .select('role, scope')
    .eq('hotel_id', id)

  async function setScope(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer) redirect('/login')
    if (!viewer.isSuperAdmin) notFound()

    const role = formData.get('role') as string
    const nextScope = formData.get('next_scope') as string

    if (nextScope === 'all_departments') {
      await supabaseAdmin
        .from('hotel_role_ticket_scope')
        .delete()
        .eq('hotel_id', id)
        .eq('role', role)
    } else {
      await supabaseAdmin
        .from('hotel_role_ticket_scope')
        .upsert(
          { hotel_id: id, role, scope: nextScope },
          { onConflict: 'hotel_id,role' },
        )
    }
    revalidatePath(`/dashboard/hotels/${id}/ticket-visibility`)
  }

  const restrictedRoles = (overrides ?? [])
    .filter((r) => r.scope === 'own_department_only')
    .map((r) => r.role as string)

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-2">👁️ ראייה בין מחלקות — {hotel.name}</h1>
      <p className="text-sm text-gray-500 mb-6">
        ברירת המחדל: כל מנהל רואה את כל הקריאות במלון, בכל המחלקות. אפשר להגביל מנהל מחלקה ספציפי
        לראות רק את הקריאות של המחלקה שלו (בנוסף לכל קריאה שהוא עצמו פתח/טיפל בה, גם אם היא במחלקה אחרת).
      </p>

      <TicketVisibilityManager
        restrictedRoles={restrictedRoles}
        setScopeAction={setScope}
      />
    </div>
  )
}
