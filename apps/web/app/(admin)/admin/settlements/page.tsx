import { DEMO_MODE } from '@/lib/mock/demo-data'
import SettlementsClient, { type Settlement } from './settlements-client'

// =====================================================
// Admin Settlement Management Page (RSC - data fetch only)
// Client component handles: 필터, 승인/반려, CSV, 상세 모달
// =====================================================

// Mock settlements with subscription revenue data
const mockSettlements: Settlement[] = [
  {
    id: 'settle-001',
    creator_id: 'demo-creator-1',
    creator_name: 'WAKER',
    period_start: '2026-01-01',
    period_end: '2026-01-31',
    subscription_basic_count: 15,
    subscription_basic_krw: 73500,
    subscription_standard_count: 8,
    subscription_standard_krw: 79200,
    subscription_vip_count: 3,
    subscription_vip_krw: 59700,
    subscription_total_krw: 212400,
    dt_total_gross: 125000,
    dt_revenue_krw: 125000,
    funding_revenue_krw: 387500,
    total_revenue_krw: 724900,
    platform_fee_krw: 144980,
    income_type: 'business_income',
    tax_rate: 3.3,
    withholding_tax_krw: 19137,
    net_payout_krw: 560783,
    status: 'pending_review',
    created_at: '2026-02-01T00:00:00Z',
  },
  {
    id: 'settle-002',
    creator_id: 'demo-creator-2',
    creator_name: 'MOONLIGHT',
    period_start: '2026-01-01',
    period_end: '2026-01-31',
    subscription_basic_count: 22,
    subscription_basic_krw: 107800,
    subscription_standard_count: 12,
    subscription_standard_krw: 118800,
    subscription_vip_count: 5,
    subscription_vip_krw: 99500,
    subscription_total_krw: 326100,
    dt_total_gross: 85000,
    dt_revenue_krw: 85000,
    funding_revenue_krw: 780000,
    total_revenue_krw: 1191100,
    platform_fee_krw: 238220,
    income_type: 'other_income',
    tax_rate: 8.8,
    withholding_tax_krw: 83853,
    net_payout_krw: 869027,
    status: 'pending_review',
    created_at: '2026-02-01T00:00:00Z',
  },
  {
    id: 'settle-003',
    creator_id: 'demo-creator-3',
    creator_name: 'STARLIGHT',
    period_start: '2025-12-01',
    period_end: '2025-12-31',
    subscription_basic_count: 35,
    subscription_basic_krw: 171500,
    subscription_standard_count: 18,
    subscription_standard_krw: 178200,
    subscription_vip_count: 8,
    subscription_vip_krw: 159200,
    subscription_total_krw: 508900,
    dt_total_gross: 45000,
    dt_revenue_krw: 45000,
    funding_revenue_krw: 450000,
    total_revenue_krw: 1003900,
    platform_fee_krw: 200780,
    income_type: 'business_income',
    tax_rate: 3.3,
    withholding_tax_krw: 26503,
    net_payout_krw: 776617,
    status: 'approved',
    created_at: '2026-01-01T00:00:00Z',
  },
  {
    id: 'settle-004',
    creator_id: 'demo-creator-1',
    creator_name: 'WAKER',
    period_start: '2025-12-01',
    period_end: '2025-12-31',
    subscription_basic_count: 12,
    subscription_basic_krw: 58800,
    subscription_standard_count: 7,
    subscription_standard_krw: 69300,
    subscription_vip_count: 2,
    subscription_vip_krw: 39800,
    subscription_total_krw: 167900,
    dt_total_gross: 98000,
    dt_revenue_krw: 98000,
    funding_revenue_krw: 250000,
    total_revenue_krw: 515900,
    platform_fee_krw: 103180,
    income_type: 'business_income',
    tax_rate: 3.3,
    withholding_tax_krw: 13620,
    net_payout_krw: 399100,
    status: 'paid',
    created_at: '2025-12-31T00:00:00Z',
  },
]

async function getSettlements(): Promise<Settlement[]> {
  if (DEMO_MODE) {
    return mockSettlements
  }

  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('settlement_statements')
    .select(`
      *,
      payouts!inner(status, creator_id),
      user_profiles!inner(display_name)
    `)
    .order('created_at', { ascending: false })
    .limit(50)

  if (error) {
    console.error('Error fetching settlements:', error)
    return []
  }

  return (data || []).map((s: Record<string, unknown>) => ({
    id: s.id as string,
    creator_id: (s.payouts as Record<string, unknown>)?.creator_id as string || '',
    creator_name: (s.user_profiles as Record<string, unknown>)?.display_name as string || 'Unknown',
    period_start: s.period_start as string,
    period_end: s.period_end as string,
    subscription_basic_count: (s.subscription_basic_count as number) || 0,
    subscription_basic_krw: (s.subscription_basic_krw as number) || 0,
    subscription_standard_count: (s.subscription_standard_count as number) || 0,
    subscription_standard_krw: (s.subscription_standard_krw as number) || 0,
    subscription_vip_count: (s.subscription_vip_count as number) || 0,
    subscription_vip_krw: (s.subscription_vip_krw as number) || 0,
    subscription_total_krw: (s.subscription_total_krw as number) || 0,
    dt_total_gross: s.dt_total_gross as number || 0,
    dt_revenue_krw: s.dt_revenue_krw as number || 0,
    funding_revenue_krw: s.funding_revenue_krw as number || 0,
    total_revenue_krw: s.total_revenue_krw as number || 0,
    platform_fee_krw: s.platform_fee_krw as number || 0,
    income_type: s.income_type as string || 'business_income',
    tax_rate: s.tax_rate as number || 3.3,
    withholding_tax_krw: s.withholding_tax_krw as number || 0,
    net_payout_krw: s.net_payout_krw as number || 0,
    status: (s.payouts as Record<string, unknown>)?.status as string || 'pending_review',
    created_at: s.created_at as string,
  }))
}

async function getStats(settlements: Settlement[]) {
  return {
    pendingReview: settlements.filter(s => s.status === 'pending_review').length,
    approved: settlements.filter(s => s.status === 'approved').length,
    paid: settlements.filter(s => s.status === 'paid').length,
    totalPayoutKrw: settlements.reduce((sum, s) => sum + s.net_payout_krw, 0),
  }
}

export default async function SettlementsPage() {
  const settlements = await getSettlements()
  const stats = await getStats(settlements)

  return (
    <SettlementsClient
      initialSettlements={settlements}
      initialStats={stats}
      isDemoMode={DEMO_MODE}
    />
  )
}
