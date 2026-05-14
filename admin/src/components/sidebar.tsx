'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useLang } from '@/lib/i18n'

export type SidebarViewer = {
  isSuperAdmin: boolean
  hotelId: string | null
  hotelName?: string
  displayName: string
}

type NavDef = {
  href: string
  label: string
  icon: string
}

export function Sidebar({ viewer }: { viewer: SidebarViewer }) {
  const pathname = usePathname()
  const { t, lang, setLang } = useLang()

  const overview = { href: '/dashboard', label: t.overview, icon: '📊' as const }

  const superNav: NavDef[] = [
    overview,
    { href: '/dashboard/hotels', label: t.hotels, icon: '🏨' },
    { href: '/dashboard/users', label: t.users, icon: '👥' },
    { href: '/dashboard/analytics', label: t.analytics, icon: '📈' },
    { href: '/dashboard/logs', label: t.auditLogs, icon: '📋' },
    {
      href: '/dashboard/checklists',
      label: lang === 'he' ? 'צ׳קליסטים' : 'Checklists',
      icon: '✅',
    },
    {
      href: '/dashboard/automations',
      label: lang === 'he' ? 'אוטומציות' : 'Automations',
      icon: '⚡',
    },
    {
      href: '/dashboard/guest-requests',
      label: lang === 'he' ? 'בקשות אורחים' : 'Guest requests',
      icon: '🛎️',
    },
    {
      href: '/dashboard/guest-feedback',
      label: lang === 'he' ? 'משובים' : 'Feedback',
      icon: '⭐',
    },
  ]

  const hotelScopedNav: NavDef[] = viewer.hotelId
    ? [
        overview,
        {
          href: `/dashboard/hotels/${viewer.hotelId}`,
          label: viewer.hotelName
            ? `${viewer.hotelName}`
            : lang === 'he'
              ? 'המלון שלי'
              : 'My hotel',
          icon: '🏨',
        },
        { href: '/dashboard/users', label: t.users, icon: '👥' },
        { href: '/dashboard/analytics', label: t.analytics, icon: '📈' },
        {
          href: `/dashboard/automations?hotel_id=${viewer.hotelId}`,
          label: lang === 'he' ? 'אוטומציות' : 'Automations',
          icon: '⚡',
        },
        {
          href: '/dashboard/guest-requests',
          label: lang === 'he' ? 'בקשות אורחים' : 'Guest requests',
          icon: '🛎️',
        },
        {
          href: '/dashboard/guest-feedback',
          label: lang === 'he' ? 'משובים' : 'Feedback',
          icon: '⭐',
        },
      ]
    : [overview]

  const nav = viewer.isSuperAdmin ? superNav : hotelScopedNav

  const branding = viewer.isSuperAdmin
    ? t.superAdmin
    : viewer.hotelName
      ? `${viewer.hotelName}`
      : lang === 'he'
        ? 'ניהול מלון'
        : 'Hotel admin'

  return (
    <aside className="w-56 bg-gray-900 text-white min-h-screen p-4 flex flex-col">
      <div className="text-xl font-bold mb-2 px-2">{branding}</div>
      <div className="text-xs text-gray-400 px-2 mb-6 truncate">
        {viewer.displayName.replace(/[<>'"]+/g, '')}
      </div>
      <nav className="space-y-1 flex-1">
        {nav.map((item) => {
          const active =
            pathname === item.href ||
            (item.href !== '/dashboard' && pathname.startsWith(item.href.split('?')[0]))
          return (
            <Link
              key={`${item.href}-${item.label}`}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                active
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-100 hover:bg-gray-800 hover:text-white'
              }`}
            >
              <span>{item.icon}</span>
              {item.label}
            </Link>
          )
        })}
      </nav>
      <div className="flex items-center gap-2 px-3 py-2 mb-2">
        <span className="text-gray-400 text-xs">{t.language}:</span>
        <button
          type="button"
          onClick={() => setLang('he')}
          className={`text-xs px-2 py-1 rounded ${lang === 'he' ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'}`}>
          עב
        </button>
        <button
          type="button"
          onClick={() => setLang('en')}
          className={`text-xs px-2 py-1 rounded ${lang === 'en' ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'}`}>
          EN
        </button>
      </div>
      <a href="/api/logout" className="text-gray-400 hover:text-white text-sm px-3 py-2">
        {t.signOut}
      </a>
    </aside>
  )
}
