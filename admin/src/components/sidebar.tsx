'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useLang } from '@/lib/i18n'

export function Sidebar() {
  const pathname = usePathname()
  const { t, lang, setLang } = useLang()

  const nav = [
    { href: '/dashboard',           label: t.overview,   icon: '📊' },
    { href: '/dashboard/hotels',    label: t.hotels,     icon: '🏨' },
    { href: '/dashboard/users',     label: t.users,      icon: '👥' },
    { href: '/dashboard/analytics', label: t.analytics,  icon: '📈' },
    { href: '/dashboard/logs',      label: t.auditLogs,  icon: '📋' },
  ]

  return (
    <aside className="w-56 bg-gray-900 text-white min-h-screen p-4 flex flex-col">
      <div className="text-xl font-bold mb-8 px-2">{t.superAdmin}</div>
      <nav className="space-y-1 flex-1">
        {nav.map(item => (
          <Link key={item.href} href={item.href}
            className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors
              ${pathname === item.href
                ? 'bg-blue-600 text-white'
                : 'text-gray-100 hover:bg-gray-800 hover:text-white'}`}>
            <span>{item.icon}</span>
            {item.label}
          </Link>
        ))}
      </nav>
      <div className="flex items-center gap-2 px-3 py-2 mb-2">
        <span className="text-gray-400 text-xs">{t.language}:</span>
        <button
          onClick={() => setLang('he')}
          className={`text-xs px-2 py-1 rounded ${lang === 'he' ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'}`}>
          עב
        </button>
        <button
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
