import { DEMO_MODE } from '@/lib/mock/demo-data'
import TaxReportsClient from './tax-reports-client'

// =====================================================
// Admin Tax Reports Page
// - 원천징수 내역 CSV 내보내기
// - 크리에이터별 연간 소득 집계
// - 소득유형별 필터링
// =====================================================

interface CreatorTaxSummary {
  creator_id: string
  creator_name: string
  income_type: string
  tax_rate: number
  total_revenue_krw: number
  platform_fee_krw: number
  taxable_krw: number
  income_tax_krw: number
  local_tax_krw: number
  withholding_total_krw: number
  net_payout_krw: number
  settlement_count: number
}

// Mock data for demo
const mockTaxSummaries: CreatorTaxSummary[] = [
  {
    creator_id: 'demo-creator-1',
    creator_name: 'WAKER',
    income_type: 'business_income',
    tax_rate: 3.3,
    total_revenue_krw: 860500,
    platform_fee_krw: 172100,
    taxable_krw: 688400,
    income_tax_krw: 18780,
    local_tax_krw: 1937,
    withholding_total_krw: 20717,
    net_payout_krw: 667683,
    settlement_count: 2,
  },
  {
    creator_id: 'demo-creator-2',
    creator_name: 'MOONLIGHT',
    income_type: 'other_income',
    tax_rate: 8.8,
    total_revenue_krw: 865000,
    platform_fee_krw: 173000,
    taxable_krw: 692000,
    income_tax_krw: 55360,
    local_tax_krw: 5536,
    withholding_total_krw: 60896,
    net_payout_krw: 631104,
    settlement_count: 1,
  },
  {
    creator_id: 'demo-creator-3',
    creator_name: 'STARLIGHT',
    income_type: 'business_income',
    tax_rate: 3.3,
    total_revenue_krw: 495000,
    platform_fee_krw: 99000,
    taxable_krw: 396000,
    income_tax_krw: 10800,
    local_tax_krw: 1068,
    withholding_total_krw: 11868,
    net_payout_krw: 384132,
    settlement_count: 1,
  },
]

async function getTaxSummaries(): Promise<CreatorTaxSummary[]> {
  if (DEMO_MODE) {
    return mockTaxSummaries
  }

  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  // Aggregate settlement data per creator for current year
  const { data, error } = await supabase
    .from('settlement_statements' as never)
    .select(`
      creator_id,
      income_type,
      tax_rate,
      total_revenue_krw,
      platform_fee_krw,
      income_tax_krw,
      local_tax_krw,
      withholding_tax_krw,
      net_payout_krw
    `)
    .gte('period_start', '2026-01-01')
    .lte('period_end', '2026-12-31') as { data: Array<{
      creator_id: string
      income_type: string
      tax_rate: number
      total_revenue_krw: number
      platform_fee_krw: number
      income_tax_krw: number
      local_tax_krw: number
      withholding_tax_krw: number
      net_payout_krw: number
    }> | null; error: unknown }

  if (error) {
    console.error('Error fetching tax data:', error)
    return []
  }

  // Group by creator
  const grouped: Record<string, CreatorTaxSummary> = {}
  for (const s of data || []) {
    const key = s.creator_id
    if (!grouped[key]) {
      grouped[key] = {
        creator_id: s.creator_id,
        creator_name: s.creator_id, // Will be resolved separately
        income_type: s.income_type || 'business_income',
        tax_rate: s.tax_rate || 3.3,
        total_revenue_krw: 0,
        platform_fee_krw: 0,
        taxable_krw: 0,
        income_tax_krw: 0,
        local_tax_krw: 0,
        withholding_total_krw: 0,
        net_payout_krw: 0,
        settlement_count: 0,
      }
    }
    grouped[key].total_revenue_krw += s.total_revenue_krw || 0
    grouped[key].platform_fee_krw += s.platform_fee_krw || 0
    grouped[key].income_tax_krw += s.income_tax_krw || 0
    grouped[key].local_tax_krw += s.local_tax_krw || 0
    grouped[key].withholding_total_krw += s.withholding_tax_krw || 0
    grouped[key].net_payout_krw += s.net_payout_krw || 0
    grouped[key].taxable_krw = grouped[key].total_revenue_krw - grouped[key].platform_fee_krw
    grouped[key].settlement_count++
  }

  return Object.values(grouped)
}


export default async function TaxReportsPage() {
  const summaries = await getTaxSummaries()

  return (
    <TaxReportsClient
      initialReports={summaries}
      isDemoMode={DEMO_MODE}
    />
  )
}
