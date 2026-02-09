import { Clock, CheckCircle, XCircle, FileText, Download, Eye } from 'lucide-react'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { formatKRW, formatDate } from '@/lib/utils/format'

// =====================================================
// Admin Settlement Management Page
// - 정산 대기 목록 (pending_review)
// - 승인/거절 기능
// - 정산 상세 (DT/KRW 수익 분리 표시)
// =====================================================

interface Settlement {
  id: string
  creator_id: string
  creator_name: string
  period_start: string
  period_end: string
  dt_total_gross: number
  dt_revenue_krw: number
  funding_revenue_krw: number
  total_revenue_krw: number
  platform_fee_krw: number
  income_type: string
  tax_rate: number
  withholding_tax_krw: number
  net_payout_krw: number
  status: string
  created_at: string
}

// Mock settlements for demo mode
const mockSettlements: Settlement[] = [
  {
    id: 'settle-001',
    creator_id: 'demo-creator-1',
    creator_name: 'WAKER',
    period_start: '2026-01-01',
    period_end: '2026-01-31',
    dt_total_gross: 125000,
    dt_revenue_krw: 125000,
    funding_revenue_krw: 387500,
    total_revenue_krw: 512500,
    platform_fee_krw: 102500,
    income_type: 'business_income',
    tax_rate: 3.3,
    withholding_tax_krw: 13530,
    net_payout_krw: 396470,
    status: 'pending_review',
    created_at: '2026-02-01T00:00:00Z',
  },
  {
    id: 'settle-002',
    creator_id: 'demo-creator-2',
    creator_name: 'MOONLIGHT',
    period_start: '2026-01-01',
    period_end: '2026-01-31',
    dt_total_gross: 85000,
    dt_revenue_krw: 85000,
    funding_revenue_krw: 780000,
    total_revenue_krw: 865000,
    platform_fee_krw: 173000,
    income_type: 'other_income',
    tax_rate: 8.8,
    withholding_tax_krw: 60896,
    net_payout_krw: 631104,
    status: 'pending_review',
    created_at: '2026-02-01T00:00:00Z',
  },
  {
    id: 'settle-003',
    creator_id: 'demo-creator-3',
    creator_name: 'STARLIGHT',
    period_start: '2025-12-01',
    period_end: '2025-12-31',
    dt_total_gross: 45000,
    dt_revenue_krw: 45000,
    funding_revenue_krw: 450000,
    total_revenue_krw: 495000,
    platform_fee_krw: 99000,
    income_type: 'business_income',
    tax_rate: 3.3,
    withholding_tax_krw: 13068,
    net_payout_krw: 382932,
    status: 'approved',
    created_at: '2026-01-01T00:00:00Z',
  },
  {
    id: 'settle-004',
    creator_id: 'demo-creator-1',
    creator_name: 'WAKER',
    period_start: '2025-12-01',
    period_end: '2025-12-31',
    dt_total_gross: 98000,
    dt_revenue_krw: 98000,
    funding_revenue_krw: 250000,
    total_revenue_krw: 348000,
    platform_fee_krw: 69600,
    income_type: 'business_income',
    tax_rate: 3.3,
    withholding_tax_krw: 9187,
    net_payout_krw: 269213,
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

async function getStats() {
  if (DEMO_MODE) {
    return {
      pendingReview: mockSettlements.filter(s => s.status === 'pending_review').length,
      approved: mockSettlements.filter(s => s.status === 'approved').length,
      paid: mockSettlements.filter(s => s.status === 'paid').length,
      totalPayoutKrw: mockSettlements.reduce((sum, s) => sum + s.net_payout_krw, 0),
    }
  }

  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  const [pending, approved, paid] = await Promise.all([
    supabase.from('payouts').select('id', { count: 'exact' }).eq('status', 'pending_review'),
    supabase.from('payouts').select('id', { count: 'exact' }).eq('status', 'approved'),
    supabase.from('payouts').select('id', { count: 'exact' }).eq('status', 'paid'),
  ])

  return {
    pendingReview: pending.count || 0,
    approved: approved.count || 0,
    paid: paid.count || 0,
    totalPayoutKrw: 0,
  }
}

function getStatusBadge(status: string) {
  switch (status) {
    case 'pending_review':
      return <Badge variant="outline" className="bg-yellow-50 text-yellow-700 border-yellow-200">심사 대기</Badge>
    case 'approved':
      return <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">승인됨</Badge>
    case 'paid':
      return <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">지급 완료</Badge>
    case 'rejected':
      return <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">반려</Badge>
    default:
      return <Badge variant="outline">{status}</Badge>
  }
}

function getIncomeTypeLabel(type: string) {
  switch (type) {
    case 'business_income': return '사업소득 3.3%'
    case 'other_income': return '기타소득 8.8%'
    case 'invoice': return '세금계산서 0%'
    default: return type
  }
}

export default async function SettlementsPage() {
  const [settlements, stats] = await Promise.all([
    getSettlements(),
    getStats(),
  ])

  return (
    <div className="max-w-6xl mx-auto">
      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          Demo Mode - Mock settlement data is displayed
        </div>
      )}

      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">정산 관리</h1>
          <p className="text-gray-500 mt-1">크리에이터 정산 심사 및 지급 관리</p>
        </div>
        <Button variant="outline" size="sm">
          <Download className="w-4 h-4 mr-1" />
          CSV 내보내기
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-yellow-100 rounded-lg flex items-center justify-center">
              <Clock className="w-5 h-5 text-yellow-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{stats.pendingReview}</div>
              <div className="text-sm text-gray-500">심사 대기</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <CheckCircle className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{stats.approved}</div>
              <div className="text-sm text-gray-500">승인됨</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <CheckCircle className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{stats.paid}</div>
              <div className="text-sm text-gray-500">지급 완료</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <FileText className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(stats.totalPayoutKrw)}</div>
              <div className="text-sm text-gray-500">총 지급액</div>
            </div>
          </div>
        </div>
      </div>

      {/* Settlements Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="p-4 border-b border-gray-200 flex items-center justify-between">
          <h2 className="font-semibold text-gray-900">정산 내역</h2>
          <div className="flex items-center gap-2 text-sm">
            <span className="text-gray-500">필터:</span>
            <button className="px-3 py-1 rounded-lg bg-gray-900 text-white text-sm">전체</button>
            <button className="px-3 py-1 rounded-lg bg-gray-100 text-gray-600 text-sm hover:bg-gray-200">심사 대기</button>
            <button className="px-3 py-1 rounded-lg bg-gray-100 text-gray-600 text-sm hover:bg-gray-200">승인</button>
            <button className="px-3 py-1 rounded-lg bg-gray-100 text-gray-600 text-sm hover:bg-gray-200">지급</button>
          </div>
        </div>

        {settlements.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <CheckCircle className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">정산 내역 없음</h3>
            <p className="text-gray-500">처리할 정산이 없습니다</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 text-left">
                <tr>
                  <th className="px-4 py-3 font-medium">크리에이터</th>
                  <th className="px-4 py-3 font-medium">정산 기간</th>
                  <th className="px-4 py-3 font-medium text-right">DT 수익</th>
                  <th className="px-4 py-3 font-medium text-right">펀딩 수익</th>
                  <th className="px-4 py-3 font-medium text-right">총 수익</th>
                  <th className="px-4 py-3 font-medium text-right">수수료</th>
                  <th className="px-4 py-3 font-medium">세율</th>
                  <th className="px-4 py-3 font-medium text-right">원천징수</th>
                  <th className="px-4 py-3 font-medium text-right">순 지급액</th>
                  <th className="px-4 py-3 font-medium">상태</th>
                  <th className="px-4 py-3 font-medium text-center">액션</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {settlements.map((s) => (
                  <tr key={s.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-900">{s.creator_name}</div>
                      <div className="text-xs text-gray-400">{s.creator_id.slice(0, 12)}...</div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">
                      {formatDate(s.period_start)} ~ {formatDate(s.period_end)}
                    </td>
                    <td className="px-4 py-3 text-right text-gray-600">
                      {formatKRW(s.dt_revenue_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-blue-600 font-medium">
                      {formatKRW(s.funding_revenue_krw)}
                    </td>
                    <td className="px-4 py-3 text-right font-medium text-gray-900">
                      {formatKRW(s.total_revenue_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-gray-500">
                      -{formatKRW(s.platform_fee_krw)}
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-xs px-2 py-1 rounded bg-gray-100 text-gray-600">
                        {getIncomeTypeLabel(s.income_type)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right text-red-500">
                      -{formatKRW(s.withholding_tax_krw)}
                    </td>
                    <td className="px-4 py-3 text-right font-bold text-gray-900">
                      {formatKRW(s.net_payout_krw)}
                    </td>
                    <td className="px-4 py-3">
                      {getStatusBadge(s.status)}
                    </td>
                    <td className="px-4 py-3 text-center">
                      <div className="flex items-center justify-center gap-1">
                        <Button size="sm" variant="ghost" className="h-8 w-8 p-0">
                          <Eye className="w-4 h-4" />
                        </Button>
                        {s.status === 'pending_review' && (
                          <>
                            <Button size="sm" className="h-8 px-2 bg-green-600 hover:bg-green-700 text-white text-xs">
                              승인
                            </Button>
                            <Button size="sm" variant="outline" className="h-8 px-2 text-red-600 border-red-200 text-xs">
                              반려
                            </Button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}
