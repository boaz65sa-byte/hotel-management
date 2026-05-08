'use client'

import { useState } from 'react'

type Room = {
  id: string
  room_number: string
  floor: number | null
  room_type: string | null
  status: string
}

type ServerAction = (fd: FormData) => Promise<void>

const STATUSES = [
  { value: 'available', label: '🟢 פנוי' },
  { value: 'on_hold',   label: '🟠 בהמתנה' },
  { value: 'closed',    label: '🔴 סגור' },
]

function statusColor(s: string) {
  switch (s) {
    case 'available': return 'bg-green-100 text-green-700'
    case 'on_hold':   return 'bg-orange-100 text-orange-700'
    case 'closed':    return 'bg-red-100 text-red-700'
    default:          return 'bg-gray-100 text-gray-600'
  }
}

export function RoomsManager({
  rooms,
  createRoom,
  updateRoom,
  deleteRoom,
}: {
  rooms: Room[]
  createRoom: ServerAction
  updateRoom: ServerAction
  deleteRoom: ServerAction
}) {
  const [editingId, setEditingId] = useState<string | null>(null)

  return (
    <div className="space-y-6">
      {/* Add room form */}
      <form
        action={createRoom}
        className="bg-white border rounded-xl p-4 grid grid-cols-1 md:grid-cols-5 gap-3 items-end"
      >
        <div>
          <label className="block text-xs font-medium mb-1">מספר חדר *</label>
          <input
            name="room_number"
            required
            className="w-full border rounded px-3 py-2 text-sm"
            placeholder="101"
          />
        </div>
        <div>
          <label className="block text-xs font-medium mb-1">קומה</label>
          <input
            name="floor"
            type="number"
            className="w-full border rounded px-3 py-2 text-sm"
            placeholder="1"
          />
        </div>
        <div>
          <label className="block text-xs font-medium mb-1">סוג</label>
          <input
            name="room_type"
            className="w-full border rounded px-3 py-2 text-sm"
            placeholder="standard / deluxe / suite"
          />
        </div>
        <div>
          <label className="block text-xs font-medium mb-1">סטטוס</label>
          <select
            name="status"
            defaultValue="available"
            className="w-full border rounded px-3 py-2 text-sm"
          >
            {STATUSES.map(s => (
              <option key={s.value} value={s.value}>{s.label}</option>
            ))}
          </select>
        </div>
        <button
          type="submit"
          className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700"
        >
          + הוסף חדר
        </button>
      </form>

      {/* List */}
      {rooms.length === 0 ? (
        <p className="text-gray-500 text-center py-12">אין חדרים. הוסיפו את הראשון למעלה.</p>
      ) : (
        <div className="bg-white rounded-xl border overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">חדר</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">קומה</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">סוג</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">סטטוס</th>
                <th className="text-right px-4 py-3 font-semibold text-gray-600">פעולות</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {rooms.map(room => (
                editingId === room.id ? (
                  <tr key={room.id} className="bg-blue-50/30">
                    <td colSpan={5} className="px-4 py-3">
                      <form action={updateRoom} className="grid grid-cols-1 md:grid-cols-5 gap-3 items-end">
                        <input type="hidden" name="room_id" value={room.id} />
                        <input
                          name="room_number"
                          defaultValue={room.room_number}
                          required
                          className="border rounded px-3 py-2 text-sm"
                        />
                        <input
                          name="floor"
                          type="number"
                          defaultValue={room.floor ?? ''}
                          className="border rounded px-3 py-2 text-sm"
                        />
                        <input
                          name="room_type"
                          defaultValue={room.room_type ?? ''}
                          className="border rounded px-3 py-2 text-sm"
                        />
                        <select
                          name="status"
                          defaultValue={room.status}
                          className="border rounded px-3 py-2 text-sm"
                        >
                          {STATUSES.map(s => (
                            <option key={s.value} value={s.value}>{s.label}</option>
                          ))}
                        </select>
                        <div className="flex gap-2">
                          <button
                            type="submit"
                            onClick={() => setTimeout(() => setEditingId(null), 0)}
                            className="bg-blue-600 text-white px-3 py-2 rounded text-sm hover:bg-blue-700"
                          >
                            שמור
                          </button>
                          <button
                            type="button"
                            onClick={() => setEditingId(null)}
                            className="border px-3 py-2 rounded text-sm hover:bg-white"
                          >
                            ביטול
                          </button>
                        </div>
                      </form>
                    </td>
                  </tr>
                ) : (
                  <tr key={room.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 font-medium">{room.room_number}</td>
                    <td className="px-4 py-3">{room.floor ?? '—'}</td>
                    <td className="px-4 py-3 text-gray-600">{room.room_type ?? '—'}</td>
                    <td className="px-4 py-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${statusColor(room.status)}`}>
                        {STATUSES.find(s => s.value === room.status)?.label ?? room.status}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <button
                          type="button"
                          onClick={() => setEditingId(room.id)}
                          className="text-xs text-blue-600 hover:underline"
                        >
                          ערוך
                        </button>
                        <form
                          action={deleteRoom}
                          onSubmit={(e) => {
                            if (!confirm(`למחוק את חדר ${room.room_number}?`)) {
                              e.preventDefault()
                            }
                          }}
                        >
                          <input type="hidden" name="room_id" value={room.id} />
                          <button type="submit" className="text-xs text-red-600 hover:underline">
                            מחק
                          </button>
                        </form>
                      </div>
                    </td>
                  </tr>
                )
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
