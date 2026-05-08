'use server'

import { supabaseAdmin } from '@/lib/supabase-admin'
import QRCode from 'qrcode'
import JSZip from 'jszip'

const FALLBACK_PWA_BASE_URL = 'https://exquisite-cocada-7966bd.netlify.app'

/**
 * Builds a ZIP file containing one PNG per room QR code for a hotel.
 * Returns a base64-encoded string of the ZIP, or `null` if the hotel has no rooms.
 *
 * Called from the QR codes page client to trigger a single download of all
 * room QRs (saves needing to right-click each one).
 */
export async function buildHotelQrZipBase64(
  hotelId: string,
): Promise<{ base64: string; filename: string } | null> {
  const { data: hotel } = await supabaseAdmin
    .from('hotels')
    .select('id, name, guest_pwa_url')
    .eq('id', hotelId)
    .single()
  if (!hotel) return null

  const baseUrl =
    (hotel.guest_pwa_url as string | null)?.trim() || FALLBACK_PWA_BASE_URL

  const { data: rooms } = await supabaseAdmin
    .from('rooms')
    .select('room_number')
    .eq('hotel_id', hotelId)
    .order('room_number')

  if (!rooms || rooms.length === 0) return null

  const zip = new JSZip()

  await Promise.all(
    rooms.map(async (room) => {
      const url = `${baseUrl}/#/?hotel=${hotel.id}&room=${room.room_number}`
      const buffer = await QRCode.toBuffer(url, {
        width: 600,
        margin: 2,
        color: { dark: '#0a1628', light: '#ffffff' },
      })
      zip.file(`qr-room-${room.room_number}.png`, buffer)
    }),
  )

  // Include a small text manifest for reference
  const manifest = rooms
    .map((r) => `Room ${r.room_number}: ${baseUrl}/#/?hotel=${hotel.id}&room=${r.room_number}`)
    .join('\n')
  zip.file('README.txt', `${hotel.name} — Guest PWA QR codes\n\n${manifest}\n`)

  const buf = await zip.generateAsync({ type: 'nodebuffer' })
  const safeName = hotel.name.replace(/[^a-zA-Z0-9-_]+/g, '_')
  return {
    base64: buf.toString('base64'),
    filename: `qr-codes-${safeName}.zip`,
  }
}
