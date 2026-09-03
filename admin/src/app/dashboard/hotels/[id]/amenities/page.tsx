import { supabaseAdmin } from '@/lib/supabase-admin'
import {
  assertHotelAccess,
  assertHotelMutationAllowed,
  requireDashboardViewer,
  verifyDashboardViewerForAction,
} from '@/lib/auth-guard'
import { redirect, notFound } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { AmenitiesManager } from './amenities-manager'

export default async function HotelAmenitiesPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  const viewer = await requireDashboardViewer()
  assertHotelAccess(viewer, id)

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('id, name, enabled_features')
    .eq('id', id)
    .single()
  if (!hotel) notFound()

  const { data: amenities } = await supabaseAdmin
    .from('hotel_amenities')
    .select('id, category, name, description, price, currency, image_url, is_active, sort_order')
    .eq('hotel_id', id)
    .order('category')
    .order('sort_order')

  async function createAmenity(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer) redirect('/login')
    assertHotelMutationAllowed(viewer, id)

    const name = (formData.get('name') as string)?.trim()
    const category = formData.get('category') as string
    if (!name || !category) return

    const priceRaw = (formData.get('price') as string)?.trim()
    const description = (formData.get('description') as string)?.trim()
    const imageUrl = (formData.get('image_url') as string)?.trim()

    await supabaseAdmin.from('hotel_amenities').insert({
      hotel_id: id,
      category,
      name,
      description: description || null,
      price: priceRaw ? Number(priceRaw) : null,
      image_url: imageUrl || null,
    })
    revalidatePath(`/dashboard/hotels/${id}/amenities`)
  }

  async function toggleAmenityActive(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer) redirect('/login')
    assertHotelMutationAllowed(viewer, id)

    const amenityId = formData.get('amenity_id') as string
    const nextActive = formData.get('next_active') === 'true'
    await supabaseAdmin
      .from('hotel_amenities')
      .update({ is_active: nextActive })
      .eq('id', amenityId)
      .eq('hotel_id', id)
    revalidatePath(`/dashboard/hotels/${id}/amenities`)
  }

  async function deleteAmenity(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer) redirect('/login')
    assertHotelMutationAllowed(viewer, id)

    const amenityId = formData.get('amenity_id') as string
    await supabaseAdmin.from('hotel_amenities').delete().eq('id', amenityId).eq('hotel_id', id)
    revalidatePath(`/dashboard/hotels/${id}/amenities`)
  }

  const enabled = Boolean(
    (hotel.enabled_features as Record<string, boolean> | null)?.amenities_ordering,
  )

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-2">🍽️ שירותים נוספים — {hotel.name}</h1>
      <p className={`text-sm mb-6 ${enabled ? 'text-green-600' : 'text-amber-600'}`}>
        {enabled
          ? '✓ המודול פעיל למלון זה — אורחים יכולים להזמין'
          : '⚠ המודול כבוי למלון זה — הקטלוג נשמר אך אורחים לא רואים אותו. הפעל בעמוד עריכת המלון.'}
      </p>

      <AmenitiesManager
        amenities={amenities ?? []}
        createAction={createAmenity}
        toggleAction={toggleAmenityActive}
        deleteAction={deleteAmenity}
      />
    </div>
  )
}
