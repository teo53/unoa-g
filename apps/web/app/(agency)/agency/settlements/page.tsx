import Link from 'next/link'
import { Wallet, Download, Clock, CheckCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { mockAgencySettlements } from '@/lib/mock/demo-agency-data'
import { formatKRW, formatDate } from '@/lib/utils/format'
import type { AgencySettlement, SettlementStatus } from '@/lib/agency/agency-types'

const STATUS_CONFIG: Record<SettlementStatus, { label: string; className: string }> = {
  draft: { label: '초안', className: 'bg-gray-100 text-gray-600' },
  pending_review: { label: '검토 대기', className: 'bg-yellow-100 text-yellow-700' },
  approved: { label: '승인', className: 'bg-blue-100 text-blue-700' },
  processing: { label: '처리중', className: 'bg-indigo-100 text-indigo-700' },
  paid: { label: '지급완료', className: 'bg-green-100 text-green-700' },
  rejected: { label: '반려', className: 'bg-red-100 text-red-700' },
}

async function getSettlements(): Promise<AgencySettlement[]> {
  if (DEMO_MODE) {
    return mockAgencySettlements
  }
  // TODO: Call agency-manage Edge Function with action: settlement.list
  return mockAgencySettlements
}

export default async function AgencySettlementsPage() {
  const settlements = await getSettlements()

  const totalPaid = settlements
    .filter(s => s.status === 'paid')
    .reduce((sum, s) => sum + s.agency_net_krw, 0)

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
          <h1 className="text-2xl font-bold text-gray-900">정산 관리</h1>
          <p className="text-gray-500 mt-1">
            총 {settlements.length}건 · 누적 지급 {formatKRW(totalPaid)}
          </p>
        </div>
        <Button variant="outline">
          <Download className="w-4 h-4 mr-2" />
          CSV 내보내기
        </Button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <CheckCircle className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">
                {settlements.filter(s => s.status === 'paid').length}건
              </div>
              <div className="text-sm text-gray-500">지급 완료</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-yellow-100 rounded-lg flex items-center justify-center">
              <Clock className="w-5 h-5 text-yellow-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">
                {settlements.filter(s => s.status === 'pending_review').length}건
              </div>
              <div className="text-sm text-gray-500">검토 대기</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
              <Wallet className="w-5 h-5 text-indigo-600" />
            </div>
            <div>
              <div className="text-lg font-bold text-gray-900">{formatKRW(totalPaid)}</div>
              <div className="text-sm text-gray-500">누적 지급액</div>
            </div>
          </div>
        </div>
      </div>

      {/* Settlement List */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">정산 내역</h2>
        </div>

        {settlements.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Wallet className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">정산 내역이 없습니다</h3>
            <p className="text-gray-500">활성 크리에이터가 있으면 자동으로 정산이 생성됩니다</p>
          </div>
        ) : (
          <>
            {/* Table Header */}
            <div className="hidden md:grid grid-cols-12 gap-4 p-4 border-b border-gray-100 bg-gray-50 text-sm font-medium text-gray-500">
              <div className="col-span-2">정산 기간</div>
              <div className="col-span-2">크리에이터</div>
              <div className="col-span-2 text-right">총 수익</div>
              <div className="col-span-2 text-right">소속사 수수료</div>
              <div className="col-span-2 text-right">정산 금액</div>
              <div className="col-span-2 text-center">상태</div>
            </div>

            <div className="divide-y divide-gray-100">
              {settlements.map((s) => {
                const statusConfig = STATUS_CONFIG[s.status]
                return (
                  <Link
                    key={s.id}
                    href={`/agency/settlements/${s.id}`}
                    className="grid grid-cols-1 md:grid-cols-12 gap-4 p-4 items-center hover:bg-gray-50 transition-colors"
                  >
                    <div className="col-span-2">
                      <div className="font-medium text-gray-900">
                        {s.period_start.slice(0, 7)}
                      </div>
                      <div className="text-xs text-gray-500">
                        {formatDate(s.period_start)} ~ {formatDate(s.period_end)}
                      </div>
                    </div>
                    <div className="col-span-2 text-sm text-gray-700">
                      {s.total_creators}명
                    </div>
                    <div className="col-span-2 text-right text-sm text-gray-700">
                      {formatKRW(s.total_gross_krw)}
                    </div>
                    <div className="col-span-2 text-right text-sm text-gray-700">
                      {formatKRW(s.agency_commission_krw)}
                    </div>
                    <div className="col-span-2 text-right font-medium text-gray-900">
                      {formatKRW(s.agency_net_krw)}
                    </div>
                    <div className="col-span-2 text-center">
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${statusConfig.className}`}>
                        {statusConfig.label}
                      </span>
                    </div>
                  </Link>
                )
              })}
            </div>
          </>
        )}
      </div>
    </div>
  )
}
