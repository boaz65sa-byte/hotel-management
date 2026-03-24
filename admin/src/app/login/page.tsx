'use client'
import { useState } from 'react'
import { createClient } from '@supabase/supabase-js'
import { useRouter } from 'next/navigation'

// Client-side only for login (uses anon key just for auth)
const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [mfaCode, setMfaCode] = useState('')
  const [step, setStep] = useState<'credentials' | 'mfa'>('credentials')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true); setError('')
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error

      if (data.session) {
        const { data: factors } = await supabase.auth.mfa.listFactors()
        if (!factors?.totp?.length) {
          // MFA not enrolled — sign them out and show error
          await supabase.auth.signOut()
          setError('MFA is required. Please enroll TOTP via Supabase dashboard first.')
          setLoading(false)
          return
        }
        setStep('mfa')
      }
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'An error occurred')
    } finally {
      setLoading(false)
    }
  }

  async function handleMfa(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true); setError('')
    try {
      const { data: factorsData } = await supabase.auth.mfa.listFactors()
      const totp = factorsData?.totp
      const factorId = totp![0].id
      const { data: challenge } = await supabase.auth.mfa.challenge({ factorId })
      await supabase.auth.mfa.verify({ factorId, challengeId: challenge!.id, code: mfaCode })
      router.push('/dashboard')
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'An error occurred')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="bg-white p-8 rounded-xl shadow w-full max-w-sm">
        <h1 className="text-2xl font-bold mb-6">Super Admin</h1>

        {step === 'credentials' ? (
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1">Email</label>
              <input type="email" value={email} onChange={e => setEmail(e.target.value)}
                className="w-full border rounded px-3 py-2" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Password</label>
              <input type="password" value={password} onChange={e => setPassword(e.target.value)}
                className="w-full border rounded px-3 py-2" required />
            </div>
            {error && <p className="text-red-500 text-sm">{error}</p>}
            <button type="submit" disabled={loading}
              className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 disabled:opacity-50">
              {loading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>
        ) : (
          <form onSubmit={handleMfa} className="space-y-4">
            <p className="text-sm text-gray-600">Enter your authenticator code:</p>
            <input value={mfaCode} onChange={e => setMfaCode(e.target.value)}
              className="w-full border rounded px-3 py-2 text-center text-2xl tracking-widest"
              maxLength={6} placeholder="000000" required />
            {error && <p className="text-red-500 text-sm">{error}</p>}
            <button type="submit" disabled={loading}
              className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700 disabled:opacity-50">
              {loading ? 'Verifying...' : 'Verify'}
            </button>
          </form>
        )}
      </div>
    </div>
  )
}
