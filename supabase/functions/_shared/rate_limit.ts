/**
 * Database-Based Rate Limiting Helper
 *
 * Provides rate limiting without Redis, using the rate_limit_counters
 * table and a stored procedure for atomic check-and-increment.
 *
 * Usage:
 *   const result = await checkRateLimit(supabase, {
 *     key: `ai-reply:${userId}`,
 *     limit: 50,
 *     windowSeconds: 86400, // 24 hours
 *   });
 *   if (!result.allowed) {
 *     return new Response(JSON.stringify({ error: 'Rate limit exceeded' }), {
 *       status: 429,
 *       headers: { 'Retry-After': String(result.retryAfterSeconds) },
 *     });
 *   }
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface RateLimitOptions {
  /** Unique key identifying the resource + user (e.g., "ai-reply:user-id") */
  key: string
  /** Maximum number of requests allowed in the window */
  limit: number
  /** Window duration in seconds */
  windowSeconds: number
}

interface RateLimitResult {
  /** Whether the request is allowed */
  allowed: boolean
  /** Remaining requests in the current window */
  remaining: number
  /** Total limit for the window */
  limit: number
  /** Seconds until the window resets */
  retryAfterSeconds: number
}

/**
 * Check and increment rate limit counter atomically.
 * Uses the check_and_increment_rate_limit stored procedure.
 */
export async function checkRateLimit(
  supabase: SupabaseClient,
  options: RateLimitOptions
): Promise<RateLimitResult> {
  const { key, limit, windowSeconds } = options

  try {
    const { data, error } = await supabase.rpc('check_and_increment_rate_limit', {
      p_key: key,
      p_limit: limit,
      p_window_seconds: windowSeconds,
    })

    if (error) {
      console.error('[RateLimit] RPC error:', error.message)
      // Fail open on DB error to avoid blocking legitimate requests
      return { allowed: true, remaining: limit, limit, retryAfterSeconds: 0 }
    }

    const result = Array.isArray(data) ? data[0] : data
    if (!result) {
      return { allowed: true, remaining: limit, limit, retryAfterSeconds: 0 }
    }

    const currentCount = result.current_count || 0
    const windowStart = result.window_start ? new Date(result.window_start) : new Date()
    const windowEnd = new Date(windowStart.getTime() + windowSeconds * 1000)
    const retryAfterSeconds = Math.max(0, Math.ceil((windowEnd.getTime() - Date.now()) / 1000))

    return {
      allowed: result.allowed !== false,
      remaining: Math.max(0, limit - currentCount),
      limit,
      retryAfterSeconds,
    }
  } catch (err) {
    console.error('[RateLimit] Unexpected error:', err)
    // Fail open
    return { allowed: true, remaining: limit, limit, retryAfterSeconds: 0 }
  }
}

/**
 * Build rate limit response headers for 429 or successful responses.
 */
export function rateLimitHeaders(result: RateLimitResult): Record<string, string> {
  const headers: Record<string, string> = {
    'X-RateLimit-Limit': String(result.limit),
    'X-RateLimit-Remaining': String(result.remaining),
  }
  if (!result.allowed) {
    headers['Retry-After'] = String(result.retryAfterSeconds)
  }
  return headers
}
