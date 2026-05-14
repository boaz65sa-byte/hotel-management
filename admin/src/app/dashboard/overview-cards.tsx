'use client'
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
    { label: t.totalHotels,  value: props.totalHotels,  sub: `${props.activeHotels} ${t.active}` },
    { label: t.totalUsers,   value: props.totalUsers,   sub: `${props.activeUsers} ${t.active}` },
    { label: t.openTickets,  value: props.openTickets,  sub: ticketSub },
  ]

  return (
    <div>
      <h1 className="text-2xl font-bold mb-8">{t.overview}</h1>
      <div className="grid grid-cols-3 gap-6">
        {cards.map(c => (
          <div key={c.label} className="bg-white rounded-xl p-6 shadow-sm border">
            <div className="text-3xl font-bold text-blue-600">{c.value}</div>
            <div className="font-semibold text-gray-900 mt-1">{c.label}</div>
            <div className="text-sm text-gray-600">{c.sub}</div>
          </div>
        ))}
      </div>
    </div>
  )
}
