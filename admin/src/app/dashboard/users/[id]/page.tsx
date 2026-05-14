import { requireDashboardViewer } from '@/lib/auth-guard'

import EditUserClient from './edit-user-client'

export default async function EditUserPage() {
  const viewer = await requireDashboardViewer()
  const lockedHotelId =
    viewer.isHotelTierAdmin && viewer.hotelId ? viewer.hotelId : null
  return (
    <EditUserClient
      isSuperAdmin={viewer.isSuperAdmin}
      lockedHotelId={lockedHotelId}
    />
  )
}
