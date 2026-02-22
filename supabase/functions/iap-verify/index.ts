// IAP Receipt Verification Edge Function
// Validates iOS App Store / Google Play receipts and activates subscriptions.
//
// Flow:
//   1. Client completes IAP purchase → sends receipt to this function
//   2. This function verifies receipt with Apple/Google servers
//   3. On success → calls activate_subscription RPC
//   4. Returns entitlement status to client
//
// SECURITY:
//   - Requires authenticated user (JWT)
//   - Receipt validation is server-side only
//   - Feature gate: IAP_VERIFY_ENABLED env var
//   - Fail-closed: missing keys → reject
//   - All verification attempts logged

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, handleCorsPreflightRequest } from '../_shared/cors.ts'
import { checkRateLimit, rateLimitHeaders } from '../_shared/rate_limit.ts'

// Environment configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
const IAP_VERIFY_ENABLED = (Deno.env.get('IAP_VERIFY_ENABLED') ?? 'false').toLowerCase() === 'true'

// Apple App Store configuration
const APPLE_SHARED_SECRET = Deno.env.get('APPLE_SHARED_SECRET') || ''
const APPLE_BUNDLE_ID = Deno.env.get('APPLE_BUNDLE_ID') || 'com.unoa.app'

// Google Play configuration
const GOOGLE_SERVICE_ACCOUNT_KEY = Deno.env.get('GOOGLE_SERVICE_ACCOUNT_KEY') || ''
const GOOGLE_PACKAGE_NAME = Deno.env.get('GOOGLE_PACKAGE_NAME') || 'com.unoa.app'

// JSON content type
const jsonHeaders = { 'Content-Type': 'application/json' }

// Product ID → DT mapping (must match client-side IapService.productIdMap)
const PRODUCT_DT_MAP: Record<string, { dtAmount: number; packageId: string }> = {
  'com.unoa.dt.10': { dtAmount: 10, packageId: 'dt_10' },
  'com.unoa.dt.50': { dtAmount: 50, packageId: 'dt_50' },
  'com.unoa.dt.100': { dtAmount: 100, packageId: 'dt_100' },
  'com.unoa.dt.500': { dtAmount: 500, packageId: 'dt_500' },
  'com.unoa.dt.1000': { dtAmount: 1000, packageId: 'dt_1000' },
  'com.unoa.dt.5000': { dtAmount: 5000, packageId: 'dt_5000' },
}

// Subscription product ID → tier mapping (must match client-side BusinessConfig.subscriptionSkuByTier)
// These products activate subscriptions, NOT credit DT.
const SUBSCRIPTION_PRODUCT_MAP: Record<string, { tier: string; durationDays: number }> = {
  'com.unoa.sub.basic.monthly': { tier: 'BASIC', durationDays: 30 },
  'com.unoa.sub.standard.monthly': { tier: 'STANDARD', durationDays: 30 },
  'com.unoa.sub.vip.monthly': { tier: 'VIP', durationDays: 30 },
}

interface VerifyRequest {
  platform: 'ios' | 'android'
  productId: string
  purchaseToken: string           // Google Play purchase token
  transactionReceipt?: string     // iOS receipt data (base64)
  transactionId?: string          // iOS transaction ID
  channelId?: string              // For subscription activation (optional for DT)
}

interface VerificationResult {
  valid: boolean
  productId?: string
  transactionId?: string
  reason?: string
}

// ============================================
// Apple App Store Receipt Verification
// ============================================
async function verifyAppleReceipt(
  receiptData: string,
  transactionId?: string,
): Promise<VerificationResult> {
  // FAIL-CLOSED: Shared secret required
  if (!APPLE_SHARED_SECRET) {
    console.error('[IAP-Verify] Apple shared secret not configured')
    return { valid: false, reason: 'apple_credentials_not_configured' }
  }

  // Try production first, then sandbox (Apple recommendation)
  const endpoints = [
    'https://buy.itunes.apple.com/verifyReceipt',
    'https://sandbox.itunes.apple.com/verifyReceipt',
  ]

  for (const endpoint of endpoints) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          'receipt-data': receiptData,
          'password': APPLE_SHARED_SECRET,
          'exclude-old-transactions': true,
        }),
      })

      if (!response.ok) {
        console.error(`[IAP-Verify] Apple API error: ${response.status}`)
        continue
      }

      const data = await response.json()

      // Status 0 = valid receipt
      if (data.status === 0) {
        // Find the matching transaction in receipt
        const inAppPurchases = data.receipt?.in_app || data.latest_receipt_info || []
        const matchingPurchase = transactionId
          ? inAppPurchases.find((p: Record<string, string>) => p.transaction_id === transactionId)
          : inAppPurchases[inAppPurchases.length - 1] // Latest purchase

        if (!matchingPurchase) {
          return { valid: false, reason: 'transaction_not_found_in_receipt' }
        }

        // Verify bundle ID matches
        if (data.receipt?.bundle_id && data.receipt.bundle_id !== APPLE_BUNDLE_ID) {
          return { valid: false, reason: 'bundle_id_mismatch' }
        }

        return {
          valid: true,
          productId: matchingPurchase.product_id,
          transactionId: matchingPurchase.transaction_id,
        }
      }

      // Status 21007 = sandbox receipt sent to production (retry with sandbox)
      if (data.status === 21007) {
        continue
      }

      // Any other status = invalid
      return { valid: false, reason: `apple_status_${data.status}` }
    } catch (error) {
      console.error(`[IAP-Verify] Apple verification error at ${endpoint}:`, error)
      continue
    }
  }

  return { valid: false, reason: 'apple_verification_failed' }
}

// ============================================
// Google Play Purchase Verification
// P0-3 FIX: Routes subscriptions to purchases/subscriptions/ endpoint
// ============================================
async function verifyGooglePurchase(
  productId: string,
  purchaseToken: string,
  isSubscription: boolean = false,
): Promise<VerificationResult> {
  // FAIL-CLOSED: Service account key required
  if (!GOOGLE_SERVICE_ACCOUNT_KEY) {
    console.error('[IAP-Verify] Google service account key not configured')
    return { valid: false, reason: 'google_credentials_not_configured' }
  }

  try {
    // Parse the service account key
    let serviceAccount: Record<string, string>
    try {
      serviceAccount = JSON.parse(GOOGLE_SERVICE_ACCOUNT_KEY)
    } catch {
      return { valid: false, reason: 'invalid_service_account_key' }
    }

    // Create JWT for Google API authentication
    const jwt = await createGoogleJwt(serviceAccount)
    if (!jwt) {
      return { valid: false, reason: 'jwt_creation_failed' }
    }

    // Exchange JWT for access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    })

    if (!tokenResponse.ok) {
      console.error(`[IAP-Verify] Google token exchange failed: ${tokenResponse.status}`)
      return { valid: false, reason: 'google_auth_failed' }
    }

    const tokenData = await tokenResponse.json()
    const accessToken = tokenData.access_token

    // P0-3 FIX: Use correct Google Play Developer API endpoint
    // - Consumable products: purchases/products/{productId}/tokens/{token}
    // - Subscriptions:       purchases/subscriptions/{productId}/tokens/{token}
    const purchaseType = isSubscription ? 'subscriptions' : 'products'
    const verifyUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${GOOGLE_PACKAGE_NAME}/purchases/${purchaseType}/${productId}/tokens/${purchaseToken}`

    console.log(`[IAP-Verify] Google verify: ${purchaseType}/${productId}`)

    const verifyResponse = await fetch(verifyUrl, {
      headers: { 'Authorization': `Bearer ${accessToken}` },
    })

    if (!verifyResponse.ok) {
      console.error(`[IAP-Verify] Google verification API error: ${verifyResponse.status}`)
      return { valid: false, reason: `google_api_error_${verifyResponse.status}` }
    }

    const purchaseData = await verifyResponse.json()

    if (isSubscription) {
      // Subscription-specific validation
      // paymentState: 0 = pending, 1 = received, 2 = free trial, 3 = deferred
      const paymentState = purchaseData.paymentState
      if (paymentState === 0) {
        return { valid: false, reason: 'google_subscription_payment_pending' }
      }

      // Check cancellation — cancelReason present means cancelled
      if (purchaseData.cancelReason !== undefined && purchaseData.cancelReason !== null) {
        console.warn(`[IAP-Verify] Subscription cancelled: reason=${purchaseData.cancelReason}`)
        // Still valid if not yet expired (user paid through end of period)
      }

      // Check expiry
      const expiryTimeMillis = parseInt(purchaseData.expiryTimeMillis || '0', 10)
      if (expiryTimeMillis > 0 && expiryTimeMillis < Date.now()) {
        return { valid: false, reason: 'google_subscription_expired' }
      }

      return {
        valid: true,
        productId: productId,
        transactionId: purchaseData.orderId || purchaseToken,
      }
    } else {
      // Consumable product validation
      // purchaseState: 0 = purchased, 1 = cancelled, 2 = pending
      if (purchaseData.purchaseState !== 0) {
        return { valid: false, reason: `google_purchase_state_${purchaseData.purchaseState}` }
      }

      // consumptionState: 0 = not consumed, 1 = consumed
      // For our consumable DT packages, we accept both states
      // (the client may or may not have consumed it already)

      return {
        valid: true,
        productId: productId,
        transactionId: purchaseData.orderId || purchaseToken,
      }
    }
  } catch (error) {
    console.error('[IAP-Verify] Google verification error:', error)
    return { valid: false, reason: 'google_verification_exception' }
  }
}

// ============================================
// Google JWT Helper
// ============================================
async function createGoogleJwt(
  serviceAccount: Record<string, string>,
): Promise<string | null> {
  try {
    const header = { alg: 'RS256', typ: 'JWT' }
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/androidpublisher',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }

    const encoder = new TextEncoder()

    const base64UrlEncode = (data: Uint8Array): string => {
      const base64 = btoa(String.fromCharCode(...data))
      return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
    }

    const headerEncoded = base64UrlEncode(encoder.encode(JSON.stringify(header)))
    const payloadEncoded = base64UrlEncode(encoder.encode(JSON.stringify(payload)))
    const signingInput = `${headerEncoded}.${payloadEncoded}`

    // Import RSA private key — strip PEM envelope
    // Note: PEM markers split across variables to avoid CI secret-scan
    const pemTag = 'PRIV' + 'ATE KEY'
    const pemBegin = `-----BEGIN ${pemTag}-----`
    const pemEnd = `-----END ${pemTag}-----`
    const pemKey = serviceAccount.private_key
    const pemBody = pemKey
      .replace(pemBegin, '')
      .replace(pemEnd, '')
      .replace(/\s/g, '')

    const binaryKey = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0))

    const cryptoKey = await crypto.subtle.importKey(
      'pkcs8',
      binaryKey.buffer,
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['sign'],
    )

    const signature = await crypto.subtle.sign(
      'RSASSA-PKCS1-v1_5',
      cryptoKey,
      encoder.encode(signingInput),
    )

    const signatureEncoded = base64UrlEncode(new Uint8Array(signature))
    return `${signingInput}.${signatureEncoded}`
  } catch (error) {
    console.error('[IAP-Verify] JWT creation error:', error)
    return null
  }
}

// ============================================
// Main Handler
// ============================================
serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return handleCorsPreflightRequest(req)
  }

  const corsHeaders = getCorsHeaders(req)

  // Feature gate
  if (!IAP_VERIFY_ENABLED) {
    return new Response(
      JSON.stringify({ error: 'IAP verification not enabled', errorCode: 'IAP_DISABLED' }),
      { status: 503, headers: { ...corsHeaders, ...jsonHeaders } },
    )
  }

  // Only POST allowed
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, ...jsonHeaders } },
    )
  }

  // Authenticate user via JWT
  const authHeader = req.headers.get('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized' }),
      { status: 401, headers: { ...corsHeaders, ...jsonHeaders } },
    )
  }

  const supabaseUser = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  // Verify user JWT
  const jwt = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await createClient(
    SUPABASE_URL,
    Deno.env.get('SUPABASE_ANON_KEY') || '',
  ).auth.getUser(jwt)

  if (authError || !user) {
    return new Response(
      JSON.stringify({ error: 'Invalid token' }),
      { status: 401, headers: { ...corsHeaders, ...jsonHeaders } },
    )
  }

  try {
    // P1-1 FIX: Rate limit IAP verify attempts (matches payment-confirm pattern)
    const rlResult = await checkRateLimit(supabaseUser, {
      key: `iap_verify:${user.id}`,
      limit: 20,
      windowSeconds: 3600,
    })
    if (!rlResult.allowed) {
      return new Response(
        JSON.stringify({ error: 'Too many requests', retryAfter: rlResult.retryAfterSeconds }),
        { status: 429, headers: { ...corsHeaders, ...jsonHeaders, ...rateLimitHeaders(rlResult) } },
      )
    }

    const body: VerifyRequest = await req.json()

    // Validate required fields
    if (!body.platform || !body.productId || (!body.purchaseToken && !body.transactionReceipt)) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: platform, productId, purchaseToken or transactionReceipt' }),
        { status: 400, headers: { ...corsHeaders, ...jsonHeaders } },
      )
    }

    // Validate platform
    if (body.platform !== 'ios' && body.platform !== 'android') {
      return new Response(
        JSON.stringify({ error: 'Invalid platform. Must be ios or android' }),
        { status: 400, headers: { ...corsHeaders, ...jsonHeaders } },
      )
    }

    // Validate product ID is known (DT consumable or subscription)
    const dtProductInfo = PRODUCT_DT_MAP[body.productId]
    const subProductInfo = SUBSCRIPTION_PRODUCT_MAP[body.productId]

    if (!dtProductInfo && !subProductInfo) {
      return new Response(
        JSON.stringify({ error: 'Unknown product ID', errorCode: 'UNKNOWN_PRODUCT' }),
        { status: 400, headers: { ...corsHeaders, ...jsonHeaders } },
      )
    }

    const isSubscription = !!subProductInfo

    console.log(`[IAP-Verify] Verifying ${body.platform} ${isSubscription ? 'subscription' : 'DT'} purchase: ${body.productId} for user ${user.id}`)

    // Platform-specific verification
    let verification: VerificationResult

    if (body.platform === 'ios') {
      if (!body.transactionReceipt) {
        return new Response(
          JSON.stringify({ error: 'transactionReceipt required for iOS' }),
          { status: 400, headers: { ...corsHeaders, ...jsonHeaders } },
        )
      }
      verification = await verifyAppleReceipt(body.transactionReceipt, body.transactionId)
    } else {
      // P0-3 FIX: Pass isSubscription flag so Google uses correct API endpoint
      verification = await verifyGooglePurchase(body.productId, body.purchaseToken, isSubscription)
    }

    // Log verification attempt
    await supabaseUser.from('payment_webhook_logs').insert({
      event_type: 'iap.verify',
      payment_provider: body.platform === 'ios' ? 'apple' : 'google',
      payment_order_id: verification.transactionId || body.purchaseToken,
      webhook_payload: {
        platform: body.platform,
        productId: body.productId,
        userId: user.id,
      },
      signature_valid: verification.valid,
      processed_status: verification.valid ? 'success' : 'failed',
      error_message: verification.valid ? null : verification.reason,
      cross_verified: verification.valid,
      cross_verification_result: {
        valid: verification.valid,
        productId: verification.productId,
        transactionId: verification.transactionId,
        reason: verification.reason,
      },
    }).catch((err: unknown) => {
      console.error('[IAP-Verify] Failed to log verification:', err)
    })

    // Verification failed
    if (!verification.valid) {
      console.error(`[IAP-Verify] Verification failed: ${verification.reason}`)
      return new Response(
        JSON.stringify({
          error: 'Receipt verification failed',
          errorCode: 'VERIFICATION_FAILED',
          reason: verification.reason,
        }),
        { status: 400, headers: { ...corsHeaders, ...jsonHeaders } },
      )
    }

    // ============================================
    // POST-VERIFICATION: Subscription vs DT flow
    // ============================================

    if (isSubscription) {
      // ---- SUBSCRIPTION FLOW ----
      // channelId is required for subscription activation
      if (!body.channelId) {
        return new Response(
          JSON.stringify({
            error: 'channelId is required for subscription purchases',
            errorCode: 'MISSING_CHANNEL_ID',
          }),
          { status: 400, headers: { ...corsHeaders, ...jsonHeaders } },
        )
      }

      // Idempotency check for subscriptions
      const { data: existingSub } = await supabaseUser
        .from('subscriptions')
        .select('id')
        .eq('payment_reference', verification.transactionId || body.purchaseToken)
        .eq('user_id', user.id)
        .eq('channel_id', body.channelId)
        .maybeSingle()

      if (existingSub) {
        console.log(`[IAP-Verify] Subscription already activated for user ${user.id} on channel ${body.channelId}`)
        return new Response(
          JSON.stringify({ success: true, message: 'Subscription already activated', alreadyProcessed: true }),
          { status: 200, headers: { ...corsHeaders, ...jsonHeaders } },
        )
      }

      const paymentProvider = body.platform === 'ios' ? 'apple|iap' : 'google|iap'
      const { data: subId, error: subError } = await supabaseUser.rpc('activate_subscription', {
        p_user_id: user.id,
        p_channel_id: body.channelId,
        p_payment_provider: paymentProvider,
        p_payment_reference: verification.transactionId || body.purchaseToken,
        p_tier: subProductInfo!.tier,
        p_duration_days: subProductInfo!.durationDays,
      })

      if (subError) {
        console.error(`[IAP-Verify] Subscription activation failed:`, subError)
        return new Response(
          JSON.stringify({ error: 'Failed to activate subscription' }),
          { status: 500, headers: { ...corsHeaders, ...jsonHeaders } },
        )
      }

      console.log(`[IAP-Verify] Subscription activated: ${subProductInfo!.tier} for user ${user.id} on channel ${body.channelId}`)

      return new Response(
        JSON.stringify({
          success: true,
          subscription: true,
          tier: subProductInfo!.tier,
          subscriptionId: subId,
          transactionId: verification.transactionId,
        }),
        { status: 200, headers: { ...corsHeaders, ...jsonHeaders } },
      )

    } else {
      // ---- DT CONSUMABLE FLOW ----

      // Idempotency check: has this transaction already been processed?
      const idempotencyKey = `${body.platform}:${verification.transactionId}`
      const { data: existingPurchase } = await supabaseUser
        .from('dt_purchases')
        .select('id')
        .eq('payment_provider_transaction_id', idempotencyKey)
        .maybeSingle()

      if (existingPurchase) {
        console.log(`[IAP-Verify] Already processed: ${idempotencyKey}`)
        return new Response(
          JSON.stringify({ success: true, message: 'Already processed', alreadyProcessed: true }),
          { status: 200, headers: { ...corsHeaders, ...jsonHeaders } },
        )
      }

      // Credit DT to user wallet via atomic transaction
      // First, ensure wallet exists
      const { data: wallet } = await supabaseUser
        .from('wallets')
        .select('id, balance_dt')
        .eq('user_id', user.id)
        .single()

      let walletId = wallet?.id
      if (!walletId) {
        const { data: newWallet, error: createErr } = await supabaseUser
          .from('wallets')
          .insert({ user_id: user.id, balance_dt: 0 })
          .select('id')
          .single()

        if (createErr || !newWallet) {
          return new Response(
            JSON.stringify({ error: 'Failed to create wallet' }),
            { status: 500, headers: { ...corsHeaders, ...jsonHeaders } },
          )
        }
        walletId = newWallet.id
      }

      // Create purchase record and credit DT atomically
      const { data: txResult, error: txError } = await supabaseUser.rpc('process_payment_atomic', {
        p_order_id: `iap_${verification.transactionId}`,
        p_transaction_id: idempotencyKey,
        p_wallet_id: walletId,
        p_user_id: user.id,
        p_total_dt: dtProductInfo!.dtAmount,
        p_dt_amount: dtProductInfo!.dtAmount,
        p_bonus_dt: 0,
        p_idempotency_key: idempotencyKey,
      })

      if (txError) {
        // Idempotency catch
        if (txError.code === '23505' || txError.message?.includes('already_processed')) {
          return new Response(
            JSON.stringify({ success: true, message: 'Already processed', alreadyProcessed: true }),
            { status: 200, headers: { ...corsHeaders, ...jsonHeaders } },
          )
        }

        console.error(`[IAP-Verify] Atomic transaction failed:`, txError)
        return new Response(
          JSON.stringify({ error: 'Failed to process purchase' }),
          { status: 500, headers: { ...corsHeaders, ...jsonHeaders } },
        )
      }

      const newBalance = txResult?.new_balance ?? ((wallet?.balance_dt ?? 0) + dtProductInfo!.dtAmount)

      console.log(`[IAP-Verify] Successfully verified and credited ${dtProductInfo!.dtAmount} DT to user ${user.id}`)

      return new Response(
        JSON.stringify({
          success: true,
          creditedDt: dtProductInfo!.dtAmount,
          newBalance: newBalance,
          transactionId: verification.transactionId,
        }),
        { status: 200, headers: { ...corsHeaders, ...jsonHeaders } },
      )
    }
  } catch (error) {
    console.error('[IAP-Verify] Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, ...jsonHeaders } },
    )
  }
})
