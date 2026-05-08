'use server'
import { supabaseAdmin } from '@/lib/supabase-admin'

const ALLOWED_MIME = new Set([
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/webp',
  'image/svg+xml',
])
const MAX_BYTES = 2 * 1024 * 1024

export async function uploadLogoAction(
  fd: FormData,
): Promise<{ ok: boolean; url?: string; error?: string }> {
  const file = fd.get('file')
  if (!(file instanceof File)) {
    return { ok: false, error: 'לא התקבל קובץ' }
  }
  if (file.size > MAX_BYTES) {
    return { ok: false, error: 'הקובץ גדול מ-2MB' }
  }
  if (!ALLOWED_MIME.has(file.type)) {
    return { ok: false, error: 'פורמט לא נתמך' }
  }

  const ext = (file.name.split('.').pop() || 'bin').toLowerCase()
  const path = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`
  const bytes = new Uint8Array(await file.arrayBuffer())

  const { error: upErr } = await supabaseAdmin.storage
    .from('hotel-logos')
    .upload(path, bytes, {
      contentType: file.type,
      upsert: false,
    })

  if (upErr) {
    return { ok: false, error: upErr.message }
  }

  const { data } = supabaseAdmin.storage.from('hotel-logos').getPublicUrl(path)
  return { ok: true, url: data.publicUrl }
}
