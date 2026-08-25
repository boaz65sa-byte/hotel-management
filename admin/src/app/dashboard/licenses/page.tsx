import { requireSuperAdmin } from '@/lib/auth-guard'
import LicensesPage from './licenses-client'

export default async function LicensesRoute() {
  await requireSuperAdmin()
  return <LicensesPage />
}
