import { FileText, Download, TrendingUp, Calculator, Users } from 'lucide-react'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { formatKRW, formatDate } from '@/lib/utils/format'

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

function getIncomeTypeBadge(type: string) {
  switch (type) {
    case 'business_income':
      return <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">사업소득 3.3%</Badge>
    case 'other_income':
      return <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200">기타소득 8.8%</Badge>
    case 'invoice':
      return <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">세금계산서 0%</Badge>
    default:
      return <Badge variant="outline">{type}</Badge>
  }
}

export default async function TaxReportsPage() {
  const summaries = await getTaxSummaries()

  const totalRevenue = summaries.reduce((sum, s) => sum + s.total_revenue_krw, 0)
  const totalFees = summaries.reduce((sum, s) => sum + s.platform_fee_krw, 0)
  const totalWithholding = summaries.reduce((sum, s) => sum + s.withholding_total_krw, 0)
  const totalPayout = summaries.reduce((sum, s) => sum + s.net_payout_krw, 0)

  return (
    <div className="max-w-6xl mx-auto">
      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          Demo Mode - Mock tax data is displayed
        </div>
      )}

      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">세금 보고서</h1>
          <p className="text-gray-500 mt-1">원천징수 내역 및 크리에이터별 소득 집계 (2026년)</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm">
            <Download className="w-4 h-4 mr-1" />
            원천징수 CSV
          </Button>
          <Button variant="outline" size="sm">
            <Download className="w-4 h-4 mr-1" />
            소득 집계 CSV
          </Button>
        </div>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(totalRevenue)}</div>
              <div className="text-sm text-gray-500">총 수익</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
              <FileText className="w-5 h-5 text-orange-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(totalFees)}</div>
              <div className="text-sm text-gray-500">플랫폼 수수료</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
              <Calculator className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(totalWithholding)}</div>
              <div className="text-sm text-gray-500">원천징수 합계</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{summaries.length}</div>
              <div className="text-sm text-gray-500">크리에이터</div>
            </div>
          </div>
        </div>
      </div>

      {/* Income Type Distribution */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        {['business_income', 'other_income', 'invoice'].map(type => {
          const creators = summaries.filter(s => s.income_type === type)
          const typeTotal = creators.reduce((sum, s) => sum + s.withholding_total_krw, 0)
          const labels: Record<string, string> = {
            business_income: '사업소득 (3.3%)',
            other_income: '기타소득 (8.8%)',
            invoice: '세금계산서 (0%)',
          }
          return (
            <div key={type} className="bg-white rounded-xl p-4 border border-gray-200">
              <div className="text-sm text-gray-500 mb-1">{labels[type]}</div>
              <div className="text-xl font-bold text-gray-900">{creators.length}명</div>
              <div className="text-sm text-gray-500 mt-1">원천징수: {formatKRW(typeTotal)}</div>
            </div>
          )
        })}
      </div>

      {/* Creator Tax Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">크리에이터별 원천징수 내역</h2>
        </div>

        {summaries.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <FileText className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">데이터 없음</h3>
            <p className="text-gray-500">해당 기간의 정산 데이터가 없습니다</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 text-left">
                <tr>
                  <th className="px-4 py-3 font-medium">크리에이터</th>
                  <th className="px-4 py-3 font-medium">소득 유형</th>
                  <th className="px-4 py-3 font-medium text-right">총 수익</th>
                  <th className="px-4 py-3 font-medium text-right">플랫폼 수수료</th>
                  <th className="px-4 py-3 font-medium text-right">과세 대상</th>
                  <th className="px-4 py-3 font-medium text-right">소득세</th>
                  <th className="px-4 py-3 font-medium text-right">지방소득세</th>
                  <th className="px-4 py-3 font-medium text-right">원천징수 합계</th>
                  <th className="px-4 py-3 font-medium text-right">순 지급액</th>
                  <th className="px-4 py-3 font-medium text-center">정산 수</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {summaries.map((s) => (
                  <tr key={s.creator_id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-900">{s.creator_name}</div>
                    </td>
                    <td className="px-4 py-3">
                      {getIncomeTypeBadge(s.income_type)}
                    </td>
                    <td className="px-4 py-3 text-right font-medium text-gray-900">
                      {formatKRW(s.total_revenue_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-gray-500">
                      -{formatKRW(s.platform_fee_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-gray-700">
                      {formatKRW(s.taxable_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-red-500">
                      -{formatKRW(s.income_tax_krw)}
                    </td>
                    <td className="px-4 py-3 text-right text-red-400">
                      -{formatKRW(s.local_tax_krw)}
                    </td>
                    <td className="px-4 py-3 text-right font-medium text-red-600">
                      -{formatKRW(s.withholding_total_krw)}
                    </td>
                    <td className="px-4 py-3 text-right font-bold text-gray-900">
                      {formatKRW(s.net_payout_krw)}
                    </td>
                    <td className="px-4 py-3 text-center text-gray-600">
                      {s.settlement_count}
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-gray-50 font-medium text-gray-900">
                <tr>
                  <td className="px-4 py-3">합계</td>
                  <td className="px-4 py-3"></td>
                  <td className="px-4 py-3 text-right">{formatKRW(totalRevenue)}</td>
                  <td className="px-4 py-3 text-right text-gray-500">-{formatKRW(totalFees)}</td>
                  <td className="px-4 py-3 text-right">{formatKRW(totalRevenue - totalFees)}</td>
                  <td className="px-4 py-3 text-right text-red-500">
                    -{formatKRW(summaries.reduce((s, c) => s + c.income_tax_krw, 0))}
                  </td>
                  <td className="px-4 py-3 text-right text-red-400">
                    -{formatKRW(summaries.reduce((s, c) => s + c.local_tax_krw, 0))}
                  </td>
                  <td className="px-4 py-3 text-right text-red-600">-{formatKRW(totalWithholding)}</td>
                  <td className="px-4 py-3 text-right font-bold">{formatKRW(totalPayout)}</td>
                  <td className="px-4 py-3 text-center">
                    {summaries.reduce((s, c) => s + c.settlement_count, 0)}
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        )}
      </div>

      {/* Tax Info Card */}
      <div className="mt-8 bg-blue-50 rounded-xl border border-blue-200 p-6">
        <h3 className="font-semibold text-blue-900 mb-3">원천징수 안내</h3>
        <div className="grid grid-cols-3 gap-6 text-sm text-blue-800">
          <div>
            <div className="font-medium mb-1">사업소득 (3.3%)</div>
            <p className="text-blue-600">소득세 3.0% + 지방소득세 0.3%</p>
            <p className="text-blue-600">개인 크리에이터 기본 적용</p>
          </div>
          <div>
            <div className="font-medium mb-1">기타소득 (8.8%)</div>
            <p className="text-blue-600">소득세 8.0% + 지방소득세 0.8%</p>
            <p className="text-blue-600">일회성/비정기 소득에 적용</p>
          </div>
          <div>
            <div className="font-medium mb-1">세금계산서 (0%)</div>
            <p className="text-blue-600">사업자 등록 크리에이터</p>
            <p className="text-blue-600">원천징수 없이 세금계산서 발행</p>
          </div>
        </div>
      </div>
    </div>
  )
}
