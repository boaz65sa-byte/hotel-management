import { supabaseAdmin } from '@/lib/supabase-admin'
import {
  assertHotelAccess,
  requireDashboardViewer,
  verifyDashboardViewerForAction,
} from '@/lib/auth-guard'
import { redirect, notFound } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { RequestTilesManager } from './request-tiles-manager'

export default async function HotelRequestTilesPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  const viewer = await requireDashboardViewer()
  assertHotelAccess(viewer, id)
  // Boaz: only the super admin decides which quick-select tiles a hotel
  // gets — same restriction as the RLS policy on hotel_request_tiles_disabled.
  if (!viewer.isSuperAdmin) notFound()

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('id, name')
    .eq('id', id)
    .single()
  if (!hotel) notFound()

  const { data: disabled } = await supabaseAdmin
    .from('hotel_request_tiles_disabled')
    .select('category, tile_key')
    .eq('hotel_id', id)

  async function setTileEnabled(formData: FormData) {
    'use server'
    const viewer = await verifyDashboardViewerForAction()
    if (!viewer) redirect('/login')
    if (!viewer.isSuperAdmin) notFound()

    const category = formData.get('category') as string
    const tileKey = formData.get('tile_key') as string
    const nextEnabled = formData.get('next_enabled') === 'true'

    if (nextEnabled) {
      await supabaseAdmin
        .from('hotel_request_tiles_disabled')
        .delete()
        .eq('hotel_id', id)
        .eq('category', category)
        .eq('tile_key', tileKey)
    } else {
      await supabaseAdmin
        .from('hotel_request_tiles_disabled')
        .upsert(
          { hotel_id: id, category, tile_key: tileKey },
          { onConflict: 'hotel_id,category,tile_key' },
        )
    }
    revalidatePath(`/dashboard/hotels/${id}/request-tiles`)
  }

  const disabledKeys = new Set(
    (disabled ?? []).map((r) => `${r.category}:${r.tile_key}`),
  )

  return (
    <div className="p-6" dir="rtl">
      <h1 className="text-2xl font-bold mb-2">🧩 בקשה חדשה — כרטיסיות שירות — {hotel.name}</h1>
      <p className="text-sm text-gray-500 mb-6">
        בחר אילו כרטיסיות &ldquo;בחירה מהירה&rdquo; יופיעו לאורחי המלון הזה במסך &ldquo;בקשה חדשה&rdquo; (מסך האורח).
        כרטיסייה כבויה לא תוצג, אבל אפשרות &ldquo;משהו אחר&rdquo; (טקסט חופשי) תמיד נשארת זמינה.
      </p>

      <RequestTilesManager
        disabledKeys={[...disabledKeys]}
        setTileAction={setTileEnabled}
      />
    </div>
  )
}
