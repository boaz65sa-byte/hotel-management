import { supabaseAdmin } from '@/lib/supabase-admin'
import {
  assertHotelAccess,
  requireDashboardViewer,
  verifyDashboardViewerForAction,
} from '@/lib/auth-guard'
import { redirect, notFound } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { DepartmentsManager } from './departments-manager'

export default async function HotelDepartmentsPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  const viewer = await requireDashboardViewer()
  assertHotelAccess(viewer, id)
  // Boaz: only the super admin decides which departments a hotel uses —
  // same restriction as the RLS policy on hotel_ticket_departments_disabled.
  if (!viewer.isSuperAdmin) notFound()

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .eq('id', id)
    .single()
  if (!hotel) notFound()

  const { data: disabled } = await supabaseAdmin
    .from('hotel_ticket_departments_disabled')
    .select('department')
    .eq('hotel_id', id)

  async function setDepartmentEnabled(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer) redirect('/login')
    if (!viewer.isSuperAdmin) notFound()

    const department = formData.get('department') as string
    const nextEnabled = formData.get('next_enabled') === 'true'

    if (nextEnabled) {
      await supabaseAdmin
        .from('hotel_ticket_departments_disabled')
        .delete()
        .eq('hotel_id', id)
        .eq('department', department)
    } else {
      await supabaseAdmin
        .from('hotel_ticket_departments_disabled')
        .upsert(
          { hotel_id: id, department },
          { onConflict: 'hotel_id,department' },
        )
    }
    revalidatePath(`/dashboard/hotels/${id}/departments`)
  }

  const disabledDepartments = (disabled ?? []).map((r) => r.department as string)

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-2">🏢 מחלקות צוות — {hotel.name}</h1>
      <p className="text-sm text-gray-500 mb-6">
        בחר אילו מחלקות פעילות במלון הזה — צוות יכול לפתוח ולנתב קריאות רק למחלקות פעילות,
        ורק מנהלים יכולים ליצור משתמשי צוות במחלקה פעילה.
      </p>

      <DepartmentsManager
        disabledDepartments={disabledDepartments}
        setDepartmentAction={setDepartmentEnabled}
      />
    </div>
  )
}
