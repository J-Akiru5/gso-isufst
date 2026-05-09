import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'
import type { Database } from '@/types/database.types'

// Role-based route protection map
const ROLE_ROUTES: Record<string, string[]> = {
  '/dashboard/admin': ['super_admin'],
  '/dashboard/settings': ['super_admin'],
  '/dashboard/users': ['super_admin', 'gso_staff'],
  '/dashboard/inventory': ['super_admin', 'gso_staff'],
  '/dashboard/reports': ['super_admin', 'gso_staff'],
}

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { pathname } = request.nextUrl

  // ── Redirect unauthenticated users trying to access dashboard ──
  if (pathname.startsWith('/dashboard') && !user) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  // ── Redirect authenticated users away from auth pages ──────────
  if ((pathname === '/login' || pathname === '/register') && user) {
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  // ── Check approval status ──────────────────────────────────────
  if (pathname.startsWith('/dashboard') && user) {
    const { data: profileData } = await supabase
      .from('profiles')
      .select('is_approved, is_active')
      .eq('id', user.id)
      .single()
    const profile = profileData as any

    if (!profile?.is_approved) {
      return NextResponse.redirect(new URL('/pending-approval', request.url))
    }

    if (!profile?.is_active) {
      await supabase.auth.signOut()
      return NextResponse.redirect(new URL('/login?reason=deactivated', request.url))
    }
  }

  return supabaseResponse
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|logo.jpg|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
