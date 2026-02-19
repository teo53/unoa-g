// Payment Checkout Edge Function
// Creates a checkout session for DT purchases

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, isAllowedOrigin } from '../_shared/cors.ts'
import { checkRateLimit, rateLimitHeaders } from '../_shared/rate_limit.ts'

const jsonHeaders = { 'Content-Type': 'application/json' }

type PlatformKey = 'web' | 'android' | 'ios'

// DT Package definitions with platform-specific pricing
// Web = base price, Android ≈ +20%, iOS ≈ +30% (IAP commission offset)
const DT_PACKAGES: Record<string, {
  dt: number; bonus: number; name: string;
  prices: Record<PlatformKey, number>;
}> = {
  'dt_10':   { dt: 10,   bonus: 0,    name: '10 DT',    prices: { web: 1000,   android: 1200,   ios: 1400   } },
  'dt_50':   { dt: 50,   bonus: 0,    name: '50 DT',    prices: { web: 5000,   android: 5900,   ios: 6900   } },
  'dt_100':  { dt: 100,  bonus: 5,    name: '100 DT',   prices: { web: 10000,  android: 11900,  ios: 13900  } },
  'dt_500':  { dt: 500,  bonus: 50,   name: '500 DT',   prices: { web: 50000,  android: 59000,  ios: 69000  } },
  'dt_1000': { dt: 1000, bonus: 150,  name: '1,000 DT', prices: { web: 100000, android: 119000, ios: 139000 } },
  'dt_5000': { dt: 5000, bonus: 1000, name: '5,000 DT', prices: { web: 500000, android: 590000, ios: 690000 } },
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: getCorsHeaders(req) })
  }

  try {
    // SECURITY: Extract userId from JWT, not from request body
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    const supabaseAuth = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error: authError } = await supabaseAuth.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // userId comes from verified JWT — body userId is ignored for security
    const userId = user.id
    const { packageId, paymentMethod = 'card', platform = 'web' } = await req.json()

    // Validate platform
    const validPlatforms: PlatformKey[] = ['web', 'android', 'ios']
    const requestedPlatform: PlatformKey = validPlatforms.includes(platform) ? platform : 'web'

    // SECURITY: Cross-validate platform claim against request origin
    // Prevents price manipulation where native apps claim 'web' to get lower pricing
    const origin = req.headers.get('Origin')
    let platformKey: PlatformKey

    if (origin && isAllowedOrigin(origin)) {
      // Request has valid web origin → force web pricing regardless of claim
      platformKey = 'web'
    } else if (origin) {
      // Unknown origin → reject (possible spoofing attempt)
      return new Response(
        JSON.stringify({ error: 'Origin not allowed' }),
        { status: 403, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    } else {
      // No origin (native app) → trust platform claim but cannot be 'web'
      // Native apps should claim 'android' or 'ios', not 'web'
      platformKey = requestedPlatform === 'web' ? 'android' : requestedPlatform
    }

    // Validate inputs
    if (!packageId) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: packageId' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    const pkg = DT_PACKAGES[packageId]
    if (!pkg) {
      return new Response(
        JSON.stringify({ error: 'Invalid package ID' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Resolve platform-specific price
    const priceKrw = pkg.prices[platformKey]

    // Initialize Supabase client with service role
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Verify user exists and can make payments
    const { data: userProfile, error: userError } = await supabase
      .from('user_profiles')
      .select('id, is_banned, date_of_birth, guardian_consent_at')
      .eq('id', userId)
      .single()

    if (userError || !userProfile) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (userProfile.is_banned) {
      return new Response(
        JSON.stringify({ error: 'User account is suspended' }),
        { status: 403, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Check age restrictions for minors (Korean law)
    if (userProfile.date_of_birth) {
      const birthDate = new Date(userProfile.date_of_birth)
      const age = Math.floor((Date.now() - birthDate.getTime()) / (365.25 * 24 * 60 * 60 * 1000))

      if (age < 14) {
        return new Response(
          JSON.stringify({ error: '만 14세 미만은 결제가 불가합니다.' }),
          { status: 403, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }

      if (age < 19 && !userProfile.guardian_consent_at) {
        return new Response(
          JSON.stringify({ error: '만 19세 미만은 법정대리인 동의가 필요합니다.' }),
          { status: 403, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
        )
      }
    }

    // B6: Pending order limit — max 10 pending orders per hour per user
    const rlResult = await checkRateLimit(supabase, {
      key: `checkout:${userId}`,
      limit: 10,
      windowSeconds: 3600, // 1 hour
    })
    if (!rlResult.allowed) {
      return new Response(
        JSON.stringify({ error: 'Too many pending orders. Please try again later.' }),
        { status: 429, headers: { ...getCorsHeaders(req), ...jsonHeaders, ...rateLimitHeaders(rlResult) } }
      )
    }

    // Calculate refund eligibility (7 days from now)
    const refundEligibleUntil = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()

    // VAT 계산 (부가가치세법 §29① + 서면법규과-823)
    // DT 구매 시점: 계약부채(선수금) 인식. DT 사용(서비스 제공) 시점: 매출 인식 및 VAT 과세(공급시기)
    // 결제 시점에는 총액 기준으로 PG 전표 발행, 세금계산서는 사용 시점에 발행
    // 공급가액 = price_krw × 10/11 (원 미만 절사)
    // 부가세 = price_krw - 공급가액
    const supplyAmountKrw = Math.floor(priceKrw * 10 / 11)
    const vatAmountKrw = priceKrw - supplyAmountKrw

    // Create pending purchase record
    const { data: purchase, error: purchaseError } = await supabase
      .from('dt_purchases')
      .insert({
        user_id: userId,
        package_id: packageId,
        dt_amount: pkg.dt,
        bonus_dt: pkg.bonus,
        price_krw: priceKrw,
        supply_amount_krw: supplyAmountKrw,
        vat_amount_krw: vatAmountKrw,
        payment_method: paymentMethod,
        payment_provider: `tosspayments|${platformKey}`, // Audit trail: PG|platform
        status: 'pending',
        refund_eligible_until: refundEligibleUntil,
      })
      .select()
      .single()

    if (purchaseError) {
      console.error('Failed to create purchase:', purchaseError)
      return new Response(
        JSON.stringify({ error: 'Failed to create purchase order' }),
        { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // --- TossPayments Checkout Integration ---
    const tossSecretKey = Deno.env.get('TOSSPAYMENTS_SECRET_KEY') ?? ''
    const appBaseUrl = Deno.env.get('APP_BASE_URL') ?? ''

    if (!tossSecretKey) {
      // Env var not configured: mark purchase as failed, return error
      console.error('[Checkout] TOSSPAYMENTS_SECRET_KEY not configured')
      await supabase
        .from('dt_purchases')
        .update({ status: 'failed' })
        .eq('id', purchase.id)

      return new Response(
        JSON.stringify({ error: 'Payment provider not configured' }),
        { status: 503, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Call TossPayments Create Payment API
    const tossAuth = btoa(`${tossSecretKey}:`)
    const tossBody = {
      method: 'CARD',
      amount: priceKrw,
      currency: 'KRW',
      orderId: purchase.id,
      orderName: pkg.name,
      successUrl: `${appBaseUrl}/payment/success`,
      failUrl: `${appBaseUrl}/payment/fail`,
    }

    const tossRes = await fetch('https://api.tosspayments.com/v1/payments', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${tossAuth}`,
        'Content-Type': 'application/json',
        'Idempotency-Key': `checkout:${purchase.id}`,
      },
      body: JSON.stringify(tossBody),
    })

    if (!tossRes.ok) {
      const tossErr = await tossRes.json().catch(() => ({}))
      console.error('[Checkout] Toss API error:', tossRes.status, tossErr)

      // Mark purchase as failed
      await supabase
        .from('dt_purchases')
        .update({ status: 'failed' })
        .eq('id', purchase.id)

      return new Response(
        JSON.stringify({
          error: 'Payment session creation failed',
          detail: tossErr.message ?? 'Unknown PG error',
        }),
        { status: 502, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    const tossData = await tossRes.json()

    // S-P1-1: Cross-verify amount returned by PG matches our request
    if (tossData.totalAmount != null && tossData.totalAmount !== priceKrw) {
      console.error(
        `[Checkout] Amount mismatch: requested=${priceKrw}, PG returned=${tossData.totalAmount}`
      )
      await supabase
        .from('dt_purchases')
        .update({ status: 'failed' })
        .eq('id', purchase.id)

      return new Response(
        JSON.stringify({ error: 'Payment amount verification failed' }),
        { status: 502, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    const checkoutUrl = tossData.checkout?.url ?? tossData.url ?? ''

    if (!checkoutUrl) {
      console.error('[Checkout] No checkout URL in Toss response:', tossData)
      await supabase
        .from('dt_purchases')
        .update({ status: 'failed' })
        .eq('id', purchase.id)

      return new Response(
        JSON.stringify({ error: 'No checkout URL returned from payment provider' }),
        { status: 502, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Return checkout information
    return new Response(
      JSON.stringify({
        success: true,
        purchaseId: purchase.id,
        checkoutUrl: checkoutUrl,
        package: {
          id: packageId,
          name: pkg.name,
          dtAmount: pkg.dt,
          bonusDt: pkg.bonus,
          totalDt: pkg.dt + pkg.bonus,
          priceKrw: priceKrw,
          platform: platformKey,
        },
        expiresAt: new Date(Date.now() + 30 * 60 * 1000).toISOString(), // 30 minutes
      }),
      {
        status: 200,
        headers: { ...getCorsHeaders(req), ...jsonHeaders },
      }
    )
  } catch (error) {
    console.error('Payment checkout error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }
})
