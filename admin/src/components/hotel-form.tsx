'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { LogoPicker } from '@/components/logo-picker'

type Hotel = { id?: string; name: string; subscription_plan: string
               default_sla_hours: number; default_language: string
               is_active: boolean; theme?: string | null
               stay_threshold?: number
               guest_pwa_url?: string | null
               logo_url?: string | null }

export function HotelForm({ hotel, action }: { hotel: Hotel; action: (fd: FormData) => Promise<void> }) {
  const [data, setData] = useState(hotel)
  const router = useRouter()

  return (
    <form action={action} className="space-y-6 bg-white rounded-xl p-6 border max-w-2xl">
      <input type="hidden" name="id" value={data.id ?? ''} />

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
            <option value="ru">Russian</option>
          </select>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium mb-2">לוגו המלון</label>
        <LogoPicker
          value={data.logo_url ?? null}
          onChange={(url) => setData({ ...data, logo_url: url })}
        />
      </div>

      <div>
        <label className="block text-sm font-medium mb-2">ערכת עיצוב</label>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => setData({...data, theme: 'clean_blue'})}
            className={`px-3 py-1 rounded-md text-xs font-medium border transition-all ${
              !data.theme || data.theme === 'clean_blue'
                ? 'border-blue-600 bg-blue-50 text-blue-700'
                : 'border-gray-200 text-gray-500 hover:border-blue-300'
            }`}
          >
            ☀️ Clean Blue
          </button>
          <button
            type="button"
            onClick={() => setData({...data, theme: 'luxury'})}
            className={`px-3 py-1 rounded-md text-xs font-medium border transition-all ${
              data.theme === 'luxury'
                ? 'border-yellow-500 bg-yellow-50 text-yellow-700'
                : 'border-gray-200 text-gray-500 hover:border-yellow-300'
            }`}
          >
            🌙 Luxury
          </button>
        </div>
        <input type="hidden" name="theme" value={data.theme ?? 'clean_blue'} />
      </div>

      <div>
        <label className="block text-sm font-medium mb-1">ימי שהייה לפני משוב (stay_threshold)</label>
        <input
          type="number"
          name="stay_threshold"
          value={data.stay_threshold ?? 3}
          onChange={e => setData({...data, stay_threshold: +e.target.value})}
          className="w-full border rounded px-3 py-2"
          min={1}
          max={30}
        />
        <p className="text-xs text-gray-500 mt-1">
          מספר ימים מכניסת האורח עד שמוצג banner המשוב ב-PWA (ברירת מחדל: 3)
        </p>
      </div>

      <div>
        <label className="block text-sm font-medium mb-1">Guest PWA URL</label>
        <input
          type="url"
          name="guest_pwa_url"
          value={data.guest_pwa_url ?? ''}
          onChange={e => setData({...data, guest_pwa_url: e.target.value})}
          className="w-full border rounded px-3 py-2"
          placeholder="https://exquisite-cocada-7966bd.netlify.app"
        />
        <p className="text-xs text-gray-500 mt-1">
          ה-URL הבסיסי של אפליקציית האורחים לקודי ה-QR. ריק = ברירת מחדל.
        </p>
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
