'use server'

import { supabaseAdmin } from '@/lib/supabase-admin'
import { redirect } from 'next/navigation'

import { verifyDashboardViewerForAction } from '@/lib/auth-guard'

/**
 * Permanently deletes a hotel and all its dependent data.
 *
 * Caution: this is destructive — relies on FK ON DELETE CASCADE in the schema.
 * Auth users for the hotel staff are NOT deleted (their accounts remain).
 */
export async function deleteHotel(
  hotelId: string,
  confirmName: string,
): Promise<{ ok: boolean; error?: string }> {
  const viewer = await verifyDashboardViewerForAction()
  if (!viewer?.isSuperAdmin) {
    return { ok: false, error: 'Forbidden' }
  }

  if (!hotelId || !confirmName) {
    return { ok: false, error: 'Missing arguments' }
  }

  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('name')
    .eq('id', hotelId)
    .single()
  if (!hotel) return { ok: false, error: 'Hotel not found' }

  if (hotel.name !== confirmName) {
    return { ok: false, error: 'Hotel name confirmation does not match' }
  }

  const { error } = await supabaseAdmin.from('hotels').delete().eq('id', hotelId)
  if (error) return { ok: false, error: error.message }

  // Redirect on success — caller may also do this.
  redirect('/dashboard/hotels')
}
