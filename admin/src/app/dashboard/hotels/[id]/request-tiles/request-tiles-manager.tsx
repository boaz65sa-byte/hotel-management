'use client'

// Mirrors the tile catalog in hotel_guest_app/lib/presentation/new_request_screen.dart
// (_serviceTilesByCategory). Icon + key must stay in sync with that file —
// labels here are for the admin UI only, the guest PWA has its own
// localized (he/en/ar/ru) labels for the same keys.
const CATEGORY_LABELS: Record<string, string> = {
  housekeeping: '🛏️ חדרניות',
  maintenance:  '🔧 תחזוקה',
  reception:    '🛎️ קבלה',
}

const TILES_BY_CATEGORY: Record<string, { key: string; icon: string; label: string }[]> = {
  housekeeping: [
    { key: 'extra_towels',    icon: '🧺', label: 'מגבות נוספות' },
    { key: 'extra_pillows',   icon: '🛏️', label: 'כריות נוספות' },
    { key: 'clean_room',      icon: '🧹', label: 'ניקיון החדר עכשיו' },
    { key: 'do_not_disturb',  icon: '🚫', label: 'נא לא להפריע' },
    { key: 'toiletries',      icon: '🧴', label: 'מוצרי טיפוח' },
    { key: 'ice_water',       icon: '🧊', label: 'קרח ומים' },
  ],
  maintenance: [
    { key: 'ac_issue',        icon: '❄️', label: 'מיזוג לא עובד' },
    { key: 'tv_issue',        icon: '📺', label: 'טלוויזיה לא עובדת' },
    { key: 'wifi_issue',      icon: '📶', label: 'בעיית WiFi' },
    { key: 'plumbing_issue',  icon: '🚿', label: 'בעיית אינסטלציה' },
    { key: 'light_bulb',      icon: '💡', label: 'נורה שרופה' },
    { key: 'power_outlet',    icon: '🔌', label: 'שקע חשמל' },
  ],
  reception: [
    { key: 'late_checkout',    icon: '🕐', label: "צ'ק-אאוט מאוחר" },
    { key: 'extra_key',        icon: '🔑', label: 'מפתח נוסף' },
    { key: 'taxi_request',     icon: '🚕', label: 'הזמנת מונית' },
    { key: 'luggage_help',     icon: '🧳', label: 'עזרה עם מזוודות' },
    { key: 'wake_up_call',     icon: '⏰', label: 'שיחת השכמה' },
    { key: 'invoice_request',  icon: '🧾', label: 'חשבונית / קבלה' },
  ],
}

export function RequestTilesManager({
  disabledKeys,
  setTileAction,
}: {
  disabledKeys: string[]
  setTileAction: (fd: FormData) => Promise<void>
}) {
  const disabled = new Set(disabledKeys)

  return (
    <div className="space-y-8">
      {Object.entries(TILES_BY_CATEGORY).map(([category, tiles]) => (
        <div key={category}>
          <h2 className="text-sm font-semibold text-gray-600 mb-3">
            {CATEGORY_LABELS[category] ?? category}
          </h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-3">
            {tiles.map((tile) => {
              const enabled = !disabled.has(`${category}:${tile.key}`)
              return (
                <form key={tile.key} action={setTileAction}>
                  <input type="hidden" name="category" value={category} />
                  <input type="hidden" name="tile_key" value={tile.key} />
                  <input type="hidden" name="next_enabled" value={(!enabled).toString()} />
                  <button
                    type="submit"
                    className={`w-full rounded-xl border p-3 text-center transition-colors ${
                      enabled
                        ? 'bg-white border-gray-200 hover:border-gray-400'
                        : 'bg-gray-50 border-gray-200 opacity-40 hover:opacity-70'
                    }`}
                  >
                    <div className="text-2xl mb-1">{tile.icon}</div>
                    <div className="text-xs font-medium text-gray-700 leading-tight">
                      {tile.label}
                    </div>
                    <div
                      className={`mt-2 text-[10px] font-semibold rounded-full px-2 py-0.5 inline-block ${
                        enabled ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-500'
                      }`}
                    >
                      {enabled ? 'מוצג' : 'כבוי'}
                    </div>
                  </button>
                </form>
              )
            })}
          </div>
        </div>
      ))}
    </div>
  )
}
