'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { ROLES } from '@/lib/roles'
import { LogoPicker } from '@/components/logo-picker'
import { setupHotelAction, type WizardInput, type WizardResult } from './actions'

// ─── helpers ────────────────────────────────────────────────────────────────

function generateRoomNumbers(
  floors: number,
  rooms_per_floor: number,
  start_per_floor: number,
  skip_numbers: number[],
): string[] {
  const skipSet = new Set(skip_numbers)
  const result: string[] = []
  for (let f = 1; f <= floors; f++) {
    for (let r = 0; r < rooms_per_floor; r++) {
      const roomIndex = start_per_floor + r
      if (skipSet.has(roomIndex)) continue
      const pad = String(roomIndex).padStart(2, '0')
      result.push(`${f}${pad}`)
    }
  }
  return result
}

// ─── progress bar ────────────────────────────────────────────────────────────

const STEPS = [
  { num: 1, label: 'פרטי מלון' },
  { num: 2, label: 'חדרים' },
  { num: 3, label: 'משתמשים' },
]

function StepBar({ current }: { current: 1 | 2 | 3 }) {
  return (
    <div className="flex items-center gap-0 mb-8" dir="rtl">
      {STEPS.map((s, idx) => {
        const done   = s.num < current
        const active = s.num === current
        return (
          <div key={s.num} className="flex items-center flex-1 last:flex-none">
            <div className="flex flex-col items-center gap-1">
              <div
                className={`w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold border-2 transition-all ${
                  done    ? 'bg-green-500 border-green-500 text-white'
                  : active ? 'bg-yellow-400 border-yellow-500 text-gray-900'
                  : 'bg-white border-gray-300 text-gray-400'
                }`}
              >
                {done ? '✓' : s.num}
              </div>
              <span className={`text-xs font-medium whitespace-nowrap ${
                active ? 'text-yellow-600' : done ? 'text-green-600' : 'text-gray-400'
              }`}>
                {s.label}
              </span>
            </div>
            {idx < STEPS.length - 1 && (
              <div className={`flex-1 h-0.5 mx-2 mb-5 ${done ? 'bg-green-400' : 'bg-gray-200'}`} />
            )}
          </div>
        )
      })}
    </div>
  )
}

// ─── step 1: hotel details ────────────────────────────────────────────────────

function Step1({
  hotel,
  setHotel,
  onNext,
  onCancel,
}: {
  hotel: WizardInput['hotel']
  setHotel: (h: WizardInput['hotel']) => void
  onNext: () => void
  onCancel: () => void
}) {
  const set = <K extends keyof WizardInput['hotel']>(k: K, v: WizardInput['hotel'][K]) =>
    setHotel({ ...hotel, [k]: v })

  return (
    <div className="space-y-6" dir="rtl">
      <div className="bg-white rounded-xl border p-6 space-y-5">
        <h2 className="text-lg font-semibold text-gray-800">פרטי המלון</h2>

        <div>
          <label className="block text-sm font-medium mb-1">שם המלון *</label>
          <input
            value={hotel.name}
            onChange={e => set('name', e.target.value)}
            className="w-full border rounded px-3 py-2"
            placeholder="לדוג׳: מלון ים המלח"
            autoFocus
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">כתובת</label>
            <input
              value={hotel.address ?? ''}
              onChange={e => set('address', e.target.value)}
              className="w-full border rounded px-3 py-2"
              placeholder="רחוב הים 1"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">עיר</label>
            <input
              value={hotel.city ?? ''}
              onChange={e => set('city', e.target.value)}
              className="w-full border rounded px-3 py-2"
              placeholder="תל אביב"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">מדינה</label>
            <input
              value={hotel.country ?? ''}
              onChange={e => set('country', e.target.value)}
              className="w-full border rounded px-3 py-2"
              placeholder="ישראל"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">טלפון</label>
            <input
              value={hotel.phone ?? ''}
              onChange={e => set('phone', e.target.value)}
              className="w-full border rounded px-3 py-2"
              placeholder="03-0000000"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">אימייל</label>
            <input
              type="email"
              value={hotel.email ?? ''}
              onChange={e => set('email', e.target.value)}
              className="w-full border rounded px-3 py-2"
              placeholder="info@hotel.co.il"
            />
          </div>
        </div>

        <hr />

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">מסלול</label>
            <select
              value={hotel.subscription_plan}
              onChange={e => set('subscription_plan', e.target.value)}
              className="w-full border rounded px-3 py-2"
            >
              <option value="basic">Basic (10GB)</option>
              <option value="pro">Pro (50GB)</option>
              <option value="enterprise">Enterprise (200GB)</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">SLA (שעות)</label>
            <input
              type="number"
              min={1}
              value={hotel.default_sla_hours}
              onChange={e => set('default_sla_hours', +e.target.value)}
              className="w-full border rounded px-3 py-2"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">שפת ברירת מחדל</label>
            <select
              value={hotel.default_language}
              onChange={e => set('default_language', e.target.value)}
              className="w-full border rounded px-3 py-2"
            >
              <option value="he">עברית</option>
              <option value="en">English</option>
              <option value="ar">العربية</option>
              <option value="ru">Русский</option>
            </select>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">ערכת עיצוב</label>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => set('theme', 'clean_blue')}
              className={`px-3 py-1 rounded-md text-xs font-medium border transition-all ${
                !hotel.theme || hotel.theme === 'clean_blue'
                  ? 'border-blue-600 bg-blue-50 text-blue-700'
                  : 'border-gray-200 text-gray-500 hover:border-blue-300'
              }`}
            >
              ☀️ Clean Blue
            </button>
            <button
              type="button"
              onClick={() => set('theme', 'luxury')}
              className={`px-3 py-1 rounded-md text-xs font-medium border transition-all ${
                hotel.theme === 'luxury'
                  ? 'border-yellow-500 bg-yellow-50 text-yellow-700'
                  : 'border-gray-200 text-gray-500 hover:border-yellow-300'
              }`}
            >
              🌙 Luxury
            </button>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium mb-2">לוגו המלון</label>
          <LogoPicker
            value={hotel.logo_url ?? null}
            onChange={(url) => set('logo_url', url ?? '')}
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Guest PWA URL</label>
          <input
            type="url"
            value={hotel.guest_pwa_url ?? ''}
            onChange={e => set('guest_pwa_url', e.target.value)}
            className="w-full border rounded px-3 py-2"
            placeholder="https://your-pwa.netlify.app"
          />
          <p className="text-xs text-gray-500 mt-1">ה-URL הבסיסי של אפליקציית האורחים לקודי QR. ריק = ברירת מחדל.</p>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">ימי שהייה לפני משוב</label>
          <input
            type="number"
            min={1}
            max={30}
            value={hotel.stay_threshold}
            onChange={e => set('stay_threshold', +e.target.value)}
            className="w-full border rounded px-3 py-2 max-w-xs"
          />
          <p className="text-xs text-gray-500 mt-1">מספר ימים מכניסת האורח עד שמוצג banner המשוב ב-PWA (ברירת מחדל: 3)</p>
        </div>

        <div className="flex items-center gap-3">
          <input
            type="checkbox"
            id="is_active"
            checked={hotel.is_active}
            onChange={e => set('is_active', e.target.checked)}
            className="w-4 h-4"
          />
          <label htmlFor="is_active" className="text-sm font-medium">מלון פעיל</label>
        </div>
      </div>

      <div className="flex justify-between">
        <button
          type="button"
          onClick={onCancel}
          className="border px-6 py-2 rounded-lg hover:bg-gray-50 text-sm"
        >
          ביטול
        </button>
        <button
          type="button"
          onClick={onNext}
          disabled={!hotel.name.trim()}
          className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 disabled:opacity-40 disabled:cursor-not-allowed text-sm flex items-center gap-2"
        >
          הבא ←
        </button>
      </div>
    </div>
  )
}

// ─── step 2: rooms ────────────────────────────────────────────────────────────

type RoomsState = { floors: number; rooms_per_floor: number; start_per_floor: number; skip_numbers: string }

function Step2({
  createRooms,
  setCreateRooms,
  rooms,
  setRooms,
  onNext,
  onBack,
}: {
  createRooms: boolean
  setCreateRooms: (v: boolean) => void
  rooms: RoomsState
  setRooms: (r: RoomsState) => void
  onNext: () => void
  onBack: () => void
}) {
  const set = <K extends keyof RoomsState>(k: K, v: RoomsState[K]) => setRooms({ ...rooms, [k]: v })

  const skipNumbers = rooms.skip_numbers
    .split(',')
    .map(s => parseInt(s.trim()))
    .filter(n => !isNaN(n))

  const preview = generateRoomNumbers(rooms.floors, rooms.rooms_per_floor, rooms.start_per_floor, skipNumbers)
  const showCount = Math.min(preview.length, 30)

  return (
    <div className="space-y-6" dir="rtl">
      <div className="bg-white rounded-xl border p-6 space-y-5">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-800">הגדרת חדרים</h2>
          <label className="flex items-center gap-2 cursor-pointer select-none">
            <span className="text-sm font-medium">צור חדרים אוטומטית</span>
            <button
              type="button"
              role="switch"
              aria-checked={createRooms}
              onClick={() => setCreateRooms(!createRooms)}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                createRooms ? 'bg-blue-600' : 'bg-gray-300'
              }`}
            >
              <span
                className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${
                  createRooms ? 'translate-x-6' : 'translate-x-1'
                }`}
              />
            </button>
          </label>
        </div>

        {!createRooms && (
          <div className="rounded-lg bg-gray-50 border border-dashed p-4 text-sm text-gray-500 text-center">
            ניתן להוסיף חדרים בנפרד מדף ניהול המלון לאחר היצירה.
          </div>
        )}

        {createRooms && (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1">מספר קומות</label>
                <input
                  type="number"
                  min={1}
                  max={100}
                  value={rooms.floors}
                  onChange={e => set('floors', Math.max(1, +e.target.value))}
                  className="w-full border rounded px-3 py-2"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">מספר חדרים בקומה</label>
                <input
                  type="number"
                  min={1}
                  max={200}
                  value={rooms.rooms_per_floor}
                  onChange={e => set('rooms_per_floor', Math.max(1, +e.target.value))}
                  className="w-full border rounded px-3 py-2"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">חדר ראשון בקומה</label>
                <input
                  type="number"
                  min={1}
                  value={rooms.start_per_floor}
                  onChange={e => set('start_per_floor', Math.max(1, +e.target.value))}
                  className="w-full border rounded px-3 py-2"
                />
                <p className="text-xs text-gray-500 mt-1">לדוג׳ 1 → קומה 1: 101, 102... | קומה 2: 201, 202...</p>
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">חדרים לדלג (מופרד בפסיק)</label>
                <input
                  type="text"
                  value={rooms.skip_numbers}
                  onChange={e => set('skip_numbers', e.target.value)}
                  className="w-full border rounded px-3 py-2"
                  placeholder="13"
                />
                <p className="text-xs text-gray-500 mt-1">לדוג׳ 13 → ידלג על 113, 213, 313</p>
              </div>
            </div>

            {preview.length > 0 && (
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-gray-700">תצוגה מקדימה</span>
                  <span className="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">
                    סה״כ: {preview.length} חדרים
                  </span>
                </div>
                <div className="flex flex-wrap gap-1.5 max-h-36 overflow-y-auto p-3 bg-gray-50 rounded-lg border">
                  {preview.slice(0, showCount).map(n => (
                    <span key={n} className="bg-white border border-blue-200 text-blue-700 text-xs px-2 py-0.5 rounded-full font-mono">
                      {n}
                    </span>
                  ))}
                  {preview.length > showCount && (
                    <span className="text-xs text-gray-400 px-2 py-0.5">
                      +{preview.length - showCount} נוספים...
                    </span>
                  )}
                </div>
              </div>
            )}
          </>
        )}
      </div>

      <div className="flex justify-between">
        <button type="button" onClick={onBack} className="border px-6 py-2 rounded-lg hover:bg-gray-50 text-sm">
          → חזרה
        </button>
        <button type="button" onClick={onNext} className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 text-sm">
          הבא ←
        </button>
      </div>
    </div>
  )
}

// ─── step 3: users ────────────────────────────────────────────────────────────

function Step3({
  users,
  setUsers,
  onBack,
  onSubmit,
  submitting,
}: {
  users: WizardInput['users']
  setUsers: (u: WizardInput['users']) => void
  onBack: () => void
  onSubmit: () => void
  submitting: boolean
}) {
  const addUser = (role: string) =>
    setUsers([...users, { full_name: '', email: '', role }])

  const removeUser = (i: number) =>
    setUsers(users.filter((_, idx) => idx !== i))

  const updateUser = (i: number, field: keyof WizardInput['users'][number], value: string) => {
    const next = [...users]
    next[i] = { ...next[i], [field]: value }
    setUsers(next)
  }

  return (
    <div className="space-y-6" dir="rtl">
      <div className="bg-gradient-to-br from-amber-50 to-yellow-50 border-2 border-amber-200 rounded-xl p-5">
        <div className="flex items-start gap-3">
          <span className="text-2xl">⭐</span>
          <div className="flex-1">
            <h3 className="font-bold text-gray-900 mb-1">2 התפקידים החיוניים לכל מלון</h3>
            <p className="text-sm text-gray-700 mb-3">
              לפני הכל — הוסיפו את <strong>{'מנכ\u05f4ל המלון'}</strong> ואת <strong>מנהל התוכנה</strong>.
              הם יקבלו גישה מלאה לניהול המלון: הוספת עובדים, צפייה בכל הנתונים, ושינוי הגדרות —
              <strong> אך ורק למלון הזה</strong>.
            </p>
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => addUser('ceo')}
                className="bg-amber-500 text-white text-sm px-4 py-2 rounded-lg hover:bg-amber-600 font-medium"
              >
                👔 + הוסף {'מנכ\u05f4ל מלון'}
              </button>
              <button
                type="button"
                onClick={() => addUser('software_manager')}
                className="bg-amber-500 text-white text-sm px-4 py-2 rounded-lg hover:bg-amber-600 font-medium"
              >
                🛠️ + הוסף מנהל תוכנה
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border p-6 space-y-5">
        <h2 className="text-lg font-semibold text-gray-800">משתמשים נוספים (אופציונלי)</h2>
        <p className="text-sm text-gray-500">
          כל משתמש יקבל הזמנה במייל עם קישור להגדרת סיסמה. ניתן לדלג ולהוסיף משתמשים לאחר יצירת המלון.
        </p>

        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => addUser('reception_manager')}
            className="bg-blue-50 border border-blue-200 text-blue-700 text-sm px-4 py-2 rounded-lg hover:bg-blue-100 font-medium"
          >
            📞 + מנהל קבלה
          </button>
          <button
            type="button"
            onClick={() => addUser('maintenance_manager')}
            className="bg-blue-50 border border-blue-200 text-blue-700 text-sm px-4 py-2 rounded-lg hover:bg-blue-100 font-medium"
          >
            🔧 + מנהל אחזקה
          </button>
          <button
            type="button"
            onClick={() => addUser('housekeeping_manager')}
            className="bg-blue-50 border border-blue-200 text-blue-700 text-sm px-4 py-2 rounded-lg hover:bg-blue-100 font-medium"
          >
            🧹 + מנהל משק
          </button>
          <button
            type="button"
            onClick={() => addUser('receptionist')}
            className="bg-green-50 border border-green-200 text-green-700 text-sm px-4 py-2 rounded-lg hover:bg-green-100 font-medium"
          >
            🧑‍💼 + עובד קבלה
          </button>
          <button
            type="button"
            onClick={() => addUser('maintenance_tech')}
            className="bg-green-50 border border-green-200 text-green-700 text-sm px-4 py-2 rounded-lg hover:bg-green-100 font-medium"
          >
            🔩 + טכנאי
          </button>
        </div>

        {users.length > 0 && (
          <div className="space-y-3">
            {users.map((u, i) => (
              <div key={i} className="grid grid-cols-1 sm:grid-cols-[1fr_1fr_auto_auto] gap-2 items-start p-3 bg-gray-50 rounded-lg border">
                <div>
                  <label className="block text-xs text-gray-500 mb-1">שם מלא</label>
                  <input
                    value={u.full_name}
                    onChange={e => updateUser(i, 'full_name', e.target.value)}
                    className="w-full border rounded px-2 py-1.5 text-sm bg-white"
                    placeholder="ישראל ישראלי"
                  />
                </div>
                <div>
                  <label className="block text-xs text-gray-500 mb-1">אימייל</label>
                  <input
                    type="email"
                    value={u.email}
                    onChange={e => updateUser(i, 'email', e.target.value)}
                    className="w-full border rounded px-2 py-1.5 text-sm bg-white"
                    placeholder="user@hotel.co.il"
                  />
                </div>
                <div>
                  <label className="block text-xs text-gray-500 mb-1">תפקיד</label>
                  <select
                    value={u.role}
                    onChange={e => updateUser(i, 'role', e.target.value)}
                    className="border rounded px-2 py-1.5 text-sm bg-white"
                  >
                    <optgroup label="🟦 ניהול המלון">
                      {ROLES.filter(r => r.tier === 'hotel_admin').map(r => (
                        <option key={r.value} value={r.value}>{r.icon} {r.label}</option>
                      ))}
                    </optgroup>
                    <optgroup label="🟢 מנהלי מחלקות">
                      {ROLES.filter(r => r.tier === 'dept_manager').map(r => (
                        <option key={r.value} value={r.value}>{r.icon} {r.label}</option>
                      ))}
                    </optgroup>
                    <optgroup label="⚪ צוות">
                      {ROLES.filter(r => r.tier === 'staff').map(r => (
                        <option key={r.value} value={r.value}>{r.icon} {r.label}</option>
                      ))}
                    </optgroup>
                  </select>
                </div>
                <div className="pt-5">
                  <button
                    type="button"
                    onClick={() => removeUser(i)}
                    className="text-red-500 hover:text-red-700 text-lg px-1"
                    title="הסר משתמש"
                  >
                    🗑️
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {users.length === 0 && (
          <div className="text-center text-gray-400 text-sm py-6 border border-dashed rounded-lg">
            לא נוספו משתמשים — ניתן להוסיף לאחר יצירת המלון
          </div>
        )}
      </div>

      <div className="flex justify-between">
        <button type="button" onClick={onBack} className="border px-6 py-2 rounded-lg hover:bg-gray-50 text-sm">
          → חזרה
        </button>
        <button
          type="button"
          onClick={onSubmit}
          disabled={submitting}
          className="bg-blue-600 text-white px-8 py-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 text-sm font-semibold flex items-center gap-2"
        >
          {submitting ? (
            <>
              <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
              </svg>
              יוצר מלון...
            </>
          ) : '✓ צור מלון'}
        </button>
      </div>
    </div>
  )
}

// ─── result view ──────────────────────────────────────────────────────────────

function ResultView({
  result,
  users,
  createRooms,
  onGoToHotel,
  onStay,
}: {
  result: WizardResult
  users: WizardInput['users']
  createRooms: boolean
  onGoToHotel: () => void
  onStay: () => void
}) {
  const userErrors = result.errors?.filter(e => e.step === 'users') ?? []
  const roomError  = result.errors?.find(e => e.step === 'rooms')
  const hasIssues  = (result.errors?.length ?? 0) > 0

  return (
    <div className="space-y-6" dir="rtl">
      <div className={`bg-white rounded-xl border p-6 space-y-4 ${hasIssues ? 'border-yellow-300' : 'border-green-300'}`}>
        <div className="flex items-center gap-3">
          <span className="text-3xl">{hasIssues ? '⚠️' : '🎉'}</span>
          <div>
            <h2 className="text-lg font-bold text-gray-800">
              {hasIssues ? 'המלון נוצר עם כמה בעיות' : 'המלון נוצר בהצלחה!'}
            </h2>
            <p className="text-sm text-gray-500">מועבר לדף המלון בעוד שניות...</p>
          </div>
        </div>

        <div className="space-y-2 text-sm">
          <div className="flex items-center gap-2">
            <span className="text-green-500 text-base">✅</span>
            <span>המלון נוצר</span>
          </div>

          {createRooms && (
            <div className="flex items-center gap-2">
              {roomError ? (
                <>
                  <span className="text-red-500 text-base">❌</span>
                  <span className="text-red-700">שגיאה ביצירת חדרים: {roomError.message}</span>
                </>
              ) : (
                <>
                  <span className="text-green-500 text-base">✅</span>
                  <span>{result.roomsCreated} חדרים נוצרו</span>
                </>
              )}
            </div>
          )}

          {users.map((u, i) => {
            const err = userErrors.find(e => e.userIndex === i)
            return (
              <div key={i} className="flex items-center gap-2">
                {err ? (
                  <>
                    <span className="text-red-500 text-base">❌</span>
                    <span className="text-red-700">{u.email}: {err.message}</span>
                  </>
                ) : (
                  <>
                    <span className="text-green-500 text-base">✅</span>
                    <span>{u.full_name || u.email} — הוזמן בהצלחה</span>
                  </>
                )}
              </div>
            )
          })}
        </div>
      </div>

      <div className="flex gap-3 justify-center">
        <button
          type="button"
          onClick={onGoToHotel}
          className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 text-sm font-semibold"
        >
          ראה מלון
        </button>
        <button
          type="button"
          onClick={onStay}
          className="border px-6 py-2 rounded-lg hover:bg-gray-50 text-sm"
        >
          הישאר
        </button>
      </div>
    </div>
  )
}

// ─── main wizard ──────────────────────────────────────────────────────────────

export function Wizard() {
  const router = useRouter()
  const [step, setStep] = useState<1 | 2 | 3>(1)
  const [submitting, setSubmitting] = useState(false)
  const [result, setResult] = useState<WizardResult | null>(null)
  const [redirectTimer, setRedirectTimer] = useState<ReturnType<typeof setTimeout> | null>(null)

  const [hotel, setHotel] = useState<WizardInput['hotel']>({
    name: '',
    subscription_plan: 'basic',
    default_sla_hours: 4,
    default_language: 'he',
    theme: 'clean_blue',
    is_active: true,
    stay_threshold: 3,
  })

  const [createRooms, setCreateRooms] = useState(true)
  const [rooms, setRooms] = useState<RoomsState>({
    floors: 3,
    rooms_per_floor: 10,
    start_per_floor: 1,
    skip_numbers: '',
  })
  const [users, setUsers] = useState<WizardInput['users']>([])

  async function handleSubmit() {
    setSubmitting(true)
    setResult(null)

    const skipNumbers = rooms.skip_numbers
      .split(',')
      .map(s => parseInt(s.trim()))
      .filter(n => !isNaN(n))

    const res = await setupHotelAction({
      hotel,
      rooms: createRooms ? { ...rooms, skip_numbers: skipNumbers } : null,
      users,
    })

    setResult(res)
    setSubmitting(false)

    if (res.ok) {
      const t = setTimeout(() => router.push(`/dashboard/hotels/${res.hotelId}`), 2000)
      setRedirectTimer(t)
    }
  }

  function handleGoToHotel() {
    if (redirectTimer) clearTimeout(redirectTimer)
    router.push(`/dashboard/hotels/${result?.hotelId}`)
  }

  function handleStay() {
    if (redirectTimer) clearTimeout(redirectTimer)
    setRedirectTimer(null)
  }

  if (result) {
    return (
      <>
        <StepBar current={3} />
        <ResultView
          result={result}
          users={users}
          createRooms={createRooms}
          onGoToHotel={handleGoToHotel}
          onStay={handleStay}
        />
      </>
    )
  }

  return (
    <>
      <StepBar current={step} />

      {step === 1 && (
        <Step1
          hotel={hotel}
          setHotel={setHotel}
          onNext={() => setStep(2)}
          onCancel={() => router.back()}
        />
      )}
      {step === 2 && (
        <Step2
          createRooms={createRooms}
          setCreateRooms={setCreateRooms}
          rooms={rooms}
          setRooms={setRooms}
          onNext={() => setStep(3)}
          onBack={() => setStep(1)}
        />
      )}
      {step === 3 && (
        <Step3
          users={users}
          setUsers={setUsers}
          onBack={() => setStep(2)}
          onSubmit={handleSubmit}
          submitting={submitting}
        />
      )}
    </>
  )
}
