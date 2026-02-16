import {
  Users,
  TrendingUp,
  TrendingDown,
  Wallet,
  Clock,
  UserPlus,
  BarChart3,
  Receipt,
  ArrowRight,
} from 'lucide-react'
import Link from 'next/link'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import {
  getAgencyDashboard,
  getRecentCreators,
  getRecentSettlements,
} from '@/lib/agency/agency-client'
import { formatKRW, formatDate } from '@/lib/utils/format'
import type { AgencyDashboardSummary, AgencyCreator, AgencySettlement } from '@/lib/agency/agency-types'

async function getDashboardData(): Promise<AgencyDashboardSummary> {
  return getAgencyDashboard()
}

const STATUS_BADGES: Record<string, { label: string; className: string }> = {
  active: { label: '활성', className: 'bg-green-100 text-green-700' },
  pending: { label: '대기', className: 'bg-yellow-100 text-yellow-700' },
  paused: { label: '일시정지', className: 'bg-gray-100 text-gray-600' },
  terminated: { label: '해지', className: 'bg-red-100 text-red-700' },
  draft: { label: '초안', className: 'bg-gray-100 text-gray-600' },
  pending_review: { label: '검토 대기', className: 'bg-yellow-100 text-yellow-700' },
  approved: { label: '승인', className: 'bg-blue-100 text-blue-700' },
  processing: { label: '처리중', className: 'bg-indigo-100 text-indigo-700' },
  paid: { label: '지급완료', className: 'bg-green-100 text-green-700' },
  rejected: { label: '반려', className: 'bg-red-100 text-red-700' },
}

function StatusBadge({ status }: { status: string }) {
  const badge = STATUS_BADGES[status] || { label: status, className: 'bg-gray-100 text-gray-600' }
  return (
    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${badge.className}`}>
      {badge.label}
    </span>
  )
}

export default async function AgencyDashboardPage() {
  const [dashboard, creators, settlements] = await Promise.all([
    getDashboardData(),
    getRecentCreators(),
    getRecentSettlements(),
  ])

  const revenueChange = dashboard.previousMonthKRW > 0
    ? ((dashboard.currentMonthKRW - dashboard.previousMonthKRW) / dashboard.previousMonthKRW) * 100
    : 0
  const isRevenueUp = revenueChange >= 0

  return (
    <div className="max-w-6xl mx-auto">
      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 샘플 데이터가 표시됩니다
        </div>
      )}

      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">{dashboard.agency.name}</h1>
        <p className="text-gray-500 mt-1">소속사 대시보드</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {/* Active Creators */}
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
              <Users className="w-5 h-5 text-indigo-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{dashboard.activeCreators}</div>
              <div className="text-sm text-gray-500">활성 크리에이터</div>
            </div>
          </div>
          {dashboard.pendingContracts > 0 && (
            <div className="mt-2 text-xs text-yellow-600">
              + {dashboard.pendingContracts}건 승인 대기
            </div>
          )}
        </div>

        {/* Monthly Revenue */}
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <Wallet className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{formatKRW(dashboard.currentMonthKRW)}</div>
              <div className="text-sm text-gray-500">이번달 수익</div>
            </div>
          </div>
          <div className={`mt-2 text-xs flex items-center gap-1 ${isRevenueUp ? 'text-green-600' : 'text-red-600'}`}>
            {isRevenueUp ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
            전월 대비 {Math.abs(revenueChange).toFixed(1)}%
          </div>
        </div>

        {/* Monthly DT */}
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <BarChart3 className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">
                {new Intl.NumberFormat('ko-KR').format(dashboard.currentMonthDT)} DT
              </div>
              <div className="text-sm text-gray-500">이번달 DT</div>
            </div>
          </div>
        </div>

        {/* Latest Settlement */}
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
              <Receipt className="w-5 h-5 text-amber-600" />
            </div>
            <div>
              {dashboard.latestSettlement ? (
                <>
                  <div className="text-2xl font-bold text-gray-900">
                    {formatKRW(dashboard.latestSettlement.agency_net_krw)}
                  </div>
                  <div className="text-sm text-gray-500">
                    최근 정산 ({dashboard.latestSettlement.period_start.slice(5, 7)}월)
                  </div>
                </>
              ) : (
                <>
                  <div className="text-2xl font-bold text-gray-400">-</div>
                  <div className="text-sm text-gray-500">정산 내역 없음</div>
                </>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Quick Links */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <Link
          href="/agency/creators/register"
          className="bg-white rounded-xl p-4 border border-gray-200 hover:border-indigo-300 hover:shadow-sm transition-all group"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
              <UserPlus className="w-5 h-5 text-indigo-600" />
            </div>
            <div className="flex-1">
              <div className="font-medium text-gray-900 group-hover:text-indigo-600">크리에이터 등록</div>
              <div className="text-sm text-gray-500">새 크리에이터 계약</div>
            </div>
            <ArrowRight className="w-4 h-4 text-gray-400 group-hover:text-indigo-500" />
          </div>
        </Link>
        <Link
          href="/agency/settlements"
          className="bg-white rounded-xl p-4 border border-gray-200 hover:border-green-300 hover:shadow-sm transition-all group"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <Wallet className="w-5 h-5 text-green-600" />
            </div>
            <div className="flex-1">
              <div className="font-medium text-gray-900 group-hover:text-green-600">정산 확인</div>
              <div className="text-sm text-gray-500">정산 내역 조회</div>
            </div>
            <ArrowRight className="w-4 h-4 text-gray-400 group-hover:text-green-500" />
          </div>
        </Link>
        <Link
          href="/agency/statistics"
          className="bg-white rounded-xl p-4 border border-gray-200 hover:border-purple-300 hover:shadow-sm transition-all group"
        >
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <BarChart3 className="w-5 h-5 text-purple-600" />
            </div>
            <div className="flex-1">
              <div className="font-medium text-gray-900 group-hover:text-purple-600">통계 보기</div>
              <div className="text-sm text-gray-500">크리에이터별 실적</div>
            </div>
            <ArrowRight className="w-4 h-4 text-gray-400 group-hover:text-purple-500" />
          </div>
        </Link>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Creators */}
        <div className="bg-white rounded-xl border border-gray-200">
          <div className="p-4 border-b border-gray-200 flex items-center justify-between">
            <h2 className="font-semibold text-gray-900">소속 크리에이터</h2>
            <Link href="/agency/creators" className="text-sm text-indigo-600 hover:text-indigo-800">
              전체 보기
            </Link>
          </div>
          {creators.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              소속 크리에이터가 없습니다
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {creators.map((ac) => (
                <div key={ac.id} className="p-4 flex items-center gap-3">
                  <div className="w-10 h-10 bg-gray-100 rounded-full overflow-hidden flex-shrink-0">
                    {ac.creator?.avatar_url ? (
                      <img
                        src={ac.creator.avatar_url}
                        alt={ac.creator.stage_name || ''}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-400 text-xs">
                        <Users className="w-5 h-5" />
                      </div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="font-medium text-gray-900 truncate">
                      {ac.creator?.stage_name || '알 수 없음'}
                    </div>
                    <div className="text-xs text-gray-500">
                      구독자 {ac.creator?.subscriber_count?.toLocaleString() || 0}명 · 수수료 {(ac.revenue_share_rate * 100).toFixed(0)}%
                    </div>
                  </div>
                  <StatusBadge status={ac.status} />
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Recent Settlements */}
        <div className="bg-white rounded-xl border border-gray-200">
          <div className="p-4 border-b border-gray-200 flex items-center justify-between">
            <h2 className="font-semibold text-gray-900">최근 정산</h2>
            <Link href="/agency/settlements" className="text-sm text-indigo-600 hover:text-indigo-800">
              전체 보기
            </Link>
          </div>
          {settlements.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              정산 내역이 없습니다
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {settlements.map((s) => (
                <Link
                  key={s.id}
                  href={`/agency/settlements/${s.id}`}
                  className="p-4 flex items-center gap-3 hover:bg-gray-50 transition-colors block"
                >
                  <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Clock className="w-5 h-5 text-gray-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="font-medium text-gray-900">
                      {s.period_start.slice(0, 7)} 정산
                    </div>
                    <div className="text-xs text-gray-500">
                      {s.total_creators}명 · 소속사 수수료 {formatKRW(s.agency_commission_krw)}
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <div className="font-medium text-gray-900">{formatKRW(s.agency_net_krw)}</div>
                    <StatusBadge status={s.status} />
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
