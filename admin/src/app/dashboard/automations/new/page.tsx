import NewAutomationClient from './new-automation-client'
import { requireDashboardViewer } from '@/lib/auth-guard'

export default async function NewAutomationPage() {
  const viewer = await requireDashboardViewer()
  const lockedHotelId = viewer.isHotelTierAdmin && viewer.hotelId ? viewer.hotelId : null
  return <NewAutomationClient lockedHotelId={lockedHotelId} />
}
