// =====================================================
// Edge Function: settlement-export
// Purpose: 정산 명세서 CSV 내보내기 (관리자/크리에이터)
//
// Endpoints:
//   POST /settlement-export
//     - type: 'csv' | 'summary'
//     - period: { start: 'YYYY-MM-DD', end: 'YYYY-MM-DD' }
//     - creatorId?: string (admin only, specific creator)
//
// SECURITY: Admin can export all; creators can only export their own.
// =====================================================

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders } from '../_shared/cors.ts'

const jsonHeaders = { 'Content-Type': 'application/json' }

interface ExportRequest {
  type: 'csv' | 'summary'
  periodStart: string  // YYYY-MM-DD
  periodEnd: string    // YYYY-MM-DD
  creatorId?: string   // Admin: specific creator; empty = all
}

/**
 * Generate CSV content from settlement data
 */
function generateSettlementCSV(statements: Record<string, unknown>[]): string {
  const headers = [
    '정산ID',
    '크리에이터ID',
    '정산기간시작',
    '정산기간종료',
    'DT팁수',
    'DT팁총액',
    'DT카드수',
    'DT카드총액',
    'DT답글수',
    'DT답글총액',
    'DT수익합계',
    'DT→KRW환율',
    'DT수익KRW',
    '펀딩캠페인수',
    '펀딩후원수',
    '펀딩수익KRW',
    '총수익KRW',
    '플랫폼수수료율(%)',
    '플랫폼수수료KRW',
    '소득유형',
    '세율(%)',
    '소득세KRW',
    '지방소득세KRW',
    '원천징수합계KRW',
    '순지급액KRW',
    '생성일',
  ]

  const rows = statements.map((s: Record<string, unknown>) => [
    s.id,
    s.creator_id,
    s.period_start,
    s.period_end,
    s.dt_tips_count ?? 0,
    s.dt_tips_gross ?? 0,
    s.dt_cards_count ?? 0,
    s.dt_cards_gross ?? 0,
    s.dt_replies_count ?? 0,
    s.dt_replies_gross ?? 0,
    s.dt_total_gross ?? 0,
    s.dt_to_krw_rate ?? 1.0,
    s.dt_revenue_krw ?? 0,
    s.funding_campaigns_count ?? 0,
    s.funding_pledges_count ?? 0,
    s.funding_revenue_krw ?? 0,
    s.total_revenue_krw ?? 0,
    s.platform_fee_rate ?? 20.0,
    s.platform_fee_krw ?? 0,
    s.income_type ?? '',
    s.tax_rate ?? 0,
    s.income_tax_krw ?? 0,
    s.local_tax_krw ?? 0,
    s.withholding_tax_krw ?? 0,
    s.net_payout_krw ?? 0,
    s.created_at ?? '',
  ])

  // BOM for Korean Excel compatibility
  const BOM = '\uFEFF'
  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')),
  ].join('\n')

  return BOM + csvContent
}

/**
 * Generate withholding tax report CSV
 */
function generateTaxReportCSV(statements: Record<string, unknown>[]): string {
  const headers = [
    '크리에이터ID',
    '정산기간',
    '소득유형',
    '총수익KRW',
    '플랫폼수수료KRW',
    '과세대상금액KRW',
    '세율(%)',
    '소득세KRW',
    '지방소득세KRW',
    '원천징수합계KRW',
  ]

  const rows = statements.map((s: Record<string, unknown>) => [
    s.creator_id,
    `${s.period_start}~${s.period_end}`,
    s.income_type ?? 'business_income',
    s.total_revenue_krw ?? 0,
    s.platform_fee_krw ?? 0,
    (Number(s.total_revenue_krw ?? 0) - Number(s.platform_fee_krw ?? 0)),
    s.tax_rate ?? 3.3,
    s.income_tax_krw ?? 0,
    s.local_tax_krw ?? 0,
    s.withholding_tax_krw ?? 0,
  ])

  const BOM = '\uFEFF'
  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')),
  ].join('\n')

  return BOM + csvContent
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: getCorsHeaders(req) })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Verify user
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid authentication' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Check admin role
    const { data: profile } = await supabaseAdmin
      .from('user_profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    const isAdmin = profile?.role === 'admin'

    const body: ExportRequest = await req.json()
    const { type, periodStart, periodEnd, creatorId } = body

    if (!periodStart || !periodEnd) {
      return new Response(
        JSON.stringify({ error: 'periodStart and periodEnd are required' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Build query
    let query = supabaseAdmin
      .from('settlement_statements')
      .select('*')
      .gte('period_start', periodStart)
      .lte('period_end', periodEnd)
      .order('period_start', { ascending: false })

    if (isAdmin && creatorId) {
      query = query.eq('creator_id', creatorId)
    } else if (!isAdmin) {
      // Non-admin: only own data
      query = query.eq('creator_id', user.id)
    }

    const { data: statements, error: queryError } = await query

    if (queryError) {
      return new Response(
        JSON.stringify({ error: 'Failed to query settlements', details: queryError.message }),
        { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (!statements || statements.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No settlement data found for the specified period' }),
        { status: 404, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (type === 'csv') {
      // Full settlement CSV
      const csv = generateSettlementCSV(statements)
      const filename = `settlement_${periodStart}_${periodEnd}.csv`

      return new Response(csv, {
        status: 200,
        headers: {
          ...getCorsHeaders(req),
          'Content-Type': 'text/csv; charset=utf-8',
          'Content-Disposition': `attachment; filename="${filename}"`,
        },
      })
    } else if (type === 'summary') {
      // Withholding tax report CSV
      const csv = generateTaxReportCSV(statements)
      const filename = `tax_withholding_${periodStart}_${periodEnd}.csv`

      return new Response(csv, {
        status: 200,
        headers: {
          ...getCorsHeaders(req),
          'Content-Type': 'text/csv; charset=utf-8',
          'Content-Disposition': `attachment; filename="${filename}"`,
        },
      })
    } else {
      // JSON summary
      const summary = {
        period: { start: periodStart, end: periodEnd },
        totalStatements: statements.length,
        totalRevenueKrw: statements.reduce((sum, s) => sum + (s.total_revenue_krw || 0), 0),
        totalPlatformFeeKrw: statements.reduce((sum, s) => sum + (s.platform_fee_krw || 0), 0),
        totalWithholdingTaxKrw: statements.reduce((sum, s) => sum + (s.withholding_tax_krw || 0), 0),
        totalNetPayoutKrw: statements.reduce((sum, s) => sum + (s.net_payout_krw || 0), 0),
        dtRevenueKrw: statements.reduce((sum, s) => sum + (s.dt_revenue_krw || 0), 0),
        fundingRevenueKrw: statements.reduce((sum, s) => sum + (s.funding_revenue_krw || 0), 0),
        byIncomeType: {} as Record<string, { count: number; totalKrw: number; taxKrw: number }>,
      }

      for (const s of statements) {
        const type = s.income_type || 'business_income'
        if (!summary.byIncomeType[type]) {
          summary.byIncomeType[type] = { count: 0, totalKrw: 0, taxKrw: 0 }
        }
        summary.byIncomeType[type].count++
        summary.byIncomeType[type].totalKrw += s.total_revenue_krw || 0
        summary.byIncomeType[type].taxKrw += s.withholding_tax_krw || 0
      }

      return new Response(
        JSON.stringify({ success: true, summary }),
        { status: 200, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }
  } catch (error) {
    console.error('Settlement export error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }
})
