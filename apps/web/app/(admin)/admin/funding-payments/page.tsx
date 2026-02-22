import { DEMO_MODE } from '@/lib/mock/demo-data'
import FundingPaymentsClient from './funding-payments-client'

// =====================================================
// Admin Funding Payments Page
// - 캠페인별 KRW 결제 현황
// - 환불 처리 (PG사 연동)
// - 분쟁/차지백 관리
// =====================================================

interface FundingPayment {
  id: string
  pledge_id: string
  campaign_id: string
  campaign_title: string
  user_id: string
  user_name: string
  amount_krw: number
  payment_method: string
  payment_provider: string
  payment_order_id: string
  pg_transaction_id: string | null
  status: string
  refunded_amount_krw: number
  paid_at: string | null
  created_at: string
}

interface CampaignPaymentStats {
  campaign_id: string
  campaign_title: string
  total_paid_krw: number
  total_refunded_krw: number
  payment_count: number
  refund_count: number
  status: string
}

// Mock data
const mockPayments: FundingPayment[] = [
  {
    id: 'pay-001',
    pledge_id: 'pledge-001',
    campaign_id: '1',
    campaign_title: 'WAKER 3rd Mini Album',
    user_id: 'user-1',
    user_name: 'user_kim',
    amount_krw: 500,
    payment_method: 'card',
    payment_provider: 'portone',
    payment_order_id: 'FUND_1_1738000001',
    pg_transaction_id: 'PG_TXN_001',
    status: 'paid',
    refunded_amount_krw: 0,
    paid_at: '2026-02-04T10:30:00Z',
    created_at: '2026-02-04T10:30:00Z',
  },
  {
    id: 'pay-002',
    pledge_id: 'pledge-002',
    campaign_id: '1',
    campaign_title: 'WAKER 3rd Mini Album',
    user_id: 'user-2',
    user_name: 'user_park',
    amount_krw: 2000,
    payment_method: 'card',
    payment_provider: 'portone',
    payment_order_id: 'FUND_1_1738000002',
    pg_transaction_id: 'PG_TXN_002',
    status: 'paid',
    refunded_amount_krw: 0,
    paid_at: '2026-02-04T11:15:00Z',
    created_at: '2026-02-04T11:15:00Z',
  },
  {
    id: 'pay-003',
    pledge_id: 'pledge-003',
    campaign_id: '2',
    campaign_title: 'MOONLIGHT 단독 콘서트',
    user_id: 'user-3',
    user_name: 'user_lee',
    amount_krw: 800,
    payment_method: 'bank_transfer',
    payment_provider: 'portone',
    payment_order_id: 'FUND_2_1738000003',
    pg_transaction_id: 'PG_TXN_003',
    status: 'paid',
    refunded_amount_krw: 0,
    paid_at: '2026-02-05T09:00:00Z',
    created_at: '2026-02-05T09:00:00Z',
  },
  {
    id: 'pay-004',
    pledge_id: 'pledge-004',
    campaign_id: '2',
    campaign_title: 'MOONLIGHT 단독 콘서트',
    user_id: 'user-4',
    user_name: 'user_choi',
    amount_krw: 300,
    payment_method: 'card',
    payment_provider: 'portone',
    payment_order_id: 'FUND_2_1738000004',
    pg_transaction_id: 'PG_TXN_004',
    status: 'refunded',
    refunded_amount_krw: 300,
    paid_at: '2026-02-03T14:00:00Z',
    created_at: '2026-02-03T14:00:00Z',
  },
  {
    id: 'pay-005',
    pledge_id: 'pledge-005',
    campaign_id: '1',
    campaign_title: 'WAKER 3rd Mini Album',
    user_id: 'user-5',
    user_name: 'user_jung',
    amount_krw: 200,
    payment_method: 'card',
    payment_provider: 'portone',
    payment_order_id: 'FUND_1_1738000005',
    pg_transaction_id: null,
    status: 'failed',
    refunded_amount_krw: 0,
    paid_at: null,
    created_at: '2026-02-04T16:45:00Z',
  },
]

const mockCampaignStats: CampaignPaymentStats[] = [
  {
    campaign_id: '1',
    campaign_title: 'WAKER 3rd Mini Album [In Elixir: Spellbound]',
    total_paid_krw: 387500,
    total_refunded_krw: 0,
    payment_count: 156,
    refund_count: 0,
    status: 'active',
  },
  {
    campaign_id: '2',
    campaign_title: 'MOONLIGHT 단독 콘서트 "Under the Moon"',
    total_paid_krw: 780000,
    total_refunded_krw: 300,
    payment_count: 312,
    refund_count: 1,
    status: 'active',
  },
  {
    campaign_id: '3',
    campaign_title: 'STARLIGHT 첫 번째 공식 화보집 "Shine"',
    total_paid_krw: 450000,
    total_refunded_krw: 0,
    payment_count: 189,
    refund_count: 0,
    status: 'completed',
  },
]

async function getPayments(): Promise<FundingPayment[]> {
  if (DEMO_MODE) return mockPayments

  // Static export without Supabase credentials — skip API call
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) return []

  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('funding_payments')
    .select(`
      *,
      funding_pledges!inner(
        campaign_id,
        funding_campaigns!inner(title)
      ),
      user_profiles!inner(display_name)
    `)
    .order('created_at', { ascending: false })
    .limit(100)

  if (error) {
    console.error('Error fetching payments:', error)
    return []
  }

  return (data || []).map((p: Record<string, unknown>) => ({
    id: p.id as string,
    pledge_id: p.pledge_id as string,
    campaign_id: ((p.funding_pledges as Record<string, unknown>)?.campaign_id as string) || '',
    campaign_title: (((p.funding_pledges as Record<string, unknown>)?.funding_campaigns as Record<string, unknown>)?.title as string) || '',
    user_id: p.user_id as string,
    user_name: ((p.user_profiles as Record<string, unknown>)?.display_name as string) || 'Unknown',
    amount_krw: p.amount_krw as number || 0,
    payment_method: p.payment_method as string || 'card',
    payment_provider: p.payment_provider as string || 'portone',
    payment_order_id: p.payment_order_id as string || '',
    pg_transaction_id: p.pg_transaction_id as string | null,
    status: p.status as string || 'pending',
    refunded_amount_krw: p.refunded_amount_krw as number || 0,
    paid_at: p.paid_at as string | null,
    created_at: p.created_at as string,
  }))
}

async function getCampaignStats(): Promise<CampaignPaymentStats[]> {
  if (DEMO_MODE) return mockCampaignStats

  // Static export without Supabase credentials — skip API call
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL) return []

  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('funding_campaigns')
    .select('id, title, status, current_amount_krw, backer_count')
    .in('status', ['active', 'completed', 'funded'])
    .order('created_at', { ascending: false })

  if (error) {
    console.error('Error fetching campaign stats:', error)
    return []
  }

  return (data || []).map((c: Record<string, unknown>) => ({
    campaign_id: c.id as string,
    campaign_title: c.title as string,
    total_paid_krw: c.current_amount_krw as number || 0,
    total_refunded_krw: 0,
    payment_count: c.backer_count as number || 0,
    refund_count: 0,
    status: c.status as string,
  }))
}


export default async function FundingPaymentsPage() {
  const [payments, campaignStats] = await Promise.all([
    getPayments(),
    getCampaignStats(),
  ])

  return (
    <FundingPaymentsClient
      initialPayments={payments}
      campaignStats={campaignStats}
      isDemoMode={DEMO_MODE}
    />
  )
}
