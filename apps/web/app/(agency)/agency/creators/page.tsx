import Link from 'next/link'
import { Users, UserPlus, Search, Filter } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { mockAgencyCreators } from '@/lib/mock/demo-agency-data'
import { formatDate } from '@/lib/utils/format'
import type { AgencyCreator, ContractStatus } from '@/lib/agency/agency-types'

const STATUS_CONFIG: Record<ContractStatus, { label: string; className: string }> = {
  active: { label: '활성', className: 'bg-green-100 text-green-700' },
  pending: { label: '승인 대기', className: 'bg-yellow-100 text-yellow-700' },
  paused: { label: '일시정지', className: 'bg-gray-100 text-gray-600' },
  terminated: { label: '해지', className: 'bg-red-100 text-red-700' },
}

async function getCreators(): Promise<AgencyCreator[]> {
  if (DEMO_MODE) {
    return mockAgencyCreators
  }
  // TODO: Call agency-manage Edge Function with action: creator.list
  return mockAgencyCreators
}

export default async function AgencyCreatorsPage() {
  const creators = await getCreators()

  const activeCount = creators.filter(c => c.status === 'active').length
  const pendingCount = creators.filter(c => c.status === 'pending').length

  return (
    <div className="max-w-6xl mx-auto">
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 샘플 데이터가 표시됩니다
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">소속 크리에이터</h1>
          <p className="text-gray-500 mt-1">
            총 {creators.length}명 (활성 {activeCount}명{pendingCount > 0 ? ` · 대기 ${pendingCount}명` : ''})
          </p>
        </div>
        <Link href="/agency/creators/register">
          <Button>
            <UserPlus className="w-4 h-4 mr-2" />
            크리에이터 등록
          </Button>
        </Link>
      </div>

      {/* Filters (placeholder) */}
      <div className="bg-white rounded-xl border border-gray-200 p-4 mb-6 flex items-center gap-4">
        <div className="flex-1 relative">
          <Search className="w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="크리에이터 이름으로 검색..."
            className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            readOnly
          />
        </div>
        <button className="flex items-center gap-2 px-4 py-2 border border-gray-200 rounded-lg text-sm text-gray-600 hover:bg-gray-50">
          <Filter className="w-4 h-4" />
          필터
        </button>
      </div>

      {/* Creator List */}
      <div className="bg-white rounded-xl border border-gray-200">
        {creators.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Users className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">소속 크리에이터가 없습니다</h3>
            <p className="text-gray-500 mb-4">크리에이터를 등록하여 시작하세요</p>
            <Link href="/agency/creators/register">
              <Button>
                <UserPlus className="w-4 h-4 mr-2" />
                크리에이터 등록
              </Button>
            </Link>
          </div>
        ) : (
          <>
            {/* Table Header */}
            <div className="hidden md:grid grid-cols-12 gap-4 p-4 border-b border-gray-200 bg-gray-50 rounded-t-xl text-sm font-medium text-gray-500">
              <div className="col-span-4">크리에이터</div>
              <div className="col-span-2">상태</div>
              <div className="col-span-2">수수료율</div>
              <div className="col-span-2">계약기간</div>
              <div className="col-span-2 text-right">액션</div>
            </div>

            {/* Table Body */}
            <div className="divide-y divide-gray-100">
              {creators.map((ac) => {
                const statusConfig = STATUS_CONFIG[ac.status]
                return (
                  <div key={ac.id} className="grid grid-cols-1 md:grid-cols-12 gap-4 p-4 items-center hover:bg-gray-50 transition-colors">
                    {/* Creator Info */}
                    <div className="col-span-4 flex items-center gap-3">
                      <div className="w-10 h-10 bg-gray-100 rounded-full overflow-hidden flex-shrink-0">
                        {ac.creator?.avatar_url ? (
                          <img
                            src={ac.creator.avatar_url}
                            alt={ac.creator.stage_name || ''}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-gray-400">
                            <Users className="w-5 h-5" />
                          </div>
                        )}
                      </div>
                      <div className="min-w-0">
                        <div className="font-medium text-gray-900 truncate">
                          {ac.creator?.stage_name || '알 수 없음'}
                        </div>
                        <div className="text-xs text-gray-500">
                          구독자 {ac.creator?.subscriber_count?.toLocaleString() || 0}명
                          {ac.creator?.categories?.length ? ` · ${ac.creator.categories.join(', ')}` : ''}
                        </div>
                      </div>
                    </div>

                    {/* Status */}
                    <div className="col-span-2">
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${statusConfig.className}`}>
                        {statusConfig.label}
                      </span>
                    </div>

                    {/* Revenue Share */}
                    <div className="col-span-2 text-sm text-gray-700">
                      {(ac.revenue_share_rate * 100).toFixed(0)}%
                      {ac.power_of_attorney_url && (
                        <span className="ml-1 text-xs text-indigo-600">(통합)</span>
                      )}
                    </div>

                    {/* Contract Period */}
                    <div className="col-span-2 text-sm text-gray-500">
                      {ac.contract_start_date ? formatDate(ac.contract_start_date) : '-'}
                      {ac.contract_end_date ? ` ~ ${formatDate(ac.contract_end_date)}` : ac.contract_start_date ? ' ~ 무기한' : ''}
                    </div>

                    {/* Actions */}
                    <div className="col-span-2 flex justify-end">
                      <Link href={`/agency/creators/${ac.id}`}>
                        <Button variant="outline" size="sm">
                          상세보기
                        </Button>
                      </Link>
                    </div>
                  </div>
                )
              })}
            </div>
          </>
        )}
      </div>
    </div>
  )
}
