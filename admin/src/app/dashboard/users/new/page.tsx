import NewUserClient from './new-user-client'
import { requireDashboardViewer } from '@/lib/auth-guard'

export default async function NewUserPage() {
  const viewer = await requireDashboardViewer()
  const lockedHotelId =
    viewer.isHotelTierAdmin && viewer.hotelId ? viewer.hotelId : null
  return <NewUserClient lockedHotelId={lockedHotelId} />
}
