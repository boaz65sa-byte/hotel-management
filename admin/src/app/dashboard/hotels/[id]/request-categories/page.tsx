import { supabaseAdmin } from '@/lib/supabase-admin'
import {
  assertHotelAccess,
  requireDashboardViewer,
  verifyDashboardViewerForAction,
} from '@/lib/auth-guard'
import { redirect, notFound } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { RequestCategoriesManager } from './request-categories-manager'

export default async function RequestCategoriesPage({
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

  const { data: categories } = await supabaseAdmin
    .from('hotel_request_categories')
    .select('id, key, label, icon, is_system, is_active, sort_order')
    .eq('hotel_id', id)
    .order('sort_order')

  async function createCategory(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer?.isSuperAdmin) redirect('/login')

    const label = (formData.get('label') as string)?.trim()
    const icon = (formData.get('icon') as string)?.trim() || '📋'
    if (!label) return

    const key = label
      .toLowerCase()
      .replace(/[^\p{L}\p{N}]+/gu, '_')
      .replace(/^_+|_+$/g, '')
      || `category_${Date.now()}`

    await supabaseAdmin.from('hotel_request_categories').insert({
      hotel_id: id,
      key,
      label,
      icon,
      is_system: false,
    })
    revalidatePath(`/dashboard/hotels/${id}/request-categories`)
  }

  async function toggleCategoryActive(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer?.isSuperAdmin) redirect('/login')

    const categoryId = formData.get('category_id') as string
    const nextActive = formData.get('next_active') === 'true'
    await supabaseAdmin
      .from('hotel_request_categories')
      .update({ is_active: nextActive })
      .eq('id', categoryId)
      .eq('hotel_id', id)
    revalidatePath(`/dashboard/hotels/${id}/request-categories`)
  }

  async function deleteCategory(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer?.isSuperAdmin) redirect('/login')

    const categoryId = formData.get('category_id') as string
    // System categories (housekeeping/maintenance/reception) can be
    // disabled but never deleted — the guest app ships curated quick-select
    // tiles and staff-side role routing keyed to those 3.
    await supabaseAdmin
      .from('hotel_request_categories')
      .delete()
      .eq('id', categoryId)
      .eq('hotel_id', id)
      .eq('is_system', false)
    revalidatePath(`/dashboard/hotels/${id}/request-categories`)
  }

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-2">🧾 קטגוריות בקשה — {hotel.name}</h1>
      <p className="text-sm text-gray-600 mb-6">
        קטגוריות אלו מוצגות לאורח במסך &quot;בקשה חדשה&quot;. שלוש הקטגוריות הבסיסיות (חדרניות/תחזוקה/קבלה)
        אפשר לכבות אך לא למחוק. קטגוריות חדשות שתוסיף כאן יופיעו לאורח ללא כרטיסיות מהירות
        (רק תיאור חופשי), ובקשות שיוגשו אליהן יופיעו אצל הקבלה וההנהלה.
      </p>

      <RequestCategoriesManager
        categories={categories ?? []}
        createAction={createCategory}
        toggleAction={toggleCategoryActive}
        deleteAction={deleteCategory}
      />
    </div>
  )
}
