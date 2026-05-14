// Server-side auth for the Next.js admin panel — super_admin (platform owner)
// OR hotel-tier admins (מנכל / מנהל תוכנה / hotel_admin legacy) scoped to one hotel.

import { cookies } from 'next/headers'
import type { NextRequest } from 'next/server'
import { createClient } from '@supabase/supabase-js'
import { notFound, redirect } from 'next/navigation'
import { cache } from 'react'

import {
  canManageAdmin,
  isHotelAdmin,
  isSuperAdmin,
} from '@/lib/roles'

export type DashboardViewer = {
  userId: string
  email: string | null
  fullName: string | null
  role: string
  hotelId: string | null
  isSuperAdmin: boolean
  isHotelTierAdmin: boolean
}

export type ApiAuthSession = DashboardViewer & { access_token: string }

const supabaseService = () =>
  createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

async function loadViewer(accessToken: string): Promise<DashboardViewer | null> {
  const supabase = supabaseService()
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(accessToken)
  if (error || !user) return null

  const { data: profile } = await supabase
    .from('users')
    .select('role, hotel_id, full_name')
    .eq('id', user.id)
    .maybeSingle()

  if (!profile?.role) return null
  const role = profile.role as string
  if (!canManageAdmin(role)) return null

  if (isHotelAdmin(role) && !(profile.hotel_id as string | null)) return null

  return {
    userId: user.id,
    email: user.email ?? null,
    fullName: (profile.full_name as string | null) ?? null,
    role,
    hotelId: (profile.hotel_id as string | null) ?? null,
    isSuperAdmin: isSuperAdmin(role),
    isHotelTierAdmin: isHotelAdmin(role),
  }
}

async function viewerFromCookies(): Promise<DashboardViewer | null> {
  const cookieStore = await cookies()
  const token = cookieStore.get('sb-access-token')?.value
  if (!token) return null
  return loadViewer(token)
}

/** Per-request memoization for layouts + pages during a single navigation. */
export const getDashboardViewer = cache(async (): Promise<DashboardViewer | null> => {
  return viewerFromCookies()
})

/** Throws redirect to login if unauthenticated / disallowed role. */
export async function requireDashboardViewer(): Promise<DashboardViewer> {
  const v = await getDashboardViewer()
  if (!v) redirect('/login')
  return v
}

/** Platform owner only (legacy API name). Redirects unauthorized users away from admin. */
export async function requireSuperAdmin(): Promise<DashboardViewer> {
  const v = await requireDashboardViewer()
  if (!v.isSuperAdmin) redirect('/dashboard')
  return v
}

/**
 * Restrict to a hotel id. Super admin passes through; hotel admin must match.
 */
export function assertHotelAccess(viewer: DashboardViewer, hotelId: string) {
  if (viewer.isSuperAdmin) return
  if (!viewer.hotelId || viewer.hotelId !== hotelId) notFound()
}

/** Server actions — throw instead of masking as 404. */
export function assertHotelMutationAllowed(viewer: DashboardViewer, hotelId: string) {
  if (viewer.isSuperAdmin) return
  if (!viewer.hotelId || viewer.hotelId !== hotelId) {
    throw new Error('Forbidden')
  }
}

/**
 * Cookie-based bearer for REST route handlers (+ optional cookie string fallback).
 */
export async function authGuard(req: NextRequest): Promise<ApiAuthSession | null> {
  const token =
    req.cookies.get('sb-access-token')?.value ??
    req.headers.get('cookie')?.match(/sb-access-token=([^;]+)/)?.[1]
  if (!token) return null

  const v = await loadViewer(token)
  if (!v) return null
  return { ...v, access_token: token }
}

/** Viewer for server actions (no React cache — each POST is isolated). */
export async function verifyDashboardViewerForAction(): Promise<DashboardViewer | null> {
  return viewerFromCookies()
}
