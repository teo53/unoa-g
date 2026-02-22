import Link from 'next/link'
import { ArrowLeft, Download, Users, FileText } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import { getMockAgencySettlementIds } from '@/lib/mock/demo-agency-data'
import { formatKRW, formatDate } from '@/lib/utils/format'
import type { AgencySettlement, SettlementStatus } from '@/lib/agency/agency-types'
import { getAgencySettlement } from '@/lib/agency/agency-client'

const STATUS_CONFIG: Record<SettlementStatus, { label: string; className: string }> = {
  draft: { label: '초안', className: 'bg-gray-100 text-gray-600' },
  pending_review: { label: '검토 대기', className: 'bg-yellow-100 text-yellow-700' },
  approved: { label: '승인', className: 'bg-blue-100 text-blue-700' },
  processing: { label: '처리중', className: 'bg-indigo-100 text-indigo-700' },
  paid: { label: '지급완료', className: 'bg-green-100 text-green-700' },
  rejected: { label: '반려', className: 'bg-red-100 text-red-700' },
}

// Required for `output: 'export'` — only pre-generated paths are valid.
export const dynamicParams = false

export async function generateStaticParams() {
  if (DEMO_MODE) return getMockAgencySettlementIds().map(id => ({ id }))
  return [{ id: '_' }]
}

async function getSettlement(id: string): Promise<AgencySettlement | null> {
  // Static export without Supabase credentials — skip API call
  if (!DEMO_MODE && !process.env.NEXT_PUBLIC_SUPABASE_URL) return null
  return getAgencySettlement(id)
}

export default async function SettlementDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const settlement = await getSettlement(id)

  if (!settlement) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="bg-white rounded-xl border border-gray-200 p-8 text-center">
          <h2 className="text-lg font-medium text-gray-900 mb-2">정산 내역을 찾을 수 없습니다</h2>
          <Link href="/agency/settlements">
            <Button variant="secondary">목록으로 돌아가기</Button>
          </Link>
        </div>
      </div>
    )
  }

  const statusConfig = STATUS_CONFIG[settlement.status]

  return (
    <div className="max-w-4xl mx-auto">
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          데모 모드 — 샘플 데이터가 표시됩니다
        </div>
      )}

      {/* Back + Header */}
      <div className="mb-6">
        <Link href="/agency/settlements" className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-900 mb-3">
          <ArrowLeft className="w-4 h-4" />
          정산 관리
        </Link>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              {settlement.period_start.slice(0, 7)} 정산
            </h1>
            <p className="text-gray-500 mt-1">
              {formatDate(settlement.period_start)} ~ {formatDate(settlement.period_end)}
            </p>
          </div>
          <div className="flex items-center gap-3">
            <span className={`text-sm font-medium px-3 py-1 rounded-full ${statusConfig.className}`}>
              {statusConfig.label}
            </span>
            <Button variant="outline" size="sm">
              <Download className="w-4 h-4 mr-1" />
              PDF
            </Button>
          </div>
        </div>
      </div>

      {/* Summary */}
      <div className="bg-white rounded-xl border border-gray-200 p-6 mb-6">
        <h2 className="font-semibold text-gray-900 mb-4">정산 요약</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div>
            <div className="text-sm text-gray-500">총 매출</div>
            <div className="text-lg font-bold text-gray-900">{formatKRW(settlement.total_gross_krw)}</div>
          </div>
          <div>
            <div className="text-sm text-gray-500">플랫폼 수수료</div>
            <div className="text-lg font-bold text-red-600">-{formatKRW(settlement.total_platform_fee_krw)}</div>
          </div>
          <div>
            <div className="text-sm text-gray-500">소속사 수수료</div>
            <div className="text-lg font-bold text-indigo-600">{formatKRW(settlement.agency_commission_krw)}</div>
          </div>
          <div>
            <div className="text-sm text-gray-500">소속사 실수령</div>
            <div className="text-lg font-bold text-green-600">{formatKRW(settlement.agency_net_krw)}</div>
          </div>
        </div>

        {settlement.agency_tax_krw > 0 && (
          <div className="mt-4 pt-4 border-t border-gray-100">
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-500">
                세금 ({settlement.agency_tax_type === 'invoice' ? '세금계산서' : '사업소득세'} {(settlement.agency_tax_rate * 100).toFixed(1)}%)
              </span>
              <span className="text-red-600">-{formatKRW(settlement.agency_tax_krw)}</span>
            </div>
          </div>
        )}
      </div>

      {/* Creator Breakdown */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-4 border-b border-gray-200 flex items-center gap-2">
          <Users className="w-5 h-5 text-gray-400" />
          <h2 className="font-semibold text-gray-900">크리에이터별 내역</h2>
          <span className="text-sm text-gray-500">({settlement.total_creators}명)</span>
        </div>

        {/* Table Header */}
        <div className="hidden md:grid grid-cols-12 gap-4 p-4 border-b border-gray-100 bg-gray-50 text-sm font-medium text-gray-500">
          <div className="col-span-3">크리에이터</div>
          <div className="col-span-2 text-right">총 매출</div>
          <div className="col-span-2 text-right">플랫폼 수수료</div>
          <div className="col-span-2 text-right">순수익</div>
          <div className="col-span-2 text-right">소속사 수수료</div>
          <div className="col-span-1 text-center">정산방식</div>
        </div>

        <div className="divide-y divide-gray-100">
          {settlement.creator_breakdown.map((cb) => (
            <div key={cb.creator_id} className="grid grid-cols-1 md:grid-cols-12 gap-4 p-4 items-center">
              <div className="col-span-3 font-medium text-gray-900">
                {cb.creator_name || cb.creator_id}
              </div>
              <div className="col-span-2 text-right text-sm text-gray-700">
                {formatKRW(cb.gross_krw)}
              </div>
              <div className="col-span-2 text-right text-sm text-gray-500">
                -{formatKRW(cb.platform_fee_krw)}
              </div>
              <div className="col-span-2 text-right text-sm text-gray-700">
                {formatKRW(cb.net_krw)}
              </div>
              <div className="col-span-2 text-right text-sm font-medium text-indigo-600">
                {formatKRW(cb.agency_commission_krw)}
              </div>
              <div className="col-span-1 text-center">
                {cb.has_power_of_attorney ? (
                  <span className="text-xs bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded-full" title="위임장 있음 — 소속사 일괄 수령">
                    통합
                  </span>
                ) : (
                  <span className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full" title="크리에이터 개별 수령">
                    개별
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Footer totals */}
        <div className="grid grid-cols-1 md:grid-cols-12 gap-4 p-4 bg-gray-50 border-t border-gray-200 rounded-b-xl">
          <div className="col-span-3 font-semibold text-gray-900">합계</div>
          <div className="col-span-2 text-right font-semibold text-gray-900">
            {formatKRW(settlement.total_gross_krw)}
          </div>
          <div className="col-span-2 text-right font-semibold text-gray-500">
            -{formatKRW(settlement.total_platform_fee_krw)}
          </div>
          <div className="col-span-2 text-right font-semibold text-gray-900">
            {formatKRW(settlement.total_creator_net_krw)}
          </div>
          <div className="col-span-2 text-right font-semibold text-indigo-600">
            {formatKRW(settlement.agency_commission_krw)}
          </div>
          <div className="col-span-1" />
        </div>
      </div>

      {/* Timeline */}
      {(settlement.reviewed_at || settlement.paid_at) && (
        <div className="bg-white rounded-xl border border-gray-200 p-6 mt-6">
          <h2 className="font-semibold text-gray-900 mb-4">처리 이력</h2>
          <div className="space-y-3">
            <div className="flex items-center gap-3 text-sm">
              <div className="w-2 h-2 bg-gray-400 rounded-full" />
              <span className="text-gray-500">생성: {formatDate(settlement.created_at)}</span>
            </div>
            {settlement.reviewed_at && (
              <div className="flex items-center gap-3 text-sm">
                <div className="w-2 h-2 bg-blue-500 rounded-full" />
                <span className="text-gray-500">검토 완료: {formatDate(settlement.reviewed_at)}</span>
              </div>
            )}
            {settlement.paid_at && (
              <div className="flex items-center gap-3 text-sm">
                <div className="w-2 h-2 bg-green-500 rounded-full" />
                <span className="text-gray-500">지급 완료: {formatDate(settlement.paid_at)}</span>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
