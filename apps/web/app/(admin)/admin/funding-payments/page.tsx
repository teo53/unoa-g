import { CreditCard, CheckCircle, XCircle, RefreshCw, AlertTriangle, Eye, ArrowRight } from 'lucide-react'
import { DEMO_MODE, mockCampaigns } from '@/lib/mock/demo-data'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { formatKRW, formatDate, formatDateTime } from '@/lib/utils/format'

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

function getStatusBadge(status: string) {
  switch (status) {
    case 'paid':
      return <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">결제 완료</Badge>
    case 'pending':
      return <Badge variant="outline" className="bg-yellow-50 text-yellow-700 border-yellow-200">대기중</Badge>
    case 'failed':
      return <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">실패</Badge>
    case 'cancelled':
      return <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-200">취소</Badge>
    case 'refunded':
      return <Badge variant="outline" className="bg-orange-50 text-orange-700 border-orange-200">환불</Badge>
    case 'partial_refunded':
      return <Badge variant="outline" className="bg-orange-50 text-orange-600 border-orange-200">부분환불</Badge>
    default:
      return <Badge variant="outline">{status}</Badge>
  }
}

function getPaymentMethodLabel(method: string) {
  switch (method) {
    case 'card': return '카드'
    case 'bank_transfer': return '계좌이체'
    case 'virtual_account': return '가상계좌'
    default: return method
  }
}

function getCampaignStatusBadge(status: string) {
  switch (status) {
    case 'active':
      return <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">진행중</Badge>
    case 'completed':
      return <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">완료</Badge>
    case 'funded':
      return <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200">달성</Badge>
    default:
      return <Badge variant="outline">{status}</Badge>
  }
}

export default async function FundingPaymentsPage() {
  const [payments, campaignStats] = await Promise.all([
    getPayments(),
    getCampaignStats(),
  ])

  const totalPaid = payments.filter(p => p.status === 'paid').reduce((sum, p) => sum + p.amount_krw, 0)
  const totalRefunded = payments.filter(p => p.status === 'refunded' || p.status === 'partial_refunded')
    .reduce((sum, p) => sum + p.refunded_amount_krw, 0)
  const failedCount = payments.filter(p => p.status === 'failed').length

  return (
    <div className="max-w-6xl mx-auto">
      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          Demo Mode - Mock payment data is displayed
        </div>
      )}

      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">펀딩 결제 관리</h1>
        <p className="text-gray-500 mt-1">캠페인별 KRW 결제 현황, 환불, 분쟁 관리</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <CreditCard className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(totalPaid)}</div>
              <div className="text-sm text-gray-500">총 결제 금액</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
              <RefreshCw className="w-5 h-5 text-orange-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(totalRefunded)}</div>
              <div className="text-sm text-gray-500">총 환불 금액</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <CheckCircle className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">
                {payments.filter(p => p.status === 'paid').length}
              </div>
              <div className="text-sm text-gray-500">성공 결제</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
              <AlertTriangle className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{failedCount}</div>
              <div className="text-sm text-gray-500">실패 건수</div>
            </div>
          </div>
        </div>
      </div>

      {/* Campaign Payment Summary */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden mb-8">
        <div className="p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">캠페인별 결제 현황</h2>
        </div>
        <div className="divide-y divide-gray-100">
          {campaignStats.map((c) => (
            <div key={c.campaign_id} className="p-4 hover:bg-gray-50 transition-colors flex items-center justify-between">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h3 className="font-medium text-gray-900 truncate">{c.campaign_title}</h3>
                  {getCampaignStatusBadge(c.status)}
                </div>
                <div className="flex items-center gap-4 mt-1 text-sm text-gray-500">
                  <span>결제: {c.payment_count}건</span>
                  <span>총액: {formatKRW(c.total_paid_krw)}</span>
                  {c.refund_count > 0 && (
                    <span className="text-orange-500">환불: {c.refund_count}건 ({formatKRW(c.total_refunded_krw)})</span>
                  )}
                </div>
              </div>
              <Button size="sm" variant="ghost">
                <ArrowRight className="w-4 h-4" />
              </Button>
            </div>
          ))}
        </div>
      </div>

      {/* Recent Payments Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="p-4 border-b border-gray-200 flex items-center justify-between">
          <h2 className="font-semibold text-gray-900">최근 결제 내역</h2>
          <div className="flex items-center gap-2 text-sm">
            <span className="text-gray-500">필터:</span>
            <button className="px-3 py-1 rounded-lg bg-gray-900 text-white text-sm">전체</button>
            <button className="px-3 py-1 rounded-lg bg-gray-100 text-gray-600 text-sm hover:bg-gray-200">결제</button>
            <button className="px-3 py-1 rounded-lg bg-gray-100 text-gray-600 text-sm hover:bg-gray-200">환불</button>
            <button className="px-3 py-1 rounded-lg bg-gray-100 text-gray-600 text-sm hover:bg-gray-200">실패</button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-gray-500 text-left">
              <tr>
                <th className="px-4 py-3 font-medium">주문번호</th>
                <th className="px-4 py-3 font-medium">캠페인</th>
                <th className="px-4 py-3 font-medium">사용자</th>
                <th className="px-4 py-3 font-medium text-right">결제 금액</th>
                <th className="px-4 py-3 font-medium">결제수단</th>
                <th className="px-4 py-3 font-medium">PG 거래ID</th>
                <th className="px-4 py-3 font-medium">상태</th>
                <th className="px-4 py-3 font-medium">결제일시</th>
                <th className="px-4 py-3 font-medium text-center">액션</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {payments.map((p) => (
                <tr key={p.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3">
                    <span className="font-mono text-xs text-gray-500">{p.payment_order_id}</span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="text-gray-900 truncate block max-w-[150px]">{p.campaign_title}</span>
                  </td>
                  <td className="px-4 py-3 text-gray-600">{p.user_name}</td>
                  <td className="px-4 py-3 text-right font-medium text-gray-900">
                    {formatKRW(p.amount_krw)}
                    {p.refunded_amount_krw > 0 && (
                      <div className="text-xs text-orange-500">환불: {formatKRW(p.refunded_amount_krw)}</div>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <span className="text-xs px-2 py-1 rounded bg-gray-100 text-gray-600">
                      {getPaymentMethodLabel(p.payment_method)}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className="font-mono text-xs text-gray-400">
                      {p.pg_transaction_id || '-'}
                    </span>
                  </td>
                  <td className="px-4 py-3">{getStatusBadge(p.status)}</td>
                  <td className="px-4 py-3 text-gray-500 text-xs">
                    {p.paid_at ? formatDateTime(p.paid_at) : '-'}
                  </td>
                  <td className="px-4 py-3 text-center">
                    <div className="flex items-center justify-center gap-1">
                      <Button size="sm" variant="ghost" className="h-8 w-8 p-0">
                        <Eye className="w-4 h-4" />
                      </Button>
                      {p.status === 'paid' && (
                        <Button size="sm" variant="outline" className="h-8 px-2 text-orange-600 border-orange-200 text-xs">
                          환불
                        </Button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
