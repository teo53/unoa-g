import { BarChart3, TrendingUp, Users } from 'lucide-react'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { mockAgencyCreators, mockAgencySettlements } from '@/lib/mock/demo-agency-data'
import { formatKRW } from '@/lib/utils/format'

export default async function AgencyStatisticsPage() {
  const creators = mockAgencyCreators.filter(c => c.status === 'active')
  const totalGross = mockAgencySettlements.reduce((sum, s) => sum + s.total_gross_krw, 0)
  const totalCommission = mockAgencySettlements.reduce((sum, s) => sum + s.agency_commission_krw, 0)

  return (
    <div className="max-w-6xl mx-auto">
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 샘플 데이터가 표시됩니다
        </div>
      )}

      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">전체 통계</h1>
        <p className="text-gray-500 mt-1">크리에이터별 실적 및 트렌드</p>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-indigo-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{creators.length}</div>
              <div className="text-sm text-gray-500">활성 크리에이터</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{formatKRW(totalGross)}</div>
              <div className="text-sm text-gray-500">총 매출</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <BarChart3 className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{formatKRW(totalCommission)}</div>
              <div className="text-sm text-gray-500">총 수수료</div>
            </div>
          </div>
        </div>
      </div>

      {/* Creator Performance Table */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">크리에이터별 실적</h2>
        </div>

        <div className="hidden md:grid grid-cols-12 gap-4 p-4 border-b border-gray-100 bg-gray-50 text-sm font-medium text-gray-500">
          <div className="col-span-4">크리에이터</div>
          <div className="col-span-2 text-right">구독자</div>
          <div className="col-span-2 text-right">수수료율</div>
          <div className="col-span-2 text-right">최근 정산</div>
          <div className="col-span-2 text-right">소속사 수수료</div>
        </div>

        <div className="divide-y divide-gray-100">
          {creators.map((ac) => {
            const latestBreakdown = mockAgencySettlements[0]?.creator_breakdown
              .find(cb => cb.creator_id === ac.creator_profile_id)
            return (
              <div key={ac.id} className="grid grid-cols-1 md:grid-cols-12 gap-4 p-4 items-center">
                <div className="col-span-4 flex items-center gap-3">
                  <div className="w-10 h-10 bg-gray-100 rounded-full overflow-hidden flex-shrink-0">
                    {ac.creator?.avatar_url ? (
                      <img src={ac.creator.avatar_url} alt="" className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-400">
                        <Users className="w-5 h-5" />
                      </div>
                    )}
                  </div>
                  <div>
                    <div className="font-medium text-gray-900">{ac.creator?.stage_name || '-'}</div>
                    <div className="text-xs text-gray-500">{ac.creator?.categories?.join(', ')}</div>
                  </div>
                </div>
                <div className="col-span-2 text-right text-sm text-gray-700">
                  {ac.creator?.subscriber_count?.toLocaleString() || 0}명
                </div>
                <div className="col-span-2 text-right text-sm text-gray-700">
                  {(ac.revenue_share_rate * 100).toFixed(0)}%
                </div>
                <div className="col-span-2 text-right text-sm text-gray-700">
                  {latestBreakdown ? formatKRW(latestBreakdown.net_krw) : '-'}
                </div>
                <div className="col-span-2 text-right text-sm font-medium text-indigo-600">
                  {latestBreakdown ? formatKRW(latestBreakdown.agency_commission_krw) : '-'}
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Chart placeholder */}
      <div className="bg-white rounded-xl border border-gray-200 p-6 mt-6">
        <h2 className="font-semibold text-gray-900 mb-4">월별 매출 추이</h2>
        <div className="h-48 bg-gray-50 rounded-lg flex items-center justify-center text-gray-400 text-sm">
          차트 영역 (향후 구현)
        </div>
      </div>
    </div>
  )
}
