import { requireDashboardViewer } from '@/lib/auth-guard'
import { Sidebar } from '@/components/sidebar'
import { LangProvider } from '@/lib/i18n'
import { supabaseAdmin } from '@/lib/supabase-admin'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const viewer = await requireDashboardViewer()

  let scopedHotelName: string | undefined
  if (viewer.isHotelTierAdmin && viewer.hotelId) {
    const { data: h } = await supabaseAdmin
      .from('hotels')
      .select('name')
      .eq('id', viewer.hotelId)
      .single()
    scopedHotelName = h?.name ?? undefined
  }

  return (
    <LangProvider>
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar
          viewer={{
            isSuperAdmin: viewer.isSuperAdmin,
            hotelId: viewer.hotelId,
            hotelName: scopedHotelName,
            displayName: viewer.fullName ?? viewer.email ?? 'משתמש',
          }}
        />
        <main className="flex-1 p-8 overflow-auto">
          {children}
        </main>
      </div>
    </LangProvider>
  )
}
