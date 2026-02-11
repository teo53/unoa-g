/**
 * Cron/Batch Function Authentication Helper
 *
 * Provides timing-safe secret verification for scheduled Edge Functions.
 * All cron/batch functions MUST call requireCronAuth() before processing.
 *
 * Setup:
 *   1. Set CRON_SECRET in Supabase Edge Function secrets
 *   2. Configure cron caller to include X-Cron-Secret header
 *
 * Usage:
 *   const authFail = requireCronAuth(req);
 *   if (authFail) return authFail;
 */

const CRON_SECRET = Deno.env.get('CRON_SECRET') || ''

/**
 * Timing-safe string comparison to prevent timing attacks.
 * Compares two strings in constant time regardless of where they differ.
 */
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false

  const encoder = new TextEncoder()
  const aBytes = encoder.encode(a)
  const bBytes = encoder.encode(b)

  let result = 0
  for (let i = 0; i < aBytes.length; i++) {
    result |= aBytes[i] ^ bBytes[i]
  }
  return result === 0
}

/**
 * Verify cron authentication from request headers.
 * Returns true if the X-Cron-Secret header matches the configured secret.
 */
export function verifyCronAuth(req: Request): boolean {
  if (!CRON_SECRET) {
    console.warn('[CronAuth] Authentication failed')
    return false
  }

  const providedSecret = req.headers.get('x-cron-secret') || ''
  if (!providedSecret) {
    return false
  }

  return timingSafeEqual(providedSecret, CRON_SECRET)
}

/**
 * Require cron authentication. Returns a 401 Response on failure, or null on success.
 *
 * Usage:
 *   const authFail = requireCronAuth(req);
 *   if (authFail) return authFail;
 */
export function requireCronAuth(req: Request): Response | null {
  if (verifyCronAuth(req)) {
    return null // Auth passed
  }

  console.warn('[CronAuth] Unauthorized cron request rejected')
  return new Response(
    JSON.stringify({ error: 'Unauthorized' }),
    {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    }
  )
}
