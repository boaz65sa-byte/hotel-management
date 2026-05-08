'use client'
import { useState, useRef } from 'react'
import { uploadLogoAction } from '@/app/actions/upload-logo'

type Props = {
  value: string | null
  onChange: (url: string | null) => void
  hiddenInputName?: string
}

const MAX_BYTES = 2 * 1024 * 1024 // 2 MB
const ACCEPT = 'image/png,image/jpeg,image/webp,image/svg+xml'

export function LogoPicker({ value, onChange, hiddenInputName = 'logo_url' }: Props) {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const fileRef = useRef<HTMLInputElement | null>(null)

  async function handleFile(file: File) {
    setError(null)
    if (file.size > MAX_BYTES) {
      setError(`הקובץ גדול מ-2MB (${(file.size / 1024 / 1024).toFixed(1)}MB)`)
      return
    }
    if (!ACCEPT.split(',').includes(file.type)) {
      setError('פורמט לא נתמך — רק PNG / JPG / WebP / SVG')
      return
    }
    setBusy(true)
    try {
      const fd = new FormData()
      fd.append('file', file)
      const res = await uploadLogoAction(fd)
      if (!res.ok || !res.url) {
        setError(res.error ?? 'שגיאה בהעלאה')
        return
      }
      onChange(res.url)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'שגיאה בהעלאה')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div>
      <input type="hidden" name={hiddenInputName} value={value ?? ''} />

      <div className="flex items-start gap-4">
        <div className="h-20 w-20 rounded-lg border bg-gray-50 flex items-center justify-center overflow-hidden flex-shrink-0">
          {value ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={value} alt="Logo" className="h-full w-full object-cover" />
          ) : (
            <span className="text-3xl text-gray-300">🏨</span>
          )}
        </div>

        <div className="flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              disabled={busy}
              onClick={() => fileRef.current?.click()}
              className="inline-flex items-center gap-2 bg-blue-600 text-white px-3 py-1.5 rounded-lg text-sm hover:bg-blue-700 disabled:opacity-50"
            >
              {busy ? 'מעלה...' : (value ? 'החלף קובץ' : 'בחר קובץ')}
            </button>

            {value && (
              <button
                type="button"
                disabled={busy}
                onClick={() => onChange(null)}
                className="text-sm text-red-600 hover:underline"
              >
                הסר
              </button>
            )}

            <input
              ref={fileRef}
              type="file"
              accept={ACCEPT}
              hidden
              onChange={(e) => {
                const f = e.target.files?.[0]
                if (f) handleFile(f)
                e.target.value = ''
              }}
            />
          </div>

          <p className="text-xs text-gray-500 mt-1">
            PNG / JPG / WebP / SVG · עד 2MB · יוצג באפליקציית האורחים.
          </p>

          {error && (
            <p className="text-xs text-red-600 mt-1">⚠️ {error}</p>
          )}

          {value && (
            <p className="text-xs text-gray-400 mt-1 break-all" dir="ltr">
              {value}
            </p>
          )}
        </div>
      </div>
    </div>
  )
}
