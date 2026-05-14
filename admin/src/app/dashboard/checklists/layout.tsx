import { requireSuperAdmin } from '@/lib/auth-guard'

export default async function ChecklistsSuperOnlyLayout({
  children,
}: {
  children: React.ReactNode
}) {
  await requireSuperAdmin()
  return children
}
