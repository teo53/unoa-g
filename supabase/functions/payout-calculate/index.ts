// Payout Calculate Edge Function
// Monthly job to calculate creator payouts with Korean tax withholding
// Scheduled to run on the 1st of each month

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Korean withholding tax rates
const TAX_RATES = {
  // 기타소득세 3% + 지방소득세 0.3% = 3.3%
  individual: 0.033,
  // 사업자는 별도 세율 적용 가능
  business: 0.033,
}

// Platform fee
const PLATFORM_FEE_RATE = 0.20 // 20%

// Minimum payout threshold in KRW
const MINIMUM_PAYOUT_KRW = 10000 // 10,000 KRW

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Calculate period (previous month)
    const now = new Date()
    const periodEnd = new Date(now.getFullYear(), now.getMonth(), 0) // Last day of previous month
    const periodStart = new Date(periodEnd.getFullYear(), periodEnd.getMonth(), 1) // First day of previous month

    console.log(`Calculating payouts for period: ${periodStart.toISOString().split('T')[0]} to ${periodEnd.toISOString().split('T')[0]}`)

    // Get all verified creators
    const { data: creators, error: creatorsError } = await supabase
      .from('creator_profiles')
      .select(`
        *,
        payout_settings (*)
      `)
      .eq('payout_verified', true)

    if (creatorsError) {
      console.error('Failed to fetch creators:', creatorsError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch creators' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const results = {
      processed: 0,
      created: 0,
      skipped: 0,
      errors: 0,
      payouts: [] as any[],
    }

    for (const creator of creators || []) {
      try {
        results.processed++

        // Check for existing payout in this period
        const { data: existingPayout } = await supabase
          .from('payouts')
          .select('id')
          .eq('creator_id', creator.user_id)
          .eq('period_start', periodStart.toISOString().split('T')[0])
          .eq('period_end', periodEnd.toISOString().split('T')[0])
          .not('status', 'in', '("cancelled","failed")')
          .single()

        if (existingPayout) {
          console.log(`Payout already exists for creator ${creator.user_id}`)
          results.skipped++
          continue
        }

        // Calculate earnings from tips/donations
        const { data: donations, error: donationsError } = await supabase
          .from('dt_donations')
          .select('amount_dt, creator_share_dt, platform_fee_dt')
          .eq('to_creator_id', creator.user_id)
          .gte('created_at', periodStart.toISOString())
          .lte('created_at', periodEnd.toISOString())

        if (donationsError) {
          console.error(`Failed to fetch donations for creator ${creator.user_id}:`, donationsError)
          results.errors++
          continue
        }

        // Calculate earnings from private card sales
        const { data: cardSales, error: cardSalesError } = await supabase
          .from('private_card_purchases')
          .select(`
            price_paid_dt,
            private_cards!inner (creator_id)
          `)
          .eq('private_cards.creator_id', creator.user_id)
          .gte('created_at', periodStart.toISOString())
          .lte('created_at', periodEnd.toISOString())

        if (cardSalesError) {
          console.error(`Failed to fetch card sales for creator ${creator.user_id}:`, cardSalesError)
          // Continue with just donations
        }

        // Sum up earnings
        const tipTotal = donations?.reduce((sum, d) => sum + (d.creator_share_dt || 0), 0) || 0
        const cardTotal = cardSales?.reduce((sum, s) => {
          const creatorShare = Math.floor(s.price_paid_dt * (1 - PLATFORM_FEE_RATE))
          return sum + creatorShare
        }, 0) || 0

        const grossDt = tipTotal + cardTotal

        if (grossDt === 0) {
          console.log(`No earnings for creator ${creator.user_id}`)
          results.skipped++
          continue
        }

        // Convert to KRW (1 DT = 100 KRW)
        const grossKrw = grossDt * 100

        // Calculate platform fee (already deducted for donations, need for cards)
        const platformFeeKrw = Math.floor(grossKrw * PLATFORM_FEE_RATE)

        // Get tax rate
        const taxType = creator.payout_settings?.tax_type || creator.tax_type || 'individual'
        const withholdingRate = creator.payout_settings?.withholding_tax_rate ||
                               creator.withholding_tax_rate ||
                               TAX_RATES[taxType as keyof typeof TAX_RATES] ||
                               TAX_RATES.individual

        // Calculate withholding tax (3.3% of taxable income)
        const taxableKrw = grossKrw - platformFeeKrw
        const withholdingTaxKrw = Math.floor(taxableKrw * withholdingRate)

        // Calculate net payout
        const netKrw = grossKrw - platformFeeKrw - withholdingTaxKrw

        // Check minimum threshold
        const minimumPayout = creator.payout_settings?.minimum_payout_krw || MINIMUM_PAYOUT_KRW

        if (netKrw < minimumPayout) {
          console.log(`Creator ${creator.user_id} below minimum threshold: ${netKrw} < ${minimumPayout}`)
          results.skipped++
          continue
        }

        // Get bank info
        const { data: bankInfo } = await supabase
          .from('bank_codes')
          .select('name')
          .eq('code', creator.bank_code)
          .single()

        // Create payout record
        const { data: payout, error: payoutError } = await supabase
          .from('payouts')
          .insert({
            creator_id: creator.user_id,
            creator_profile_id: creator.id,
            period_start: periodStart.toISOString().split('T')[0],
            period_end: periodEnd.toISOString().split('T')[0],
            gross_dt: grossDt,
            gross_krw: grossKrw,
            platform_fee_rate: PLATFORM_FEE_RATE,
            platform_fee_krw: platformFeeKrw,
            withholding_tax_rate: withholdingRate,
            withholding_tax_krw: withholdingTaxKrw,
            net_krw: netKrw,
            bank_code: creator.bank_code || '',
            bank_name: bankInfo?.name || '',
            bank_account_last4: creator.bank_account_number?.slice(-4) || '****',
            account_holder_name: creator.account_holder_name || '',
            status: 'pending_review',
          })
          .select()
          .single()

        if (payoutError) {
          console.error(`Failed to create payout for creator ${creator.user_id}:`, payoutError)
          results.errors++
          continue
        }

        // Create line items
        const lineItems = []

        if (tipTotal > 0) {
          lineItems.push({
            payout_id: payout.id,
            item_type: 'tip',
            item_count: donations?.length || 0,
            gross_dt: tipTotal,
            gross_krw: tipTotal * 100,
          })
        }

        if (cardTotal > 0) {
          lineItems.push({
            payout_id: payout.id,
            item_type: 'private_card',
            item_count: cardSales?.length || 0,
            gross_dt: cardTotal,
            gross_krw: cardTotal * 100,
          })
        }

        if (lineItems.length > 0) {
          await supabase.from('payout_line_items').insert(lineItems)
        }

        console.log(`Created payout for creator ${creator.user_id}: ${netKrw} KRW`)

        results.created++
        results.payouts.push({
          creatorId: creator.user_id,
          payoutId: payout.id,
          grossKrw,
          platformFeeKrw,
          withholdingTaxKrw,
          netKrw,
        })
      } catch (error) {
        console.error(`Error processing creator ${creator.user_id}:`, error)
        results.errors++
      }
    }

    console.log('Payout calculation complete:', results)

    return new Response(
      JSON.stringify({
        success: true,
        period: {
          start: periodStart.toISOString().split('T')[0],
          end: periodEnd.toISOString().split('T')[0],
        },
        results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Payout calculation error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
