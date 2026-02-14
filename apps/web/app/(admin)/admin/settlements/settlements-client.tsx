'use client'

import { useState, useCallback } from 'react'
import { Clock, CheckCircle, FileText, Download, Eye, X, ChevronDown, Calendar, Info } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { formatKRW, formatDate } from '@/lib/utils/format'

// =====================================================
// Settlement Client Component
// - 필터 기능 (전체/심사대기/승인/지급완료)
// - 승인/반려 액션 (상태 변경 + toast)
// - CSV 내보내기
// - 상세 보기 모달 (수수료/세금 계산식)
// - 구독 수익 컬럼 + 팝오버 (BASIC/STANDARD/VIP)
// =====================================================

export interface Settlement {
  id: string
  creator_id: string
  creator_name: string
  period_start: string
  period_end: string
  // Subscription revenue (new)
  subscription_basic_count: number
  subscription_basic_krw: number
  subscription_standard_count: number
  subscription_standard_krw: number
  subscription_vip_count: number
  subscription_vip_krw: number
  subscription_total_krw: number
  // Existing fields
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

interface Stats {
  pendingReview: number
  approved: number
  paid: number
  totalPayoutKrw: number
}

interface SettlementsClientProps {
  initialSettlements: Settlement[]
  initialStats: Stats
  isDemoMode: boolean
}

type FilterType = 'all' | 'pending_review' | 'approved' | 'paid'

export default function SettlementsClient({
  initialSettlements,
  initialStats,
  isDemoMode,
}: SettlementsClientProps) {
  const [settlements, setSettlements] = useState(initialSettlements)
  const [activeFilter, setActiveFilter] = useState<FilterType>('all')
  const [toast, setToast] = useState<string | null>(null)
  const [detailModal, setDetailModal] = useState<Settlement | null>(null)
  const [subscriptionPopover, setSubscriptionPopover] = useState<string | null>(null)

  // Compute live stats from current state
  const stats: Stats = {
    pendingReview: settlements.filter(s => s.status === 'pending_review').length,
    approved: settlements.filter(s => s.status === 'approved').length,
    paid: settlements.filter(s => s.status === 'paid').length,
    totalPayoutKrw: settlements.reduce((sum, s) => sum + s.net_payout_krw, 0),
  }

  const filtered = activeFilter === 'all'
    ? settlements
    : settlements.filter(s => s.status === activeFilter)

  const showToast = useCallback((message: string) => {
    setToast(message)
    setTimeout(() => setToast(null), 3000)
  }, [])

  const handleApprove = useCallback((id: string) => {
    setSettlements(prev =>
      prev.map(s => s.id === id ? { ...s, status: 'approved' } : s)
    )
    showToast('정산이 승인되었습니다')
  }, [showToast])

  const handleReject = useCallback((id: string) => {
    setSettlements(prev =>
      prev.map(s => s.id === id ? { ...s, status: 'rejected' } : s)
    )
    showToast('정산이 반려되었습니다')
  }, [showToast])

  const handleCsvExport = useCallback(() => {
    const headers = [
      '크리에이터', '정산기간', '구독수익', 'DT수익', '펀딩수익',
      '총수익', '수수료', '세율', '원천징수', '순지급액', '상태'
    ].join(',')

    const rows = filtered.map(s => [
      s.creator_name,
      `${s.period_start}~${s.period_end}`,
      s.subscription_total_krw,
      s.dt_revenue_krw,
      s.funding_revenue_krw,
      s.total_revenue_krw,
      s.platform_fee_krw,
      `${s.tax_rate}%`,
      s.withholding_tax_krw,
      s.net_payout_krw,
      s.status,
    ].join(','))

    const csvContent = '\uFEFF' + [headers, ...rows].join('\n')
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `settlements_${new Date().toISOString().slice(0, 10)}.csv`
    a.click()
    URL.revokeObjectURL(url)
    showToast('CSV 파일이 다운로드되었습니다')
  }, [filtered, showToast])

  const filterButtons: { label: string; value: FilterType }[] = [
    { label: '전체', value: 'all' },
    { label: '심사 대기', value: 'pending_review' },
    { label: '승인', value: 'approved' },
    { label: '지급', value: 'paid' },
  ]

  return (
    <div className="max-w-6xl mx-auto">
      {/* Toast */}
      {toast && (
        <div className="fixed top-4 right-4 z-50 bg-gray-900 text-white px-4 py-2 rounded-lg shadow-lg text-sm animate-in slide-in-from-top-2">
          {toast}
        </div>
      )}

      {/* Demo Banner */}
      {isDemoMode && (
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
        <Button variant="outline" size="sm" onClick={handleCsvExport}>
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

      {/* Settlement Policy & Schedule Info */}
      <div className="mb-8 grid grid-cols-2 gap-4">
        <div className="bg-white rounded-xl p-5 border border-gray-200">
          <div className="flex items-center gap-2 mb-3">
            <Calendar className="w-4 h-4 text-blue-500" />
            <h3 className="font-semibold text-gray-900 text-sm">정산 일정</h3>
          </div>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-500">정산 기준</span>
              <span className="text-gray-900">매월 1일 ~ 말일</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">정산서 공개</span>
              <span className="text-gray-900">익월 말일</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">지급 예정</span>
              <span className="text-gray-900">공개 후 15영업일</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">최소 지급액</span>
              <span className="text-gray-900">₩10,000 미만 이월</span>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-5 border border-gray-200">
          <div className="flex items-center gap-2 mb-3">
            <Info className="w-4 h-4 text-blue-500" />
            <h3 className="font-semibold text-gray-900 text-sm">수수료 체계</h3>
          </div>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-500">플랫폼 수수료</span>
              <span className="text-gray-900">총매출의 20%</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">PG 수수료</span>
              <span className="text-gray-900">결제금액의 3.3% (카드)</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">사업소득 원천징수</span>
              <span className="text-gray-900">3.3%</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">기타소득 원천징수</span>
              <span className="text-gray-900">8.8%</span>
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
            {filterButtons.map(btn => (
              <button
                key={btn.value}
                onClick={() => setActiveFilter(btn.value)}
                className={`px-3 py-1 rounded-lg text-sm transition-colors ${
                  activeFilter === btn.value
                    ? 'bg-gray-900 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {btn.label}
              </button>
            ))}
          </div>
        </div>

        {filtered.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <CheckCircle className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">정산 내역 없음</h3>
            <p className="text-gray-500">해당 상태의 정산이 없습니다</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-gray-500 text-left">
                <tr>
                  <th className="px-4 py-3 font-medium">크리에이터</th>
                  <th className="px-4 py-3 font-medium">정산 기간</th>
                  <th className="px-4 py-3 font-medium text-right">구독 수익</th>
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
                {filtered.map((s) => (
                  <tr key={s.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="font-medium text-gray-900">{s.creator_name}</div>
                      <div className="text-xs text-gray-400">{s.creator_id.slice(0, 12)}...</div>
                    </td>
                    <td className="px-4 py-3 text-gray-600">
                      {formatDate(s.period_start)} ~ {formatDate(s.period_end)}
                    </td>
                    {/* Subscription Revenue with popover */}
                    <td className="px-4 py-3 text-right relative">
                      <button
                        className="text-emerald-600 font-medium hover:underline cursor-pointer flex items-center justify-end gap-1"
                        onClick={() => setSubscriptionPopover(
                          subscriptionPopover === s.id ? null : s.id
                        )}
                      >
                        {formatKRW(s.subscription_total_krw)}
                        <ChevronDown className="w-3 h-3" />
                      </button>
                      {/* Subscription breakdown popover */}
                      {subscriptionPopover === s.id && (
                        <div className="absolute right-0 top-full mt-1 z-20 bg-white border border-gray-200 rounded-lg shadow-lg p-3 w-64">
                          <div className="text-xs font-medium text-gray-500 mb-2">구독 수익 내역</div>
                          <table className="w-full text-xs">
                            <thead>
                              <tr className="text-gray-400">
                                <th className="text-left pb-1">티어</th>
                                <th className="text-right pb-1">건수</th>
                                <th className="text-right pb-1">금액</th>
                              </tr>
                            </thead>
                            <tbody className="text-gray-700">
                              <tr>
                                <td className="py-0.5">BASIC (₩4,900)</td>
                                <td className="text-right">{s.subscription_basic_count}건</td>
                                <td className="text-right">{formatKRW(s.subscription_basic_krw)}</td>
                              </tr>
                              <tr>
                                <td className="py-0.5">STANDARD (₩9,900)</td>
                                <td className="text-right">{s.subscription_standard_count}건</td>
                                <td className="text-right">{formatKRW(s.subscription_standard_krw)}</td>
                              </tr>
                              <tr>
                                <td className="py-0.5">VIP (₩19,900)</td>
                                <td className="text-right">{s.subscription_vip_count}건</td>
                                <td className="text-right">{formatKRW(s.subscription_vip_krw)}</td>
                              </tr>
                              <tr className="border-t border-gray-100 font-medium">
                                <td className="pt-1">합계</td>
                                <td className="text-right pt-1">
                                  {s.subscription_basic_count + s.subscription_standard_count + s.subscription_vip_count}건
                                </td>
                                <td className="text-right pt-1">{formatKRW(s.subscription_total_krw)}</td>
                              </tr>
                            </tbody>
                          </table>
                        </div>
                      )}
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
                        <Button
                          size="sm"
                          variant="ghost"
                          className="h-8 w-8 p-0"
                          onClick={() => setDetailModal(s)}
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                        {s.status === 'pending_review' && (
                          <>
                            <Button
                              size="sm"
                              className="h-8 px-2 bg-green-600 hover:bg-green-700 text-white text-xs"
                              onClick={() => handleApprove(s.id)}
                            >
                              승인
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              className="h-8 px-2 text-red-600 border-red-200 text-xs"
                              onClick={() => handleReject(s.id)}
                            >
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

      {/* Detail Modal */}
      {detailModal && (
        <div
          className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
          onClick={() => setDetailModal(null)}
        >
          <div
            className="bg-white rounded-2xl max-w-lg w-full max-h-[80vh] overflow-y-auto"
            onClick={e => e.stopPropagation()}
          >
            <div className="p-6 border-b border-gray-200 flex items-center justify-between">
              <div>
                <h3 className="text-lg font-bold text-gray-900">
                  {detailModal.creator_name} 정산 상세
                </h3>
                <p className="text-sm text-gray-500 mt-1">
                  {formatDate(detailModal.period_start)} ~ {formatDate(detailModal.period_end)}
                </p>
              </div>
              <button
                onClick={() => setDetailModal(null)}
                className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center hover:bg-gray-200"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              {/* Revenue breakdown */}
              <div>
                <h4 className="text-sm font-semibold text-gray-500 mb-3">수익 내역</h4>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">구독 수익</span>
                    <span className="font-medium">{formatKRW(detailModal.subscription_total_krw)}</span>
                  </div>
                  <div className="ml-4 space-y-1 text-xs text-gray-500">
                    <div className="flex justify-between">
                      <span>BASIC ({detailModal.subscription_basic_count}건 x ₩4,900)</span>
                      <span>{formatKRW(detailModal.subscription_basic_krw)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>STANDARD ({detailModal.subscription_standard_count}건 x ₩9,900)</span>
                      <span>{formatKRW(detailModal.subscription_standard_krw)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>VIP ({detailModal.subscription_vip_count}건 x ₩19,900)</span>
                      <span>{formatKRW(detailModal.subscription_vip_krw)}</span>
                    </div>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">DT 수익</span>
                    <span className="font-medium">{formatKRW(detailModal.dt_revenue_krw)}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-600">펀딩 수익</span>
                    <span className="font-medium">{formatKRW(detailModal.funding_revenue_krw)}</span>
                  </div>
                  <div className="border-t pt-2 flex justify-between text-sm font-bold">
                    <span>총 매출</span>
                    <span>{formatKRW(detailModal.total_revenue_krw)}</span>
                  </div>
                </div>
              </div>

              {/* Fee calculation */}
              <div>
                <h4 className="text-sm font-semibold text-gray-500 mb-3">수수료/세금 계산</h4>
                <div className="bg-gray-50 rounded-lg p-4 space-y-2 text-sm font-mono">
                  <div className="flex justify-between">
                    <span className="text-gray-600">총매출</span>
                    <span>{formatKRW(detailModal.total_revenue_krw)}</span>
                  </div>
                  <div className="flex justify-between text-red-500">
                    <span>플랫폼 수수료 (20%)</span>
                    <span>-{formatKRW(detailModal.platform_fee_krw)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">과세소득</span>
                    <span>{formatKRW(detailModal.total_revenue_krw - detailModal.platform_fee_krw)}</span>
                  </div>
                  <div className="flex justify-between text-red-500">
                    <span>원천징수 ({detailModal.tax_rate}%)</span>
                    <span>-{formatKRW(detailModal.withholding_tax_krw)}</span>
                  </div>
                  <div className="border-t border-gray-200 pt-2 flex justify-between font-bold text-gray-900">
                    <span>순 지급액</span>
                    <span>{formatKRW(detailModal.net_payout_krw)}</span>
                  </div>
                </div>
              </div>

              {/* Settlement schedule */}
              <div>
                <h4 className="text-sm font-semibold text-gray-500 mb-3">정산 일정</h4>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600">정산 기준</span>
                    <span>{formatDate(detailModal.period_start)} ~ {formatDate(detailModal.period_end)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">정산서 공개일</span>
                    <span>익월 말일</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">확정/지급 예정</span>
                    <span>공개 후 15영업일</span>
                  </div>
                </div>
              </div>

              {/* Status */}
              <div className="flex items-center justify-between pt-2 border-t">
                <span className="text-sm text-gray-500">현재 상태</span>
                {getStatusBadge(detailModal.status)}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
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
