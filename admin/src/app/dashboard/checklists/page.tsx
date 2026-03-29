'use client'
import { useEffect, useState } from 'react'

interface Template { id: string; name: string; type: string; is_vip: boolean }

export default function ChecklistsPage() {
  const [templates, setTemplates] = useState<Template[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/checklists')
      .then(r => r.json())
      .then(data => { setTemplates(data); setLoading(false) })
  }, [])

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">תבניות צ׳קליסט</h1>
      {loading ? (
        <p>טוען...</p>
      ) : (
        <div className="grid gap-4">
          {templates.map(t => (
            <div key={t.id} className="bg-white rounded-lg p-4 shadow flex items-center justify-between">
              <div>
                <p className="font-semibold">{t.name}</p>
                <p className="text-sm text-gray-500">
                  {t.type === 'housekeeping' ? 'ניקיון' : 'אחזקה'}
                  {t.is_vip && ' · VIP'}
                </p>
              </div>
              <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                t.type === 'housekeeping' ? 'bg-yellow-100 text-yellow-800' : 'bg-blue-100 text-blue-800'
              }`}>
                {t.type}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
