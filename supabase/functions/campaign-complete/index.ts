// =====================================================
// Edge Function: campaign-complete (KRW Version)
// Purpose: 종료일 경과 캠페인 자동 완료 + 실패 시 KRW 환불 큐 생성
// Schedule: 매일 1회 실행 (cron or manual trigger)
//
// 처리 흐름:
//   1. end_at < now() && status = 'active' 캠페인 조회
//   2. 각 캠페인을 'completed'로 변경
//   3. 목표 미달 → refund_failed_campaign_pledges() + queue_campaign_refunds()
//   4. 목표 달성 → 로그 기록 (정산은 payout-calculate에서)
//   5. 환불 큐 처리: PG사 환불 API 호출
//
// IMPORTANT: 펀딩 환불은 KRW (PG사 환불 API). DT 지갑 복원 아님!
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { requireCronAuth } from '../_shared/cron_auth.ts'

const PORTONE_API_SECRET = Deno.env.get('PORTONE_API_SECRET') || ''

const jsonHeaders = { 'Content-Type': 'application/json' }

interface CampaignResult {
  campaignId: string
  title: string
  status: 'succeeded' | 'refund_queued' | 'error'
  goalAmountKrw: number
  currentAmountKrw: number
  backerCount: number
  refundResult?: Record<string, unknown>
  queueResult?: Record<string, unknown>
  error?: string
}

/**
 * PortOne V2 결제 취소(환불) API 호출
 */
async function cancelPortOnePayment(
  paymentId: string,
  amount: number,
  reason: string,
): Promise<{ success: boolean; pgRefundId?: string; error?: string; response?: unknown }> {
  try {
    const response = await fetch(`https://api.portone.io/v2/payments/${paymentId}/cancel`, {
      method: 'POST',
      headers: {
        'Authorization': `PortOne ${PORTONE_API_SECRET}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount,
        reason,
      }),
    })

    const result = await response.json()

    if (!response.ok) {
      return { success: false, error: result.message || `HTTP ${response.status}`, response: result }
    }

    return {
      success: true,
      pgRefundId: result.cancellation?.id || result.pgCancellationId,
      response: result,
    }
  } catch (error) {
    return { success: false, error: String(error) }
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: jsonHeaders })
  }

  // SECURITY: Require cron secret for batch operations
  const authFail = requireCronAuth(req)
  if (authFail) return authFail

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    console.log('Starting campaign completion check (KRW mode)...')

    // 1. 종료일 경과한 active 캠페인 조회 (KRW 컬럼)
    const { data: expiredCampaigns, error: queryError } = await supabase
      .from('funding_campaigns')
      .select('id, title, goal_amount_krw, current_amount_krw, backer_count, end_at, creator_id')
      .eq('status', 'active')
      .not('end_at', 'is', null)
      .lt('end_at', new Date().toISOString())

    if (queryError) {
      console.error('Failed to query expired campaigns:', queryError)
      return new Response(
        JSON.stringify({ error: 'Failed to query campaigns', details: queryError.message }),
        { status: 500, headers: jsonHeaders }
      )
    }

    if (!expiredCampaigns || expiredCampaigns.length === 0) {
      console.log('No expired campaigns found.')
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No expired campaigns to process',
          results: { completed: 0, succeeded: 0, refundQueued: 0 },
        }),
        { status: 200, headers: jsonHeaders }
      )
    }

    console.log(`Found ${expiredCampaigns.length} expired campaign(s) to process`)

    const results: CampaignResult[] = []
    let succeededCount = 0
    let refundQueuedCount = 0
    let errorCount = 0

    // 2. 각 캠페인 처리
    for (const campaign of expiredCampaigns) {
      try {
        const goalReached = campaign.goal_amount_krw > 0 &&
          campaign.current_amount_krw >= campaign.goal_amount_krw

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
            goalAmountKrw: campaign.goal_amount_krw,
            currentAmountKrw: campaign.current_amount_krw,
            backerCount: campaign.backer_count,
            error: updateError.message,
          })
          errorCount++
          continue
        }

        if (goalReached) {
          // 목표 달성 → 정산 대기 (payout-calculate에서 처리)
          console.log(
            `Campaign ${campaign.id} succeeded: ${campaign.current_amount_krw.toLocaleString()}/${campaign.goal_amount_krw.toLocaleString()} KRW`
          )
          results.push({
            campaignId: campaign.id,
            title: campaign.title,
            status: 'succeeded',
            goalAmountKrw: campaign.goal_amount_krw,
            currentAmountKrw: campaign.current_amount_krw,
            backerCount: campaign.backer_count,
          })
          succeededCount++
        } else {
          // 목표 미달 → KRW 환불 처리
          console.log(
            `Campaign ${campaign.id} failed: ${campaign.current_amount_krw.toLocaleString()}/${campaign.goal_amount_krw.toLocaleString()} KRW. Queuing refunds...`
          )

          // Step 1: pledge 상태를 refund_pending으로 변경
          const { data: refundResult, error: refundError } = await supabase.rpc(
            'refund_failed_campaign_pledges',
            { p_campaign_id: campaign.id }
          )

          if (refundError) {
            console.error(`Refund marking failed for campaign ${campaign.id}:`, refundError)
            results.push({
              campaignId: campaign.id,
              title: campaign.title,
              status: 'error',
              goalAmountKrw: campaign.goal_amount_krw,
              currentAmountKrw: campaign.current_amount_krw,
              backerCount: campaign.backer_count,
              error: `Refund error: ${refundError.message}`,
            })
            errorCount++
            continue
          }

          // Step 2: 환불 큐에 추가 (PG사 환불은 아래에서 배치 처리)
          const { data: queueResult, error: queueError } = await supabase.rpc(
            'queue_campaign_refunds',
            { p_campaign_id: campaign.id }
          )

          if (queueError) {
            console.error(`Refund queue failed for campaign ${campaign.id}:`, queueError)
          }

          results.push({
            campaignId: campaign.id,
            title: campaign.title,
            status: 'refund_queued',
            goalAmountKrw: campaign.goal_amount_krw,
            currentAmountKrw: campaign.current_amount_krw,
            backerCount: campaign.backer_count,
            refundResult: refundResult as Record<string, unknown>,
            queueResult: queueResult as Record<string, unknown>,
          })
          refundQueuedCount++
        }
      } catch (error) {
        console.error(`Error processing campaign ${campaign.id}:`, error)
        results.push({
          campaignId: campaign.id,
          title: campaign.title,
          status: 'error',
          goalAmountKrw: campaign.goal_amount_krw,
          currentAmountKrw: campaign.current_amount_krw,
          backerCount: campaign.backer_count,
          error: String(error),
        })
        errorCount++
      }
    }

    // 3. 환불 큐 처리: pending 상태의 환불 요청을 PG사 API로 처리
    let refundProcessed = 0
    let refundFailed = 0

    const { data: pendingRefunds } = await supabase
      .from('funding_refund_queue')
      .select('id, pledge_id, payment_id, refund_amount_krw, original_payment_order_id, original_pg_transaction_id, payment_provider')
      .eq('status', 'pending')
      .order('created_at', { ascending: true })
      .limit(50) // 배치 크기 제한

    if (pendingRefunds && pendingRefunds.length > 0) {
      console.log(`Processing ${pendingRefunds.length} pending refunds...`)

      for (const refund of pendingRefunds) {
        // 처리 중 상태로 변경
        await supabase
          .from('funding_refund_queue')
          .update({ status: 'processing' })
          .eq('id', refund.id)

        // PG사 환불 API 호출
        // PortOne에서는 pg_payment_id를 사용해야 함
        const { data: paymentData } = await supabase
          .from('funding_payments')
          .select('pg_payment_id')
          .eq('id', refund.payment_id)
          .single()

        const pgPaymentId = paymentData?.pg_payment_id || refund.original_payment_order_id

        const cancelResult = await cancelPortOnePayment(
          pgPaymentId,
          refund.refund_amount_krw,
          '캠페인 목표 미달로 인한 자동 환불'
        )

        if (cancelResult.success) {
          // 환불 성공 → DB 상태 업데이트
          const { error: completeError } = await supabase.rpc('complete_funding_refund', {
            p_queue_id: refund.id,
            p_pg_refund_id: cancelResult.pgRefundId || null,
            p_pg_response: cancelResult.response || null,
          })

          if (completeError) {
            console.error(`Failed to mark refund complete for queue ${refund.id}:`, completeError)
          }

          refundProcessed++
        } else {
          // 환불 실패 → 재시도 큐
          const { error: failError } = await supabase.rpc('fail_funding_refund', {
            p_queue_id: refund.id,
            p_error: cancelResult.error || 'Unknown PG error',
            p_pg_response: cancelResult.response || null,
          })

          if (failError) {
            console.error(`Failed to mark refund failed for queue ${refund.id}:`, failError)
          }

          refundFailed++
        }
      }
    }

    console.log(
      `Campaign completion done: ${succeededCount} succeeded, ${refundQueuedCount} refund_queued, ${errorCount} errors. PG refunds: ${refundProcessed} processed, ${refundFailed} failed.`
    )

    return new Response(
      JSON.stringify({
        success: true,
        summary: {
          total: expiredCampaigns.length,
          succeeded: succeededCount,
          refundQueued: refundQueuedCount,
          errors: errorCount,
          pgRefundsProcessed: refundProcessed,
          pgRefundsFailed: refundFailed,
        },
        results,
      }),
      { status: 200, headers: jsonHeaders }
    )
  } catch (error) {
    console.error('Campaign completion error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: String(error) }),
      { status: 500, headers: jsonHeaders }
    )
  }
})
