'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { ThemePicker } from './theme-picker'

type Hotel = { id?: string; name: string; subscription_plan: string
               default_sla_hours: number; default_language: string
               is_active: boolean; theme_colors: { primary: string; secondary: string; accent: string } }

export function HotelForm({ hotel, action }: { hotel: Hotel; action: (fd: FormData) => Promise<void> }) {
  const [data, setData] = useState(hotel)
  const router = useRouter()

  return (
    <form action={action} className="space-y-6 bg-white rounded-xl p-6 border max-w-2xl">
      <input type="hidden" name="id" value={data.id ?? ''} />
      <input type="hidden" name="theme_colors" value={JSON.stringify(data.theme_colors)} />

      <div>
        <label className="block text-sm font-medium mb-1">Hotel Name *</label>
        <input name="name" value={data.name} onChange={e => setData({...data, name: e.target.value})}
          className="w-full border rounded px-3 py-2" required />
      </div>

      <div className="grid grid-cols-3 gap-4">
        <div>
          <label className="block text-sm font-medium mb-1">Plan</label>
          <select name="subscription_plan" value={data.subscription_plan}
            onChange={e => setData({...data, subscription_plan: e.target.value})}
            className="w-full border rounded px-3 py-2">
            <option value="basic">Basic (10GB)</option>
            <option value="pro">Pro (50GB)</option>
            <option value="enterprise">Enterprise (200GB)</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">SLA (hours)</label>
          <input type="number" name="default_sla_hours" value={data.default_sla_hours}
            onChange={e => setData({...data, default_sla_hours: +e.target.value})}
            className="w-full border rounded px-3 py-2" min={1} />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Default Language</label>
          <select name="default_language" value={data.default_language}
            onChange={e => setData({...data, default_language: e.target.value})}
            className="w-full border rounded px-3 py-2">
            <option value="he">Hebrew</option>
            <option value="en">English</option>
            <option value="ar">Arabic</option>
          </select>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium mb-2">Theme Colors</label>
        <ThemePicker value={data.theme_colors}
          onChange={colors => setData({...data, theme_colors: colors})} />
      </div>

      <div className="flex items-center gap-3">
        <input type="checkbox" name="is_active" id="is_active"
          checked={data.is_active} onChange={e => setData({...data, is_active: e.target.checked})} />
        <label htmlFor="is_active" className="text-sm font-medium">Active</label>
      </div>

      <div className="flex gap-3">
        <button type="submit"
          className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700">
          Save Hotel
        </button>
        <button type="button" onClick={() => router.back()}
          className="border px-6 py-2 rounded-lg hover:bg-gray-50">
          Cancel
        </button>
      </div>
    </form>
  )
}
