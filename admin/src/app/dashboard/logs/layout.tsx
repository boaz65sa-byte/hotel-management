import { requireSuperAdmin } from '@/lib/auth-guard'

export default async function LogsSuperOnlyLayout({
  children,
}: {
  children: React.ReactNode
}) {
  await requireSuperAdmin()
  return children
}
