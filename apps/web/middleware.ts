import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

// SECURITY: Demo mode must be explicitly enabled via environment variable
// Never auto-enable demo mode based on missing config
const DEMO_MODE = process.env.NEXT_PUBLIC_DEMO_MODE === 'true'

// Protected route configurations
const protectedRoutes: Record<string, { roles: string[]; redirectTo: string }> = {
  '/studio': { roles: ['creator', 'admin'], redirectTo: '/' },
  '/admin': { roles: ['admin'], redirectTo: '/' },
}

// Helper function to check user role
async function checkUserRole(
  supabase: ReturnType<typeof createServerClient>,
  userId: string,
  allowedRoles: string[]
): Promise<boolean> {
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('role')
    .eq('id', userId)
    .single()

  return profile && allowedRoles.includes(profile.role)
}

// Helper function to create login redirect
function createLoginRedirect(request: NextRequest, pathname: string): NextResponse {
  const url = request.nextUrl.clone()
  url.pathname = '/login'
  url.searchParams.set('redirect', pathname)
  return NextResponse.redirect(url)
}

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  // In demo mode, allow all routes (must be explicitly enabled)
  if (DEMO_MODE) {
    console.warn('[MIDDLEWARE] Demo mode is enabled - authentication bypassed')
    return supabaseResponse
  }

  // Verify Supabase configuration exists
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

  if (!supabaseUrl || !supabaseAnonKey) {
    console.error('[MIDDLEWARE] Supabase configuration missing and DEMO_MODE not enabled')
    // Return 503 Service Unavailable for unconfigured production
    return new NextResponse('Service configuration error', { status: 503 })
  }

  const supabase = createServerClient(
    supabaseUrl,
    supabaseAnonKey,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // Refresh session
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const pathname = request.nextUrl.pathname

  // Check protected routes
  for (const [routePrefix, config] of Object.entries(protectedRoutes)) {
    if (pathname.startsWith(routePrefix)) {
      // Require authentication
      if (!user) {
        return createLoginRedirect(request, pathname)
      }

      // Check role authorization
      const hasRole = await checkUserRole(supabase, user.id, config.roles)
      if (!hasRole) {
        const url = request.nextUrl.clone()
        url.pathname = config.redirectTo
        return NextResponse.redirect(url)
      }

      // User is authorized, continue
      break
    }
  }

  return supabaseResponse
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public folder
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
