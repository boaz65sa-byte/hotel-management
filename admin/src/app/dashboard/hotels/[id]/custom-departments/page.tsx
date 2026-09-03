import { supabaseAdmin } from '@/lib/supabase-admin'
import {
  assertHotelAccess,
  requireDashboardViewer,
  verifyDashboardViewerForAction,
} from '@/lib/auth-guard'
import { redirect, notFound } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { CustomDepartmentsManager } from './custom-departments-manager'

export default async function CustomDepartmentsPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  const viewer = await requireDashboardViewer()
  assertHotelAccess(viewer, id)
  if (!viewer.isSuperAdmin) notFound()

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .eq('id', id)
    .single()
  if (!hotel) notFound()

  const { data: departments } = await supabaseAdmin
    .from('hotel_departments')
    .select('id, key, label, icon, is_active, created_at')
    .eq('hotel_id', id)
    .order('created_at')

  async function createDepartment(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer?.isSuperAdmin) redirect('/login')

    const label = (formData.get('label') as string)?.trim()
    const icon = (formData.get('icon') as string)?.trim() || '🏷️'
    if (!label) return

    const key = label
      .toLowerCase()
      .replace(/[^\p{L}\p{N}]+/gu, '_')
      .replace(/^_+|_+$/g, '')
      || `dept_${Date.now()}`

    await supabaseAdmin.from('hotel_departments').insert({
      hotel_id: id,
      key,
      label,
      icon,
    })
    revalidatePath(`/dashboard/hotels/${id}/custom-departments`)
  }

  async function toggleDepartmentActive(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer?.isSuperAdmin) redirect('/login')

    const departmentId = formData.get('department_id') as string
    const nextActive = formData.get('next_active') === 'true'
    await supabaseAdmin
      .from('hotel_departments')
      .update({ is_active: nextActive })
      .eq('id', departmentId)
      .eq('hotel_id', id)
    revalidatePath(`/dashboard/hotels/${id}/custom-departments`)
  }

  async function deleteDepartment(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer?.isSuperAdmin) redirect('/login')

    const departmentId = formData.get('department_id') as string
    // Blocked by the FK from users.department_id / tickets.custom_department_id
    // if anyone/anything still references it — surfaces as a no-op below
    // rather than a crash; the manager UI explains why via the count.
    await supabaseAdmin.from('hotel_departments').delete().eq('id', departmentId).eq('hotel_id', id)
    revalidatePath(`/dashboard/hotels/${id}/custom-departments`)
  }

  const { data: usersByDept } = await supabaseAdmin
    .from('users')
    .select('department_id')
    .eq('hotel_id', id)
    .not('department_id', 'is', null)

  const userCounts = new Map<string, number>()
  for (const u of usersByDept ?? []) {
    if (!u.department_id) continue
    userCounts.set(u.department_id, (userCounts.get(u.department_id) ?? 0) + 1)
  }

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-2">🏷️ מחלקות מותאמות אישית — {hotel.name}</h1>
      <p className="text-sm text-gray-600 mb-6">
        מחלקות חדשות לגמרי (עם מנהל ועובדים משלהן), מעבר ל-5 המחלקות המובנות
        (קבלה/אחזקה/משק בית/ביטחון/מטבח). אחרי יצירת מחלקה כאן, ניתן להוסיף לה
        משתמשים בעמוד <span className="font-medium">משתמשים</span> עם התפקיד
        &quot;מנהל/עובד מחלקה מותאמת&quot;. מחלקה עם משתמשים משויכים לא ניתנת למחיקה —
        רק לכיבוי.
      </p>

      <CustomDepartmentsManager
        departments={(departments ?? []).map((d) => ({
          ...d,
          userCount: userCounts.get(d.id) ?? 0,
        }))}
        createAction={createDepartment}
        toggleAction={toggleDepartmentActive}
        deleteAction={deleteDepartment}
      />
    </div>
  )
}
