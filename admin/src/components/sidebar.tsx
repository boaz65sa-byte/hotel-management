'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'

const nav = [
  { href: '/dashboard',           label: 'Overview',   icon: '📊' },
  { href: '/dashboard/hotels',    label: 'Hotels',     icon: '🏨' },
  { href: '/dashboard/users',     label: 'Users',      icon: '👥' },
  { href: '/dashboard/analytics', label: 'Analytics',  icon: '📈' },
  { href: '/dashboard/logs',      label: 'Audit Logs', icon: '📋' },
]

export function Sidebar() {
  const pathname = usePathname()
  return (
    <aside className="w-56 bg-gray-900 text-white min-h-screen p-4 flex flex-col">
      <div className="text-xl font-bold mb-8 px-2">Super Admin</div>
      <nav className="space-y-1 flex-1">
        {nav.map(item => (
          <Link key={item.href} href={item.href}
            className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors
              ${pathname === item.href
                ? 'bg-blue-600 text-white'
                : 'text-gray-300 hover:bg-gray-800 hover:text-white'}`}>
            <span>{item.icon}</span>
            {item.label}
          </Link>
        ))}
      </nav>
      <a href="/api/logout" className="text-gray-400 hover:text-white text-sm px-3 py-2">
        Sign Out
      </a>
    </aside>
  )
}
