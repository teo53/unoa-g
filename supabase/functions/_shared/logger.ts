// =====================================================
// Structured Logger for Edge Functions
// Masks PII (user IDs, emails, etc.) in log output.
//
// SECURITY FIX: F-12
// Use this logger instead of raw console.log/error to
// prevent PII leakage in Sentry/CloudWatch/Supabase logs.
// =====================================================

/**
 * Hash a user ID for logging purposes.
 * Returns first 8 characters of a simple hash — enough for log correlation
 * but not reversible to the actual UUID.
 */
function hashId(id: string): string {
  if (!id) return 'unknown'
  // Simple non-cryptographic hash for log correlation
  let hash = 0
  for (let i = 0; i < id.length; i++) {
    const char = id.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash // Convert to 32-bit integer
  }
  return Math.abs(hash).toString(36).padStart(8, '0').substring(0, 8)
}

/**
 * Mask a UUID for safe logging.
 * "550e8400-e29b-41d4-a716-446655440000" → "u_3k7f2m1x"
 */
export function maskUserId(userId: string): string {
  return `u_${hashId(userId)}`
}

/**
 * Structured log entry for consistent log format.
 */
interface LogEntry {
  level: 'info' | 'warn' | 'error'
  fn: string // function name
  action: string
  userId?: string // will be masked
  details?: Record<string, unknown>
  error?: string
}

/**
 * Log a structured entry with masked PII.
 *
 * Usage:
 *   log({ level: 'info', fn: 'payment-webhook', action: 'payment_processed', userId: user.id, details: { amount: 1000 } })
 *
 * Output:
 *   [payment-webhook] payment_processed user=u_3k7f2m1x amount=1000
 */
export function log(entry: LogEntry): void {
  const { level, fn, action, userId, details, error } = entry

  const parts: string[] = [`[${fn}]`, action]

  if (userId) {
    parts.push(`user=${maskUserId(userId)}`)
  }

  if (details) {
    for (const [key, value] of Object.entries(details)) {
      // Skip null/undefined values
      if (value == null) continue
      // Mask any value that looks like a UUID
      const strValue = String(value)
      if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(strValue)) {
        parts.push(`${key}=${maskUserId(strValue)}`)
      } else {
        parts.push(`${key}=${strValue}`)
      }
    }
  }

  if (error) {
    parts.push(`error="${error}"`)
  }

  const message = parts.join(' ')

  switch (level) {
    case 'error':
      console.error(message)
      break
    case 'warn':
      console.warn(message)
      break
    default:
      console.log(message)
  }
}
