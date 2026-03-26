'use client'

export function ThemePicker({ hotel }: { hotel: { id: string; theme?: string | null } }) {
  async function updateTheme(theme: string) {
    await fetch(`/api/hotels/${hotel.id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ theme }),
    })
    // Reload page to show updated state
    window.location.reload()
  }

  return (
    <div className="flex items-center gap-2">
      <span className="text-xs text-gray-500">ערכת עיצוב:</span>
      <button
        onClick={() => updateTheme('clean_blue')}
        className={`px-3 py-1 rounded-md text-xs font-medium border transition-all ${
          !hotel.theme || hotel.theme === 'clean_blue'
            ? 'border-blue-600 bg-blue-50 text-blue-700'
            : 'border-gray-200 text-gray-500 hover:border-blue-300'
        }`}
      >
        ☀️ Clean Blue
      </button>
      <button
        onClick={() => updateTheme('luxury')}
        className={`px-3 py-1 rounded-md text-xs font-medium border transition-all ${
          hotel.theme === 'luxury'
            ? 'border-yellow-500 bg-yellow-50 text-yellow-700'
            : 'border-gray-200 text-gray-500 hover:border-yellow-300'
        }`}
      >
        🌙 Luxury
      </button>
    </div>
  )
}
