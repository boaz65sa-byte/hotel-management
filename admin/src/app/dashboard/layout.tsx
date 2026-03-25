import { requireSuperAdmin } from '@/lib/auth-guard'
import { Sidebar } from '@/components/sidebar'
import { LangProvider } from '@/lib/i18n'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  await requireSuperAdmin()

  return (
    <LangProvider>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <main className="flex-1 p-8 overflow-auto">
          {children}
        </main>
      </div>
    </LangProvider>
  )
}
