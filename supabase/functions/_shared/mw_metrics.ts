/**
 * Middleware Metrics Emitter for T4 Observability
 *
 * Writes one row to ops_mw_events per notable middleware event.
 * Uses service_role client (INSERT-only, no auth context needed).
 * Fire-and-forget: errors are logged but never thrown.
 * Never blocks the response path.
 *
 * Usage:
 *   import { emitMwEvent } from '../_shared/mw_metrics.ts'
 *
 *   // After rate limit check:
 *   if (!rlResult.allowed) {
 *     emitMwEvent(adminClient, {
 *       fnName: 'ai-reply-suggest',
 *       eventType: 'rate_limited',
 *       statusCode: 429,
 *       userHash: maskUserId(user.id),
 *     })
 *     return new Response(...)
 *   }
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export type MwEventType =
  | 'rate_limited'
  | 'schema_invalid'
  | 'circuit_open'
  | 'abuse_suspected'
  | 'error_5xx'
  | 'slow_request'

interface MwEventPayload {
  fnName: string
  eventType: MwEventType
  statusCode?: number
  latencyMs?: number
  userHash?: string
}

/**
 * Emit a middleware event to ops_mw_events.
 * Fire-and-forget: awaiting is optional. Never throws.
 * Pass a service_role SupabaseClient — this writes to a
 * table that is RLS-denied for regular users.
 */
export function emitMwEvent(
  supabase: SupabaseClient,
  payload: MwEventPayload
): void {
  Promise.resolve().then(async () => {
    try {
      const { error } = await supabase
        .from('ops_mw_events')
        .insert({
          fn_name: payload.fnName,
          event_type: payload.eventType,
          status_code: payload.statusCode ?? null,
          latency_ms: payload.latencyMs ?? null,
          user_hash: payload.userHash ?? null,
        })

      if (error) {
        console.error(
          `[mw_metrics] insert failed fn=${payload.fnName} type=${payload.eventType} err=${error.message}`
        )
      }
    } catch (err) {
      console.error(`[mw_metrics] unexpected error: ${String(err)}`)
    }
  })
}

/**
 * Convenience: emit slow_request event when latency exceeds 5 seconds.
 */
export function emitSlowRequest(
  supabase: SupabaseClient,
  fnName: string,
  latencyMs: number,
  userHash?: string
): void {
  if (latencyMs > 5000) {
    emitMwEvent(supabase, {
      fnName,
      eventType: 'slow_request',
      latencyMs,
      userHash,
    })
  }
}
