// =====================================================
// Edge Function: agency-settlement-calculate
// Purpose: 소속사별 월별 정산 집계 (payout-calculate 이후 실행)
//
// payout-calculate가 크리에이터별 payouts 레코드를 생성한 뒤,
// 이 함수가 소속사별로 크리에이터 payout을 집계하여
// agency_settlements 레코드를 생성한다.
//
// 정산 모드:
//   - 개별 정산: 위임장 없음 → 크리에이터에게 직접 지급, 소속사는 수수료만 수령
//   - 통합 정산: 위임장 있음 → 소속사가 전액 수령, 크리에이터에게 직접 정산
//
// 실행 시점: 매월 2일 (payout-calculate 후 체인 실행)
// =====================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { requireCronAuth } from '../_shared/cron_auth.ts'

const jsonHeaders = { 'Content-Type': 'application/json' }

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
    const periodEnd = new Date(now.getFullYear(), now.getMonth(), 0)
    const periodStart = new Date(periodEnd.getFullYear(), periodEnd.getMonth(), 1)
    const periodStartStr = periodStart.toISOString().split('T')[0]
    const periodEndStr = periodEnd.toISOString().split('T')[0]

    console.log(`=== Agency settlement: ${periodStartStr} ~ ${periodEndStr} ===`)

    // === 2. 활성 소속사 조회 ===
    const { data: agencies, error: agenciesError } = await supabase
      .from('agencies')
      .select('id, name, tax_type, bank_code, bank_account_number, account_holder_name')
      .eq('status', 'active')

    if (agenciesError) {
      console.error('Failed to fetch agencies:', agenciesError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch agencies' }),
        { status: 500, headers: jsonHeaders }
      )
    }

    if (!agencies || agencies.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'No active agencies', results: { processed: 0 } }),
        { status: 200, headers: jsonHeaders }
      )
    }

    const results = {
      processed: 0,
      created: 0,
      skipped: 0,
      errors: 0,
      settlements: [] as Record<string, unknown>[],
    }

    for (const agency of agencies) {
      try {
        results.processed++

        // === 3. 중복 정산 체크 ===
        const { data: existingSettlement } = await supabase
          .from('agency_settlements')
          .select('id')
          .eq('agency_id', agency.id)
          .eq('period_start', periodStartStr)
          .eq('period_end', periodEndStr)
          .not('status', 'in', '("cancelled","failed")')
          .single()

        if (existingSettlement) {
          console.log(`Settlement already exists for agency ${agency.id}`)
          results.skipped++
          continue
        }

        // === 4. 소속 크리에이터 계약 조회 ===
        const { data: activeContracts, error: contractsError } = await supabase
          .from('agency_creators')
          .select(`
            id,
            creator_profile_id,
            revenue_share_rate,
            power_of_attorney_url
          `)
          .eq('agency_id', agency.id)
          .eq('status', 'active')

        if (contractsError || !activeContracts || activeContracts.length === 0) {
          console.log(`No active creators for agency ${agency.id}`)
          results.skipped++
          continue
        }

        // === 5. 크리에이터별 payout 집계 ===
        let totalGrossKrw = 0
        let totalPlatformFeeKrw = 0
        let totalCreatorNetKrw = 0
        let totalAgencyCommissionKrw = 0
        const breakdown: Record<string, unknown>[] = []

        for (const contract of activeContracts) {
          // 크리에이터의 creator_profiles.user_id 조회
          const { data: creatorProfile } = await supabase
            .from('creator_profiles')
            .select('user_id, stage_name')
            .eq('id', contract.creator_profile_id)
            .single()

          if (!creatorProfile) continue

          // 해당 기간의 payout 조회
          const { data: payout } = await supabase
            .from('payouts')
            .select('id, gross_krw, platform_fee_krw, net_krw, withholding_tax_krw')
            .eq('creator_id', creatorProfile.user_id)
            .eq('period_start', periodStartStr)
            .eq('period_end', periodEndStr)
            .not('status', 'in', '("cancelled","failed")')
            .single()

          if (!payout) continue

          // 소속사 수수료 = (gross - platform_fee) × revenue_share_rate
          const netAfterPlatform = payout.gross_krw - payout.platform_fee_krw
          const agencyCommission = Math.floor(netAfterPlatform * contract.revenue_share_rate)
          const hasPOA = !!contract.power_of_attorney_url

          breakdown.push({
            creator_profile_id: contract.creator_profile_id,
            creator_user_id: creatorProfile.user_id,
            creator_name: creatorProfile.stage_name || '',
            payout_id: payout.id,
            gross_krw: payout.gross_krw,
            platform_fee_krw: payout.platform_fee_krw,
            net_krw: payout.net_krw,
            withholding_tax_krw: payout.withholding_tax_krw,
            agency_commission_krw: agencyCommission,
            revenue_share_rate: contract.revenue_share_rate,
            has_power_of_attorney: hasPOA,
          })

          totalGrossKrw += payout.gross_krw
          totalPlatformFeeKrw += payout.platform_fee_krw
          totalCreatorNetKrw += payout.net_krw
          totalAgencyCommissionKrw += agencyCommission
        }

        if (breakdown.length === 0) {
          console.log(`No payouts for agency ${agency.id} creators`)
          results.skipped++
          continue
        }

        // === 6. 소속사 세금 계산 ===
        // 사업자: 세금계산서 발행 (원천징수 없음, 0%)
        // 개인: 사업소득 3.3%
        const isBusiness = agency.tax_type === 'business'
        const agencyTaxRate = isBusiness ? 0 : 0.033
        const agencyTaxKrw = Math.floor(totalAgencyCommissionKrw * agencyTaxRate)
        const agencyNetKrw = totalAgencyCommissionKrw - agencyTaxKrw

        // === 7. agency_settlements 레코드 생성 ===
        const { data: settlement, error: settlementError } = await supabase
          .from('agency_settlements')
          .insert({
            agency_id: agency.id,
            period_start: periodStartStr,
            period_end: periodEndStr,
            total_creators: breakdown.length,
            total_gross_krw: totalGrossKrw,
            total_platform_fee_krw: totalPlatformFeeKrw,
            total_creator_net_krw: totalCreatorNetKrw,
            agency_commission_krw: totalAgencyCommissionKrw,
            agency_tax_type: isBusiness ? 'invoice' : 'business_income',
            agency_tax_rate: agencyTaxRate,
            agency_tax_krw: agencyTaxKrw,
            agency_net_krw: agencyNetKrw,
            creator_breakdown: breakdown,
            status: 'draft',
          })
          .select()
          .single()

        if (settlementError) {
          console.error(`Failed to create settlement for agency ${agency.id}:`, settlementError)
          results.errors++
          continue
        }

        console.log(
          `Settlement created: agency=${agency.id} creators=${breakdown.length} ` +
          `commission=${totalAgencyCommissionKrw} net=${agencyNetKrw}`
        )

        results.created++
        results.settlements.push({
          agencyId: agency.id,
          agencyName: agency.name,
          settlementId: settlement.id,
          totalCreators: breakdown.length,
          totalGrossKrw: totalGrossKrw,
          agencyCommissionKrw: totalAgencyCommissionKrw,
          agencyTaxKrw: agencyTaxKrw,
          agencyNetKrw: agencyNetKrw,
        })
      } catch (error) {
        console.error(`Error processing agency ${agency.id}:`, error)
        results.errors++
      }
    }

    console.log('=== Agency settlement complete ===', JSON.stringify(results, null, 2))

    return new Response(
      JSON.stringify({
        success: true,
        period: { start: periodStartStr, end: periodEndStr },
        results,
      }),
      { status: 200, headers: jsonHeaders }
    )
  } catch (error) {
    console.error('Agency settlement error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: jsonHeaders }
    )
  }
})
