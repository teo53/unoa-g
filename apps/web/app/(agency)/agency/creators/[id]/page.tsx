import Link from 'next/link'
import { ArrowLeft, Users, Calendar, Percent, FileText, Download } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { getMockAgencyCreatorIds, mockAgencySettlements } from '@/lib/mock/demo-agency-data'
import { formatDate, formatKRW } from '@/lib/utils/format'
import type { AgencyCreator, ContractStatus } from '@/lib/agency/agency-types'
import { getAgencyCreator } from '@/lib/agency/agency-client'

const STATUS_CONFIG: Record<ContractStatus, { label: string; className: string }> = {
  active: { label: '활성', className: 'bg-green-100 text-green-700' },
  pending: { label: '승인 대기', className: 'bg-yellow-100 text-yellow-700' },
  paused: { label: '일시정지', className: 'bg-gray-100 text-gray-600' },
  terminated: { label: '해지', className: 'bg-red-100 text-red-700' },
}

export async function generateStaticParams() {
  return getMockAgencyCreatorIds().map(id => ({ id }))
}

async function getCreator(id: string): Promise<AgencyCreator | null> {
  return getAgencyCreator(id)
}

export default async function CreatorDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const creator = await getCreator(id)

  if (!creator) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="bg-white rounded-xl border border-gray-200 p-8 text-center">
          <h2 className="text-lg font-medium text-gray-900 mb-2">크리에이터를 찾을 수 없습니다</h2>
          <Link href="/agency/creators">
            <Button variant="secondary">목록으로 돌아가기</Button>
          </Link>
        </div>
      </div>
    )
  }

  const statusConfig = STATUS_CONFIG[creator.status]

  // Get settlements for this creator
  const creatorSettlements = mockAgencySettlements
    .map(s => {
      const breakdown = s.creator_breakdown.find(cb => cb.creator_id === creator.creator_profile_id)
      if (!breakdown) return null
      return { settlement: s, breakdown }
    })
    .filter(Boolean)

  return (
    <div className="max-w-4xl mx-auto">
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 샘플 데이터가 표시됩니다
        </div>
      )}

      {/* Back + Header */}
      <div className="mb-6">
        <Link href="/agency/creators" className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-900 mb-3">
          <ArrowLeft className="w-4 h-4" />
          소속 크리에이터
        </Link>

        <div className="flex items-center gap-4">
          <div className="w-16 h-16 bg-gray-100 rounded-full overflow-hidden flex-shrink-0">
            {creator.creator?.avatar_url ? (
              <img src={creator.creator.avatar_url} alt="" className="w-full h-full object-cover" />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-gray-400">
                <Users className="w-8 h-8" />
              </div>
            )}
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-bold text-gray-900">{creator.creator?.stage_name || '알 수 없음'}</h1>
              <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${statusConfig.className}`}>
                {statusConfig.label}
              </span>
            </div>
            <p className="text-gray-500 mt-1">
              구독자 {creator.creator?.subscriber_count?.toLocaleString() || 0}명
              {creator.creator?.categories?.length ? ` · ${creator.creator.categories.join(', ')}` : ''}
            </p>
          </div>
          {creator.status === 'active' && (
            <Button variant="outline" size="sm">계약 조건 변경</Button>
          )}
        </div>
      </div>

      {/* Contract Details */}
      <div className="bg-white rounded-xl border border-gray-200 p-6 mb-6">
        <h2 className="font-semibold text-gray-900 mb-4">계약 정보</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center">
              <Calendar className="w-5 h-5 text-indigo-600" />
            </div>
            <div>
              <div className="text-sm text-gray-500">계약 기간</div>
              <div className="font-medium text-gray-900">
                {creator.contract_start_date ? formatDate(creator.contract_start_date) : '-'}
                {creator.contract_end_date ? ` ~ ${formatDate(creator.contract_end_date)}` : creator.contract_start_date ? ' ~ 무기한' : ''}
              </div>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <Percent className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <div className="text-sm text-gray-500">수수료율 (소속사)</div>
              <div className="font-medium text-gray-900">{(creator.revenue_share_rate * 100).toFixed(0)}%</div>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <FileText className="w-5 h-5 text-purple-600" />
            </div>
            <div>
              <div className="text-sm text-gray-500">정산 방식</div>
              <div className="font-medium text-gray-900">
                {creator.power_of_attorney_url ? '통합 정산 (위임장 있음)' : '개별 정산'}
              </div>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-amber-100 rounded-lg flex items-center justify-center">
              <Calendar className="w-5 h-5 text-amber-600" />
            </div>
            <div>
              <div className="text-sm text-gray-500">정산 기준</div>
              <div className="font-medium text-gray-900">
                {creator.settlement_period === 'weekly' ? '주간' : creator.settlement_period === 'biweekly' ? '격주' : '월간'}
              </div>
            </div>
          </div>
        </div>

        {/* Documents */}
        {(creator.contract_document_url || creator.power_of_attorney_url) && (
          <div className="mt-6 pt-4 border-t border-gray-100">
            <h3 className="text-sm font-medium text-gray-700 mb-3">첨부 서류</h3>
            <div className="flex items-center gap-3">
              {creator.contract_document_url && (
                <button className="flex items-center gap-2 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm text-gray-700 hover:bg-gray-100">
                  <Download className="w-4 h-4" />
                  계약서 다운로드
                </button>
              )}
              {creator.power_of_attorney_url && (
                <button className="flex items-center gap-2 px-3 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm text-gray-700 hover:bg-gray-100">
                  <Download className="w-4 h-4" />
                  위임장 다운로드
                </button>
              )}
            </div>
          </div>
        )}

        {creator.notes && (
          <div className="mt-4 pt-4 border-t border-gray-100">
            <h3 className="text-sm font-medium text-gray-700 mb-1">메모</h3>
            <p className="text-sm text-gray-600">{creator.notes}</p>
          </div>
        )}
      </div>

      {/* Settlement History for this Creator */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">정산 이력</h2>
        </div>
        {creatorSettlements.length === 0 ? (
          <div className="p-8 text-center text-gray-500 text-sm">정산 내역이 없습니다</div>
        ) : (
          <>
            <div className="hidden md:grid grid-cols-12 gap-4 p-4 border-b border-gray-100 bg-gray-50 text-sm font-medium text-gray-500">
              <div className="col-span-3">정산 기간</div>
              <div className="col-span-2 text-right">총 매출</div>
              <div className="col-span-2 text-right">순수익</div>
              <div className="col-span-3 text-right">소속사 수수료</div>
              <div className="col-span-2 text-center">상태</div>
            </div>
            <div className="divide-y divide-gray-100">
              {creatorSettlements.map((item) => {
                if (!item) return null
                const { settlement, breakdown } = item
                return (
                  <div key={settlement.id} className="grid grid-cols-1 md:grid-cols-12 gap-4 p-4 items-center">
                    <div className="col-span-3 font-medium text-gray-900">
                      {settlement.period_start.slice(0, 7)}
                    </div>
                    <div className="col-span-2 text-right text-sm text-gray-700">
                      {formatKRW(breakdown.gross_krw)}
                    </div>
                    <div className="col-span-2 text-right text-sm text-gray-700">
                      {formatKRW(breakdown.net_krw)}
                    </div>
                    <div className="col-span-3 text-right text-sm font-medium text-indigo-600">
                      {formatKRW(breakdown.agency_commission_krw)}
                    </div>
                    <div className="col-span-2 text-center">
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                        settlement.status === 'paid' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
                      }`}>
                        {settlement.status === 'paid' ? '지급완료' : '대기'}
                      </span>
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
