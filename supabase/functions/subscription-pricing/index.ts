// Subscription Pricing Edge Function
// Allows creators to set subscription pricing presets for their channels.
//
// GET  ?channelId=xxx  → returns current pricing policy
// PUT  { channelId, preset }  → sets pricing policy (creator-only)
//
// Presets:
//   support  (0.9x) — 팬 우선 할인 가격
//   standard (1.0x) — 기본 가격
//   premium  (1.1x) — 프리미엄 가격

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders } from '../_shared/cors.ts'

const jsonHeaders = { 'Content-Type': 'application/json' }

/** Pricing presets — multiplier applied to base tierPrices */
const PRESETS: Record<string, { multiplier: number; label: string }> = {
  support:  { multiplier: 0.9, label: '팬 우선 (10% 할인)' },
  standard: { multiplier: 1.0, label: '기본가' },
  premium:  { multiplier: 1.1, label: '프리미엄 (10% 추가)' },
}

/** policy_config key pattern */
function policyKey(channelId: string): string {
  return `subscription_pricing:${channelId}`
}

/** Round price to nearest 100 KRW */
function roundPrice(base: number, multiplier: number): number {
  return Math.round((base * multiplier) / 100) * 100
}

serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: getCorsHeaders(req) })
  }

  const headers = { ...getCorsHeaders(req), ...jsonHeaders }

  try {
    const url = new URL(req.url)

    // ─── GET: 현재 가격 정책 조회 ───
    if (req.method === 'GET') {
      const channelId = url.searchParams.get('channelId')
      if (!channelId) {
        return new Response(
          JSON.stringify({ error: 'Missing channelId parameter' }),
          { status: 400, headers },
        )
      }

      const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      )

      const { data } = await supabase
        .from('policy_config')
        .select('value')
        .eq('key', policyKey(channelId))
        .maybeSingle()

      // Default to standard if not configured
      const policy = data?.value ?? { preset: 'standard', multiplier: 1.0 }

      return new Response(
        JSON.stringify({ success: true, channelId, policy }),
        { status: 200, headers },
      )
    }

    // ─── PUT: 가격 정책 설정 (크리에이터 전용) ───
    if (req.method === 'PUT') {
      // Authenticate
      const authHeader = req.headers.get('Authorization')
      if (!authHeader) {
        return new Response(
          JSON.stringify({ error: 'Missing authorization header' }),
          { status: 401, headers },
        )
      }

      const supabaseAuth = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        { global: { headers: { Authorization: authHeader } } },
      )
      const { data: { user }, error: authError } = await supabaseAuth.auth.getUser()
      if (authError || !user) {
        return new Response(
          JSON.stringify({ error: 'Invalid or expired token' }),
          { status: 401, headers },
        )
      }

      const { channelId, preset } = await req.json()

      // Validate inputs
      if (!channelId || !preset) {
        return new Response(
          JSON.stringify({ error: 'Missing required fields: channelId, preset' }),
          { status: 400, headers },
        )
      }

      if (!PRESETS[preset]) {
        return new Response(
          JSON.stringify({
            error: `Invalid preset. Valid values: ${Object.keys(PRESETS).join(', ')}`,
          }),
          { status: 400, headers },
        )
      }

      // Service role client for ownership check + upsert
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      )

      // Verify the user owns this channel
      const { data: channel, error: channelError } = await supabase
        .from('channels')
        .select('id, artist_id')
        .eq('id', channelId)
        .single()

      if (channelError || !channel) {
        return new Response(
          JSON.stringify({ error: 'Channel not found' }),
          { status: 404, headers },
        )
      }

      if (channel.artist_id !== user.id) {
        return new Response(
          JSON.stringify({ error: 'Only the channel owner can set pricing policy' }),
          { status: 403, headers },
        )
      }

      // Upsert pricing policy
      const policyValue = {
        preset,
        multiplier: PRESETS[preset].multiplier,
        label: PRESETS[preset].label,
        updatedAt: new Date().toISOString(),
        updatedBy: user.id,
      }

      const { error: upsertError } = await supabase
        .from('policy_config')
        .upsert(
          { key: policyKey(channelId), value: policyValue },
          { onConflict: 'key' },
        )

      if (upsertError) {
        console.error('Failed to upsert pricing policy:', upsertError)
        return new Response(
          JSON.stringify({ error: 'Failed to save pricing policy' }),
          { status: 500, headers },
        )
      }

      return new Response(
        JSON.stringify({ success: true, channelId, policy: policyValue }),
        { status: 200, headers },
      )
    }

    // Unsupported method
    return new Response(
      JSON.stringify({ error: `Method ${req.method} not allowed` }),
      { status: 405, headers },
    )
  } catch (error) {
    console.error('Subscription pricing error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } },
    )
  }
})
