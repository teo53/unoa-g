// =====================================================
// Edge Function: payout-calculate
// Purpose: 월별 크리에이터 정산 계산 (DT + KRW 분리)
//
// 매월 1일 실행 (scheduled-dispatcher에서 호출)
//
// 수익 구조:
//   DT 수익: 팁/도네이션, 프라이빗카드 판매, 유료답글
//     → DT로 집계 → KRW 변환 (DT_UNIT_PRICE_KRW)
//   KRW 수익: 펀딩 결제 (funding_payments)
//     → KRW 그대로 집계 (변환 불필요)
//
// 플랫폼 수수료: 20% (양쪽 동일)
// 원천징수: income_tax_rates 테이블에서 크리에이터별 조회
//   - 사업소득 3.3%
//   - 기타소득 8.8%
//   - 세금계산서 0%
//
// 출력:
//   - payouts 레코드 (pending_review 상태)
//   - payout_line_items (소득유형별 상세)
//   - settlement_statements (정산 명세서)
// =====================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { requireCronAuth } from '../_shared/cron_auth.ts'

const jsonHeaders = { 'Content-Type': 'application/json' }

// DT → KRW 내부 변환 단가 (패키지별 고정가 기준)
// DT_PACKAGES: 10 DT = 1,000원, 100 DT = 10,000원 등
// 환율(exchange rate) 개념이 아닌 패키지 기본 단가 기반 정산용 참고값
const DT_UNIT_PRICE_KRW = 100

// 플랫폼 수수료율
const PLATFORM_FEE_RATE = 0.20 // 20%

// 최소 지급 기준 (KRW)
const MINIMUM_PAYOUT_KRW = 10000

// 원천징수 기본값 (income_tax_rates 조회 실패 시)
const DEFAULT_TAX_RATE = 0.033 // 3.3%

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

    // === 1. 정산 기간 계산 (전월) ===
    const now = new Date()
    const periodEnd = new Date(now.getFullYear(), now.getMonth(), 0) // 전월 말일
    const periodStart = new Date(periodEnd.getFullYear(), periodEnd.getMonth(), 1) // 전월 1일
    const periodStartStr = periodStart.toISOString().split('T')[0]
    const periodEndStr = periodEnd.toISOString().split('T')[0]

    console.log(`=== Payout calculation: ${periodStartStr} ~ ${periodEndStr} ===`)

    // === 2. 인증된 크리에이터 조회 ===
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
        { status: 500, headers: jsonHeaders }
      )
    }

    const results = {
      processed: 0,
      created: 0,
      skipped: 0,
      errors: 0,
      payouts: [] as Record<string, unknown>[],
    }

    for (const creator of creators || []) {
      try {
        results.processed++

        // === 3. 중복 정산 체크 ===
        const { data: existingPayout } = await supabase
          .from('payouts')
          .select('id')
          .eq('creator_id', creator.user_id)
          .eq('period_start', periodStartStr)
          .eq('period_end', periodEndStr)
          .not('status', 'in', '("cancelled","failed")')
          .single()

        if (existingPayout) {
          console.log(`Payout already exists for creator ${creator.user_id}`)
          results.skipped++
          continue
        }

        // === 4. 크리에이터 세금 정보 조회 ===
        const incomeType = creator.payout_settings?.income_type || 'business_income'
        let taxRate = DEFAULT_TAX_RATE

        const { data: taxInfo } = await supabase
          .rpc('get_creator_tax_info', { p_creator_id: creator.user_id })

        if (taxInfo) {
          taxRate = (taxInfo.tax_rate || 3.3) / 100 // DB에서는 %로 저장
        } else {
          // Fallback: income_tax_rates 테이블에서 직접 조회
          const { data: rateData } = await supabase
            .from('income_tax_rates')
            .select('tax_rate')
            .eq('income_type', incomeType)
            .eq('is_active', true)
            .single()

          if (rateData) {
            taxRate = rateData.tax_rate / 100
          }
        }

        // === 5. DT 수익 집계 ===

        // 5a. 팁/도네이션 (DT) — gross(amount_dt) + net(creator_share_dt) 분리 추적
        const { data: donations } = await supabase
          .from('dt_donations')
          .select('amount_dt, creator_share_dt, platform_fee_dt')
          .eq('to_creator_id', creator.user_id)
          .gte('created_at', periodStart.toISOString())
          .lte('created_at', periodEnd.toISOString())

        const tipsGrossDt = donations?.reduce((sum, d) => sum + (d.amount_dt || 0), 0) || 0
        const tipsNetDt = donations?.reduce((sum, d) => sum + (d.creator_share_dt || 0), 0) || 0
        const tipsCount = donations?.length || 0

        // 5b. 프라이빗카드 판매 (DT) — gross 기준 추적 (수수료는 아래에서 일괄 차감)
        const { data: cardSales } = await supabase
          .from('private_card_purchases')
          .select(`
            price_paid_dt,
            private_cards!inner (creator_id)
          `)
          .eq('private_cards.creator_id', creator.user_id)
          .gte('created_at', periodStart.toISOString())
          .lte('created_at', periodEnd.toISOString())

        const cardsGrossDt = cardSales?.reduce((sum, s) => sum + (s.price_paid_dt || 0), 0) || 0
        const cardsCount = cardSales?.length || 0

        // 5c. 유료답글 수익 (DT) — gross(amount_dt) + net(creator_share_dt) 분리 추적
        const { data: replies } = await supabase
          .from('paid_replies')
          .select('amount_dt, creator_share_dt')
          .eq('creator_id', creator.user_id)
          .gte('created_at', periodStart.toISOString())
          .lte('created_at', periodEnd.toISOString())

        const repliesGrossDt = replies?.reduce((sum, r) => sum + (r.amount_dt || 0), 0) || 0
        const repliesNetDt = replies?.reduce((sum, r) => sum + (r.creator_share_dt || 0), 0) || 0
        const repliesCount = replies?.length || 0

        // DT 합계 → KRW 변환 (gross 기준, 수수료는 7번에서 1회만 차감)
        const dtGrossTotalDt = tipsGrossDt + cardsGrossDt + repliesGrossDt
        const dtGrossRevenueKrw = Math.floor(dtGrossTotalDt * DT_UNIT_PRICE_KRW)

        // === 6. KRW 수익 집계 (펀딩) ===
        // funding_payments 테이블에서 직접 조회 (DT 원장과 완전 분리)
        const { data: fundingPayments } = await supabase
          .from('funding_payments')
          .select(`
            amount_krw,
            campaign_id,
            funding_pledges!inner (
              campaign_id,
              funding_campaigns!inner (creator_id)
            )
          `)
          .eq('funding_pledges.funding_campaigns.creator_id', creator.user_id)
          .eq('status', 'paid')
          .gte('paid_at', periodStart.toISOString())
          .lte('paid_at', periodEnd.toISOString())

        const fundingGrossKrw = fundingPayments?.reduce((sum, p) => sum + (p.amount_krw || 0), 0) || 0
        const fundingCount = fundingPayments?.length || 0
        const fundingCampaigns = new Set(fundingPayments?.map(p => p.campaign_id) || []).size

        // === 7. 수수료 및 세금 계산 ===
        // ⚠️ 중요: DT 수익은 gross 기준으로 수수료 1회만 차감
        //    이전 버그: creator_share_dt(이미 80%)에 다시 20% 적용 → 64% 지급 오류

        // DT 수익에 대한 플랫폼 수수료 (gross 기준, 1회 차감)
        const dtPlatformFeeKrw = Math.floor(dtGrossRevenueKrw * PLATFORM_FEE_RATE)

        // KRW 수익에 대한 플랫폼 수수료
        const fundingPlatformFeeKrw = Math.floor(fundingGrossKrw * PLATFORM_FEE_RATE)

        // 총 수수료
        const totalPlatformFeeKrw = dtPlatformFeeKrw + fundingPlatformFeeKrw

        // 총 수익 (gross)
        const totalRevenueKrw = dtGrossRevenueKrw + fundingGrossKrw

        if (totalRevenueKrw === 0) {
          console.log(`No earnings for creator ${creator.user_id}`)
          results.skipped++
          continue
        }

        // 과세 대상 (수익 - 수수료)
        const taxableKrw = totalRevenueKrw - totalPlatformFeeKrw

        // 원천징수세 계산
        // 소득세 = 과세대상 × 세율 (지방소득세 포함)
        // ※ 소득세법 §86 (2024.7.1~) 소액부징수 폐지: 1,000원 미만도 반드시 원천징수
        //   현재 최소지급기준(10,000원) 덕분에 taxableKrw > 0이면 항상 withholdingTaxKrw > 0
        const withholdingTaxKrw = Math.floor(taxableKrw * taxRate)

        // 소득세/지방소득세 분리 (세율이 3.3%인 경우: 소득세 3% + 지방소득세 0.3%)
        const baseRate = taxRate / 1.1 // 지방소득세 10% 분리
        const incomeTaxKrw = Math.floor(taxableKrw * baseRate)
        const localTaxKrw = withholdingTaxKrw - incomeTaxKrw

        // 순 지급액
        const netPayoutKrw = taxableKrw - withholdingTaxKrw

        // 최소 지급 기준 체크
        const minimumPayout = creator.payout_settings?.minimum_payout_krw || MINIMUM_PAYOUT_KRW
        if (netPayoutKrw < minimumPayout) {
          console.log(`Creator ${creator.user_id} below minimum: ${netPayoutKrw} < ${minimumPayout}`)
          results.skipped++
          continue
        }

        // === 8. 은행 정보 조회 ===
        const { data: bankInfo } = await supabase
          .from('bank_codes')
          .select('name')
          .eq('code', creator.bank_code)
          .single()

        // === 9. 정산 레코드 생성 ===
        const { data: payout, error: payoutError } = await supabase
          .from('payouts')
          .insert({
            creator_id: creator.user_id,
            creator_profile_id: creator.id,
            period_start: periodStartStr,
            period_end: periodEndStr,
            gross_dt: dtGrossTotalDt,
            gross_krw: totalRevenueKrw,
            platform_fee_rate: PLATFORM_FEE_RATE,
            platform_fee_krw: totalPlatformFeeKrw,
            withholding_tax_rate: taxRate,
            withholding_tax_krw: withholdingTaxKrw,
            net_krw: netPayoutKrw,
            bank_code: creator.bank_code || '',
            bank_name: bankInfo?.name || '',
            bank_account_last4: creator.bank_account_number?.slice(-4) || '****',
            account_holder_name: creator.account_holder_name || '',
            status: 'pending_review',
          })
          .select()
          .single()

        if (payoutError) {
          // P0-05: Handle race condition — another instance already created this payout
          if (payoutError.code === '23505' &&
              (payoutError.message?.includes('idx_payouts_unique_period') ||
               payoutError.message?.includes('creator_id'))) {
            console.log(`Payout already created by concurrent process for creator ${creator.user_id}, skipping`)
            results.skipped++
            continue
          }

          console.error(`Failed to create payout for ${creator.user_id}:`, payoutError)
          results.errors++
          continue
        }

        // === 10. 소득유형별 라인 아이템 생성 ===
        const lineItems: Record<string, unknown>[] = []

        if (tipsGrossDt > 0) {
          lineItems.push({
            payout_id: payout.id,
            item_type: 'tip',
            item_count: tipsCount,
            gross_dt: tipsGrossDt,
            gross_krw: Math.floor(tipsGrossDt * DT_UNIT_PRICE_KRW),
          })
        }

        if (cardsGrossDt > 0) {
          lineItems.push({
            payout_id: payout.id,
            item_type: 'private_card',
            item_count: cardsCount,
            gross_dt: cardsGrossDt,
            gross_krw: Math.floor(cardsGrossDt * DT_UNIT_PRICE_KRW),
          })
        }

        if (repliesGrossDt > 0) {
          lineItems.push({
            payout_id: payout.id,
            item_type: 'paid_reply',
            item_count: repliesCount,
            gross_dt: repliesGrossDt,
            gross_krw: Math.floor(repliesGrossDt * DT_UNIT_PRICE_KRW),
          })
        }

        if (fundingGrossKrw > 0) {
          lineItems.push({
            payout_id: payout.id,
            item_type: 'funding',
            item_count: fundingCount,
            gross_dt: 0, // 펀딩은 DT 미사용
            gross_krw: fundingGrossKrw,
          })
        }

        if (lineItems.length > 0) {
          await supabase.from('payout_line_items').insert(lineItems)
        }

        // === 11. 정산 명세서 생성 ===
        const { error: statementError } = await supabase
          .from('settlement_statements')
          .insert({
            payout_id: payout.id,
            creator_id: creator.user_id,
            period_start: periodStartStr,
            period_end: periodEndStr,

            // DT 수익 상세 (gross 기준)
            dt_tips_count: tipsCount,
            dt_tips_gross: tipsGrossDt,
            dt_cards_count: cardsCount,
            dt_cards_gross: cardsGrossDt,
            dt_replies_count: repliesCount,
            dt_replies_gross: repliesGrossDt,
            dt_total_gross: dtGrossTotalDt,
            dt_to_krw_rate: DT_UNIT_PRICE_KRW,
            dt_revenue_krw: dtGrossRevenueKrw,

            // KRW 수익 상세 (펀딩)
            funding_campaigns_count: fundingCampaigns,
            funding_pledges_count: fundingCount,
            funding_revenue_krw: fundingGrossKrw,

            // 합산
            total_revenue_krw: totalRevenueKrw,
            platform_fee_rate: PLATFORM_FEE_RATE * 100, // %로 저장
            platform_fee_krw: totalPlatformFeeKrw,

            // 세금
            income_type: incomeType,
            tax_rate: taxRate * 100, // %로 저장
            income_tax_krw: incomeTaxKrw,
            local_tax_krw: localTaxKrw,
            withholding_tax_krw: withholdingTaxKrw,

            // 순 지급액
            net_payout_krw: netPayoutKrw,
          })

        if (statementError) {
          console.error(`Failed to create statement for ${creator.user_id}:`, statementError)
          // 정산 명세서 실패는 payout 생성에 영향 주지 않음
        }

        console.log(`Payout created: creator=${creator.user_id}, DT=${dtGrossTotalDt} KRW_funding=${fundingGrossKrw} net=${netPayoutKrw}`)

        results.created++
        results.payouts.push({
          creatorId: creator.user_id,
          payoutId: payout.id,
          dtRevenueKrw: dtGrossRevenueKrw,
          fundingRevenueKrw: fundingGrossKrw,
          totalRevenueKrw,
          platformFeeKrw: totalPlatformFeeKrw,
          withholdingTaxKrw,
          netPayoutKrw,
          incomeType,
          taxRate: taxRate * 100,
        })
      } catch (error) {
        console.error(`Error processing creator ${creator.user_id}:`, error)
        results.errors++
      }
    }

    console.log('=== Payout calculation complete ===', JSON.stringify(results, null, 2))

    return new Response(
      JSON.stringify({
        success: true,
        period: { start: periodStartStr, end: periodEndStr },
        dtToKrwRate: DT_UNIT_PRICE_KRW,
        results,
      }),
      { status: 200, headers: jsonHeaders }
    )
  } catch (error) {
    console.error('Payout calculation error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: jsonHeaders }
    )
  }
})
