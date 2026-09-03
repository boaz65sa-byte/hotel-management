'use client'
import { useState } from 'react'
import { LogoPicker } from '@/components/logo-picker'
import { uploadAmenityImageAction } from '@/app/actions/upload-logo'

type Amenity = {
  id: string
  category: string
  name: string
  description: string | null
  price: number | null
  currency: string
  image_url: string | null
  is_active: boolean
  sort_order: number
}

const CATEGORY_LABELS: Record<string, string> = {
  restaurant:   '🍽️ מסעדה',
  spa:          '💆 ספא',
  room_service: '🛎️ רום סרוויס',
}

export function AmenitiesManager({
  amenities,
  createAction,
  toggleAction,
  deleteAction,
}: {
  amenities: Amenity[]
  createAction: (fd: FormData) => Promise<void>
  toggleAction: (fd: FormData) => Promise<void>
  deleteAction: (fd: FormData) => Promise<void>
}) {
  const [showForm, setShowForm] = useState(false)
  const [category, setCategory] = useState<string>('restaurant')
  const [customCategory, setCustomCategory] = useState('')
  const [imageUrl, setImageUrl] = useState<string | null>(null)

  const resetForm = () => {
    setShowForm(false)
    setCategory('restaurant')
    setCustomCategory('')
    setImageUrl(null)
  }

  return (
    <div className="space-y-6">
      <div>
        {!showForm ? (
          <button
            type="button"
            onClick={() => setShowForm(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700"
          >
            + הוסף פריט
          </button>
        ) : (
          <form
            action={async (fd) => {
              await createAction(fd)
              resetForm()
            }}
            className="bg-gray-50 border rounded-xl p-4 grid grid-cols-1 sm:grid-cols-2 gap-3"
          >
            <div>
              <label className="block text-xs font-medium mb-1">קטגוריה / שירות</label>
              <select
                value={category}
                onChange={e => setCategory(e.target.value)}
                className="w-full border rounded px-3 py-2 text-sm"
              >
                {Object.entries(CATEGORY_LABELS).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
                <option value="__custom__">➕ שירות חדש...</option>
              </select>
              {category === '__custom__' && (
                <input
                  name="category"
                  value={customCategory}
                  onChange={e => setCustomCategory(e.target.value)}
                  placeholder="שם השירות החדש (למשל: טניס, מיני בר)"
                  className="w-full border rounded px-3 py-2 text-sm mt-2"
                  required
                />
              )}
              {category !== '__custom__' && (
                <input type="hidden" name="category" value={category} />
              )}
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">שם הפריט</label>
              <input name="name" className="w-full border rounded px-3 py-2 text-sm" required />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">מחיר (₪, אופציונלי)</label>
              <input name="price" type="number" step="0.01" min="0" className="w-full border rounded px-3 py-2 text-sm" />
            </div>
            <div className="sm:col-span-2">
              <label className="block text-xs font-medium mb-1">תיאור</label>
              <input name="description" className="w-full border rounded px-3 py-2 text-sm" />
            </div>
            <div className="sm:col-span-2">
              <label className="block text-xs font-medium mb-2">תמונה (אופציונלי)</label>
              <LogoPicker
                value={imageUrl}
                onChange={setImageUrl}
                hiddenInputName="image_url"
                uploadAction={uploadAmenityImageAction}
                placeholderIcon="🖼️"
              />
            </div>
            <div className="sm:col-span-2 flex gap-2">
              <button type="submit" className="bg-gray-900 text-white px-4 py-2 rounded-lg text-sm hover:bg-gray-700">
                שמור
              </button>
              <button type="button" onClick={resetForm} className="border px-4 py-2 rounded-lg text-sm">
                ביטול
              </button>
            </div>
          </form>
        )}
      </div>

      {amenities.length === 0 ? (
        <p className="text-gray-500 text-center py-12">אין עדיין פריטים בקטלוג.</p>
      ) : (
        <div className="overflow-x-auto rounded-xl border">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-4 py-3" />
                <th className="text-right px-4 py-3 font-semibold text-gray-600">קטגוריה</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">שם</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">תיאור</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">מחיר</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">פעיל</th>
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {amenities.map(a => (
                <tr key={a.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <div className="h-10 w-10 rounded-lg border bg-gray-50 flex items-center justify-center overflow-hidden">
                      {a.image_url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img src={a.image_url} alt={a.name} className="h-full w-full object-cover" />
                      ) : (
                        <span className="text-gray-300 text-lg">🖼️</span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3">{CATEGORY_LABELS[a.category] ?? a.category}</td>
                  <td className="px-4 py-3 font-medium">{a.name}</td>
                  <td className="px-4 py-3 text-gray-500">{a.description ?? '—'}</td>
                  <td className="px-4 py-3 text-gray-700">{a.price != null ? `${a.price} ${a.currency}` : '—'}</td>
                  <td className="px-4 py-3">
                    <form action={toggleAction}>
                      <input type="hidden" name="amenity_id" value={a.id} />
                      <input type="hidden" name="next_active" value={(!a.is_active).toString()} />
                      <button
                        type="submit"
                        className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                          a.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                        }`}
                      >
                        {a.is_active ? 'פעיל' : 'כבוי'}
                      </button>
                    </form>
                  </td>
                  <td className="px-4 py-3">
                    <form
                      action={deleteAction}
                      onSubmit={(e) => { if (!confirm('למחוק פריט זה?')) e.preventDefault() }}
                    >
                      <input type="hidden" name="amenity_id" value={a.id} />
                      <button type="submit" className="text-xs text-red-600 hover:underline">
                        מחק
                      </button>
                    </form>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
