// Funding Pledge Edge Function
// Processes funding pledges with DT wallet deduction
// Implements atomic transactions with idempotency
//
// SECURITY:
// - Requires authenticated user
// - Validates campaign status and end date
// - Validates tier availability
// - Atomic transaction: wallet deduction + pledge creation + stats update

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PledgeRequest {
  campaignId: string
  tierId?: string
  amountDt: number
  extraSupportDt?: number
  idempotencyKey: string
  isAnonymous?: boolean
  supportMessage?: string
}

interface PledgeResponse {
  success: boolean
  pledgeId?: string
  newBalance?: number
  message?: string
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow POST
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ success: false, error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    // Get auth token from header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client with user's auth token
    const supabaseUser = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    })

    // Verify user
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid authentication' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const body: PledgeRequest = await req.json()
    const {
      campaignId,
      tierId,
      amountDt,
      extraSupportDt = 0,
      idempotencyKey,
      isAnonymous = false,
      supportMessage,
    } = body

    // Validate required fields
    if (!campaignId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign ID is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!amountDt || amountDt <= 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Amount must be greater than 0' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!idempotencyKey) {
      return new Response(
        JSON.stringify({ success: false, error: 'Idempotency key is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create admin client for database operations
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Check idempotency - return existing pledge if already processed
    const { data: existingPledge } = await supabaseAdmin
      .from('funding_pledges')
      .select('id, status, total_amount_dt')
      .eq('idempotency_key', idempotencyKey)
      .single()

    if (existingPledge) {
      // Get current wallet balance
      const { data: wallet } = await supabaseAdmin
        .from('wallets')
        .select('balance_dt')
        .eq('user_id', user.id)
        .single()

      return new Response(
        JSON.stringify({
          success: true,
          pledgeId: existingPledge.id,
          newBalance: wallet?.balance_dt ?? 0,
          message: 'Pledge already processed',
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate campaign exists and is active
    const { data: campaign, error: campaignError } = await supabaseAdmin
      .from('funding_campaigns')
      .select('id, status, end_at, creator_id, current_amount_dt, backer_count')
      .eq('id', campaignId)
      .single()

    if (campaignError || !campaign) {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check campaign is active
    if (campaign.status !== 'active') {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign is not active' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check campaign has not ended
    if (campaign.end_at && new Date(campaign.end_at) < new Date()) {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign has ended' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check user is not the creator
    if (campaign.creator_id === user.id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Cannot pledge to your own campaign' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate tier if provided
    let tier = null
    if (tierId) {
      const { data: tierData, error: tierError } = await supabaseAdmin
        .from('funding_reward_tiers')
        .select('id, price_dt, is_active, remaining_quantity, pledge_count')
        .eq('id', tierId)
        .eq('campaign_id', campaignId)
        .single()

      if (tierError || !tierData) {
        return new Response(
          JSON.stringify({ success: false, error: 'Reward tier not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (!tierData.is_active) {
        return new Response(
          JSON.stringify({ success: false, error: 'Reward tier is not available' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Check tier availability (quantity)
      if (tierData.remaining_quantity !== null && tierData.remaining_quantity <= 0) {
        return new Response(
          JSON.stringify({ success: false, error: 'Reward tier is sold out' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Validate amount matches tier price
      if (amountDt < tierData.price_dt) {
        return new Response(
          JSON.stringify({
            success: false,
            error: `Amount must be at least ${tierData.price_dt} DT for this tier`,
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      tier = tierData
    }

    // Calculate total amount
    const totalAmountDt = amountDt + extraSupportDt

    // Get user's wallet
    const { data: wallet, error: walletError } = await supabaseAdmin
      .from('wallets')
      .select('id, balance_dt')
      .eq('user_id', user.id)
      .single()

    if (walletError || !wallet) {
      return new Response(
        JSON.stringify({ success: false, error: 'Wallet not found. Please top up your DT balance.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check sufficient balance
    if (wallet.balance_dt < totalAmountDt) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Insufficient DT balance',
          message: `You need ${totalAmountDt} DT but only have ${wallet.balance_dt} DT`,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Execute atomic transaction using RPC
    const { data: result, error: txError } = await supabaseAdmin.rpc('process_funding_pledge', {
      p_campaign_id: campaignId,
      p_tier_id: tierId || null,
      p_user_id: user.id,
      p_wallet_id: wallet.id,
      p_amount_dt: amountDt,
      p_extra_support_dt: extraSupportDt,
      p_idempotency_key: idempotencyKey,
      p_is_anonymous: isAnonymous,
      p_support_message: supportMessage || null,
    })

    if (txError) {
      console.error('Transaction error:', txError)

      // Check for specific errors
      if (txError.message?.includes('insufficient_balance')) {
        return new Response(
          JSON.stringify({ success: false, error: 'Insufficient DT balance' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (txError.message?.includes('tier_sold_out')) {
        return new Response(
          JSON.stringify({ success: false, error: 'Reward tier is sold out' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (txError.message?.includes('campaign_not_active')) {
        return new Response(
          JSON.stringify({ success: false, error: 'Campaign is no longer active' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({ success: false, error: 'Failed to process pledge. Please try again.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const response: PledgeResponse = {
      success: true,
      pledgeId: result.pledge_id,
      newBalance: result.new_balance,
      message: 'Pledge successful!',
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Funding pledge error:', error)
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
