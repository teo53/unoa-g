// =====================================================
// Edge Function: campaign-complete
// Purpose: 종료일 경과 캠페인 자동 완료 + 실패 환불
// Schedule: 매일 1회 실행 (cron or manual trigger)
//
// 처리 흐름:
//   1. end_at < now() && status = 'active' 캠페인 조회
//   2. 각 캠페인을 'completed'로 변경
//   3. 목표 미달 → refund_failed_campaign_pledges() 호출
//   4. 목표 달성 → 로그 기록 (정산은 payout-calculate에서)
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CampaignResult {
  campaignId: string
  title: string
  status: 'succeeded' | 'failed_refunded' | 'error'
  goalAmountDt: number
  currentAmountDt: number
  backerCount: number
  refundResult?: Record<string, unknown>
  error?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    console.log('Starting campaign completion check...')

    // 1. 종료일 경과한 active 캠페인 조회
    const { data: expiredCampaigns, error: queryError } = await supabase
      .from('funding_campaigns')
      .select('id, title, goal_amount_dt, current_amount_dt, backer_count, end_at, creator_id')
      .eq('status', 'active')
      .not('end_at', 'is', null)
      .lt('end_at', new Date().toISOString())

    if (queryError) {
      console.error('Failed to query expired campaigns:', queryError)
      return new Response(
        JSON.stringify({ error: 'Failed to query campaigns', details: queryError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!expiredCampaigns || expiredCampaigns.length === 0) {
      console.log('No expired campaigns found.')
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No expired campaigns to process',
          results: { completed: 0, succeeded: 0, refunded: 0 },
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Found ${expiredCampaigns.length} expired campaign(s) to process`)

    const results: CampaignResult[] = []
    let succeededCount = 0
    let refundedCount = 0
    let errorCount = 0

    // 2. 각 캠페인 처리
    for (const campaign of expiredCampaigns) {
      try {
        const goalReached = campaign.goal_amount_dt > 0 &&
          campaign.current_amount_dt >= campaign.goal_amount_dt

        // 캠페인 상태를 completed로 변경
        const { error: updateError } = await supabase
          .from('funding_campaigns')
          .update({
            status: 'completed',
            completed_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          })
          .eq('id', campaign.id)
          .eq('status', 'active') // 낙관적 잠금

        if (updateError) {
          console.error(`Failed to complete campaign ${campaign.id}:`, updateError)
          results.push({
            campaignId: campaign.id,
            title: campaign.title,
            status: 'error',
            goalAmountDt: campaign.goal_amount_dt,
            currentAmountDt: campaign.current_amount_dt,
            backerCount: campaign.backer_count,
            error: updateError.message,
          })
          errorCount++
          continue
        }

        if (goalReached) {
          // 목표 달성 → 정산 대기 (payout-calculate에서 처리)
          console.log(
            `Campaign ${campaign.id} succeeded: ${campaign.current_amount_dt}/${campaign.goal_amount_dt} DT`
          )
          results.push({
            campaignId: campaign.id,
            title: campaign.title,
            status: 'succeeded',
            goalAmountDt: campaign.goal_amount_dt,
            currentAmountDt: campaign.current_amount_dt,
            backerCount: campaign.backer_count,
          })
          succeededCount++
        } else {
          // 목표 미달 → 환불 처리
          console.log(
            `Campaign ${campaign.id} failed: ${campaign.current_amount_dt}/${campaign.goal_amount_dt} DT. Processing refunds...`
          )

          const { data: refundResult, error: refundError } = await supabase.rpc(
            'refund_failed_campaign_pledges',
            { p_campaign_id: campaign.id }
          )

          if (refundError) {
            console.error(`Refund failed for campaign ${campaign.id}:`, refundError)
            results.push({
              campaignId: campaign.id,
              title: campaign.title,
              status: 'error',
              goalAmountDt: campaign.goal_amount_dt,
              currentAmountDt: campaign.current_amount_dt,
              backerCount: campaign.backer_count,
              error: `Refund error: ${refundError.message}`,
            })
            errorCount++
          } else {
            console.log(
              `Refunds processed for campaign ${campaign.id}:`,
              JSON.stringify(refundResult)
            )
            results.push({
              campaignId: campaign.id,
              title: campaign.title,
              status: 'failed_refunded',
              goalAmountDt: campaign.goal_amount_dt,
              currentAmountDt: campaign.current_amount_dt,
              backerCount: campaign.backer_count,
              refundResult: refundResult as Record<string, unknown>,
            })
            refundedCount++
          }
        }
      } catch (error) {
        console.error(`Error processing campaign ${campaign.id}:`, error)
        results.push({
          campaignId: campaign.id,
          title: campaign.title,
          status: 'error',
          goalAmountDt: campaign.goal_amount_dt,
          currentAmountDt: campaign.current_amount_dt,
          backerCount: campaign.backer_count,
          error: String(error),
        })
        errorCount++
      }
    }

    console.log(
      `Campaign completion done: ${succeededCount} succeeded, ${refundedCount} refunded, ${errorCount} errors`
    )

    return new Response(
      JSON.stringify({
        success: true,
        summary: {
          total: expiredCampaigns.length,
          succeeded: succeededCount,
          refunded: refundedCount,
          errors: errorCount,
        },
        results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Campaign completion error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: String(error) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
