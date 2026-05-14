'use client'

import { useState, useMemo } from 'react'

type Room = {
  id: string
  room_number: string
  floor: number | null
  room_type: string | null
  status: string
}

type ServerAction = (fd: FormData) => Promise<void>
type BulkAction = (fd: FormData) => Promise<{
  ok: boolean
  created: number
  skipped: number
  error?: string
}>

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
  hotelId,
  rooms,
  createRoom,
  updateRoom,
  deleteRoom,
  bulkAddRooms,
}: {
  hotelId: string
  rooms: Room[]
  createRoom: ServerAction
  updateRoom: ServerAction
  deleteRoom: ServerAction
  bulkAddRooms: BulkAction
}) {
  const [editingId, setEditingId] = useState<string | null>(null)
  const [showBulk, setShowBulk] = useState(false)
  const [floors, setFloors] = useState(3)
  const [perFloor, setPerFloor] = useState(20)
  const [startPer, setStartPer] = useState(1)
  const [skipRaw, setSkipRaw] = useState('13')
  const [roomTypeBulk, setRoomTypeBulk] = useState('standard')
  const [bulkBusy, setBulkBusy] = useState(false)
  const [bulkMsg, setBulkMsg] = useState<string | null>(null)

  const existingNumbers = useMemo(
    () => new Set(rooms.map(r => r.room_number)),
    [rooms],
  )

  const preview = useMemo(() => {
    const skipSet = new Set(
      skipRaw.split(/[\s,]+/).map(s => Number(s)).filter(Number.isFinite),
    )
    const list: string[] = []
    for (let f = 1; f <= floors; f++) {
      for (let r = 0; r < perFloor; r++) {
        const idx = startPer + r
        if (skipSet.has(idx)) continue
        list.push(`${f}${String(idx).padStart(2, '0')}`)
      }
    }
    return list
  }, [floors, perFloor, startPer, skipRaw])

  const previewNew = preview.filter(n => !existingNumbers.has(n))
  const previewDup = preview.filter(n =>  existingNumbers.has(n))

  async function handleBulk(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setBulkBusy(true)
    setBulkMsg(null)
    try {
      const fd = new FormData(e.currentTarget)
      const res = await bulkAddRooms(fd)
      if (res.ok) {
        setBulkMsg(
          `✓ נוספו ${res.created} חדרים${res.skipped ? ` · דולגו ${res.skipped} שכבר קיימים` : ''}`,
        )
      } else {
        setBulkMsg(`⚠️ ${res.error ?? 'שגיאה לא ידועה'}`)
      }
    } finally {
      setBulkBusy(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Bulk add toggle + panel */}
      <div className="bg-gradient-to-br from-blue-50 to-indigo-50 border-2 border-blue-200 rounded-xl p-4">
        <div className="flex items-start justify-between gap-3">
          <div>
            <h3 className="font-bold text-blue-900">🏗️ הוספת חדרים מרובים</h3>
            <p className="text-xs text-blue-700 mt-1">
              מייצר אוטומטית מספרי חדרים לפי קומות (101, 102 ... 201, 202 ...). יעיל למלון שלם.
            </p>
          </div>
          <button
            type="button"
            onClick={() => setShowBulk(v => !v)}
            className="bg-blue-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-blue-700 whitespace-nowrap"
          >
            {showBulk ? '✕ סגור' : '+ פתח'}
          </button>
        </div>

        {showBulk && (
          <form onSubmit={handleBulk} className="mt-4 space-y-4">
            <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
              <div>
                <label className="block text-xs font-medium mb-1">קומות</label>
                <input
                  name="floors" type="number" min={1} max={50}
                  value={floors}
                  onChange={e => setFloors(Math.max(1, Number(e.target.value)))}
                  className="w-full border rounded px-3 py-2 text-sm bg-white"
                />
              </div>
              <div>
                <label className="block text-xs font-medium mb-1">חדרים בקומה</label>
                <input
                  name="rooms_per_floor" type="number" min={1} max={100}
                  value={perFloor}
                  onChange={e => setPerFloor(Math.max(1, Number(e.target.value)))}
                  className="w-full border rounded px-3 py-2 text-sm bg-white"
                />
              </div>
              <div>
                <label className="block text-xs font-medium mb-1">מספור מתחיל ב</label>
                <input
                  name="start_per_floor" type="number" min={1} max={99}
                  value={startPer}
                  onChange={e => setStartPer(Math.max(1, Number(e.target.value)))}
                  className="w-full border rounded px-3 py-2 text-sm bg-white"
                />
              </div>
              <div>
                <label className="block text-xs font-medium mb-1">לדלג על</label>
                <input
                  name="skip_numbers" type="text"
                  value={skipRaw}
                  onChange={e => setSkipRaw(e.target.value)}
                  placeholder="13, 14"
                  className="w-full border rounded px-3 py-2 text-sm bg-white"
                />
              </div>
              <div>
                <label className="block text-xs font-medium mb-1">סוג ברירת מחדל</label>
                <input
                  name="room_type" type="text"
                  value={roomTypeBulk}
                  onChange={e => setRoomTypeBulk(e.target.value)}
                  className="w-full border rounded px-3 py-2 text-sm bg-white"
                />
              </div>
            </div>

            <div className="bg-white rounded-lg border p-3">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-semibold text-gray-600">
                  תצוגה מקדימה
                </span>
                <div className="flex gap-2 text-xs">
                  <span className="px-2 py-0.5 rounded-full bg-green-100 text-green-700">
                    + {previewNew.length} חדשים
                  </span>
                  {previewDup.length > 0 && (
                    <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-700">
                      ⊝ {previewDup.length} קיימים (ידולגו)
                    </span>
                  )}
                </div>
              </div>
              <div className="flex flex-wrap gap-1 max-h-32 overflow-y-auto text-xs font-mono">
                {preview.slice(0, 200).map(n => (
                  <span
                    key={n}
                    className={`px-1.5 py-0.5 rounded ${
                      existingNumbers.has(n)
                        ? 'bg-amber-50 text-amber-700 line-through'
                        : 'bg-green-50 text-green-700'
                    }`}
                  >
                    {n}
                  </span>
                ))}
                {preview.length > 200 && (
                  <span className="text-gray-400">… ועוד {preview.length - 200}</span>
                )}
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <button
                type="submit"
                disabled={bulkBusy || previewNew.length === 0}
                className="bg-blue-600 text-white px-5 py-2 rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50"
              >
                {bulkBusy ? 'מוסיף...' : `הוסף ${previewNew.length} חדרים`}
              </button>
              {bulkMsg && (
                <span className={`text-sm ${bulkMsg.startsWith('✓') ? 'text-green-700' : 'text-red-700'}`}>
                  {bulkMsg}
                </span>
              )}
              <a
                href={`/dashboard/hotels/${hotelId}/qr-codes`}
                className="text-sm text-blue-600 hover:underline mr-auto"
              >
                ← אחרי ההוספה: לעמוד ה-QR
              </a>
            </div>
          </form>
        )}
      </div>

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
