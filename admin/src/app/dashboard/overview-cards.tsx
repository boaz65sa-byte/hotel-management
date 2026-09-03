'use client'
import Link from 'next/link'
import { useLang } from '@/lib/i18n'

type Props = {
  totalHotels: number
  activeHotels: number
  totalUsers: number
  activeUsers: number
  openTickets: number
  /** When true, scope copy refers to the viewer's hotel only. */
  hotelScoped?: boolean
}

export function OverviewCards(props: Props) {
  const { t } = useLang()
  const ticketSub = props.hotelScoped ? t.inYourHotel : t.acrossAllHotels

  const cards = [
    { label: t.totalHotels,  value: props.totalHotels,  sub: `${props.activeHotels} ${t.active}`, href: '/dashboard/hotels' },
    { label: t.totalUsers,   value: props.totalUsers,   sub: `${props.activeUsers} ${t.active}`, href: '/dashboard/users' },
    { label: t.openTickets,  value: props.openTickets,  sub: ticketSub, href: '/dashboard/analytics' },
  ]

  return (
    <div>
      <h1 className="text-2xl font-bold mb-8">{t.overview}</h1>
      <div className="grid grid-cols-3 gap-6">
        {cards.map(c => (
          <Link
            key={c.label}
            href={c.href}
            className="block bg-white rounded-xl p-6 shadow-sm border hover:shadow-md hover:border-blue-300 transition"
          >
            <div className="text-3xl font-bold text-blue-600">{c.value}</div>
            <div className="font-semibold text-gray-900 mt-1">{c.label}</div>
            <div className="text-sm text-gray-600">{c.sub}</div>
          </Link>
        ))}
      </div>
    </div>
  )
}
