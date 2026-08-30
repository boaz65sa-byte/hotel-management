'use client'
import { useEffect, useState } from 'react'
import { createClient } from '@supabase/supabase-js'

// Client-side only, same pattern as the login page — MFA enrollment has to
// happen against the signed-in user's own session, not the service_role
// client the rest of the dashboard reads through.
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

type Factor = { id: string; friendly_name?: string; status: 'verified' | 'unverified' }

export default function SecurityPage() {
  const [loading, setLoading] = useState(true)
  const [factors, setFactors] = useState<Factor[]>([])
  const [enrolling, setEnrolling] = useState(false)
  const [qrCode, setQrCode] = useState<string | null>(null)
  const [secret, setSecret] = useState<string | null>(null)
  const [pendingFactorId, setPendingFactorId] = useState<string | null>(null)
  const [code, setCode] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  async function loadFactors() {
    const { data, error } = await supabase.auth.mfa.listFactors()
    if (error) { setError(error.message); setLoading(false); return }
    setFactors((data?.totp ?? []) as Factor[])
    setLoading(false)
  }

  useEffect(() => { loadFactors() }, [])

  const verifiedFactor = factors.find((f) => f.status === 'verified')

  async function startEnroll() {
    setError(''); setSuccess('')
    // Clean up any half-finished enrollment from a previous visit before
    // starting a new one, so re-attempts don't pile up unverified factors.
    for (const f of factors.filter((f) => f.status === 'unverified')) {
      await supabase.auth.mfa.unenroll({ factorId: f.id })
    }
    const { data, error } = await supabase.auth.mfa.enroll({
      factorType: 'totp',
      friendlyName: `Admin panel — ${new Date().toISOString().slice(0, 10)}`,
    })
    if (error) { setError(error.message); return }
    setQrCode(data.totp.qr_code)
    setSecret(data.totp.secret)
    setPendingFactorId(data.id)
    setEnrolling(true)
  }

  async function confirmEnroll(e: React.FormEvent) {
    e.preventDefault()
    if (!pendingFactorId) return
    setError('')
    const { data: challenge, error: challengeError } =
      await supabase.auth.mfa.challenge({ factorId: pendingFactorId })
    if (challengeError || !challenge) { setError(challengeError?.message ?? 'Challenge failed'); return }
    const { error: verifyError } = await supabase.auth.mfa.verify({
      factorId: pendingFactorId, challengeId: challenge.id, code,
    })
    if (verifyError) { setError(verifyError.message); return }
    setEnrolling(false); setQrCode(null); setSecret(null); setPendingFactorId(null); setCode('')
    setSuccess('אימות דו-שלבי הופעל בהצלחה. בכניסה הבאה תתבקש קוד מהאפליקציה שלך.')
    loadFactors()
  }

  async function removeFactor(factorId: string) {
    if (!confirm('לבטל את האימות הדו-שלבי? זה יחליש את אבטחת החשבון.')) return
    setError('')
    const { error } = await supabase.auth.mfa.unenroll({ factorId })
    if (error) { setError(error.message); return }
    setSuccess('אימות דו-שלבי בוטל.')
    loadFactors()
  }

  return (
    <div dir="rtl" className="max-w-lg">
      <h1 className="text-2xl font-bold mb-2">🔐 אבטחת חשבון</h1>
      <p className="text-sm text-gray-500 mb-6">
        אימות דו-שלבי (TOTP) מוסיף קוד חד-פעמי מאפליקציית Authenticator בנוסף לסיסמה שלך בכל כניסה.
      </p>

      {loading ? (
        <p className="text-gray-500">טוען…</p>
      ) : (
        <div className="bg-white rounded-xl border p-6 space-y-4">
          {success && (
            <div className="bg-green-50 border border-green-200 text-green-700 text-sm rounded-lg px-3 py-2">
              {success}
            </div>
          )}
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg px-3 py-2">
              {error}
            </div>
          )}

          {verifiedFactor && !enrolling ? (
            <div className="flex items-center justify-between">
              <div>
                <div className="font-medium text-green-700">✓ אימות דו-שלבי מופעל</div>
                <div className="text-xs text-gray-500">{verifiedFactor.friendly_name ?? 'TOTP'}</div>
              </div>
              <button
                type="button"
                onClick={() => removeFactor(verifiedFactor.id)}
                className="text-sm text-red-600 hover:underline"
              >
                בטל
              </button>
            </div>
          ) : !enrolling ? (
            <div className="flex items-center justify-between">
              <div className="text-gray-600 text-sm">אימות דו-שלבי כבוי כרגע.</div>
              <button
                type="button"
                onClick={startEnroll}
                className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700"
              >
                + הפעל אימות דו-שלבי
              </button>
            </div>
          ) : (
            <form onSubmit={confirmEnroll} className="space-y-4">
              <div>
                <p className="text-sm font-medium mb-2">1. סרוק עם אפליקציית Authenticator (Google Authenticator, Authy וכו׳)</p>
                {qrCode && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={qrCode} alt="TOTP QR code" className="border rounded-lg w-48 h-48" />
                )}
                {secret && (
                  <p className="text-xs text-gray-500 mt-2">
                    או הזן ידנית: <code className="bg-gray-100 px-1 rounded" dir="ltr">{secret}</code>
                  </p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">2. הזן את הקוד בן 6 הספרות</label>
                <input
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  className="w-full border rounded px-3 py-2 text-center text-2xl tracking-widest"
                  dir="ltr"
                  maxLength={6}
                  placeholder="000000"
                  required
                  autoFocus
                />
              </div>
              <div className="flex gap-2">
                <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700">
                  אמת והפעל
                </button>
                <button
                  type="button"
                  onClick={() => { setEnrolling(false); setQrCode(null); setSecret(null); setPendingFactorId(null) }}
                  className="border px-4 py-2 rounded-lg text-sm"
                >
                  ביטול
                </button>
              </div>
            </form>
          )}
        </div>
      )}
    </div>
  )
}
