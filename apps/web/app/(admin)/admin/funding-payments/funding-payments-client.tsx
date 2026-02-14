'use client'

import { useState } from 'react'
import { CreditCard, CheckCircle, XCircle, RefreshCw, AlertTriangle, Eye, ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { formatKRW, formatDateTime } from '@/lib/utils/format'
import { useToast } from '@/components/ops/ops-toast'

// =====================================================
// Funding Payments Client Component
// - Filter buttons with state management
// - Refund functionality
// - Detail view modal
// - Stats calculation
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

interface FundingPaymentsClientProps {
  initialPayments: FundingPayment[]
  campaignStats: CampaignPaymentStats[]
  isDemoMode: boolean
}

type FilterStatus = 'all' | 'paid' | 'refunded' | 'failed'

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

export default function FundingPaymentsClient({
  initialPayments,
  campaignStats,
  isDemoMode,
}: FundingPaymentsClientProps) {
  const [payments, setPayments] = useState<FundingPayment[]>(initialPayments)
  const [filterStatus, setFilterStatus] = useState<FilterStatus>('all')
  const [selectedPayment, setSelectedPayment] = useState<FundingPayment | null>(null)
  const toast = useToast()

  // Filter payments based on selected status
  const filteredPayments = payments.filter(p => {
    if (filterStatus === 'all') return true
    if (filterStatus === 'refunded') return p.status === 'refunded' || p.status === 'partial_refunded'
    return p.status === filterStatus
  })

  // Calculate stats
  const totalPaid = payments.filter(p => p.status === 'paid').reduce((sum, p) => sum + p.amount_krw, 0)
  const totalRefunded = payments.filter(p => p.status === 'refunded' || p.status === 'partial_refunded')
    .reduce((sum, p) => sum + p.refunded_amount_krw, 0)
  const completedCount = payments.filter(p => p.status === 'paid').length
  const refundedCount = payments.filter(p => p.status === 'refunded' || p.status === 'partial_refunded').length
  const failedCount = payments.filter(p => p.status === 'failed').length

  // Handle refund
  const handleRefund = (payment: FundingPayment) => {
    const confirmed = window.confirm(
      `${payment.user_name}님의 ${formatKRW(payment.amount_krw)} 결제를 환불하시겠습니까?\n\n` +
      `캠페인: ${payment.campaign_title}\n` +
      `주문번호: ${payment.payment_order_id}\n\n` +
      `이 작업은 되돌릴 수 없습니다.`
    )

    if (!confirmed) return

    // Update payment status to refunded
    setPayments(prev => prev.map(p =>
      p.id === payment.id
        ? { ...p, status: 'refunded', refunded_amount_krw: p.amount_krw }
        : p
    ))

    toast.success('환불 처리 완료', `${payment.user_name}님에게 ${formatKRW(payment.amount_krw)} 환불되었습니다.`)
  }

  return (
    <div className="max-w-6xl mx-auto">
      {/* Demo Banner */}
      {isDemoMode && (
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
              <div className="text-2xl font-bold text-gray-900">{completedCount}</div>
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
            <button
              onClick={() => setFilterStatus('all')}
              className={`px-3 py-1 rounded-lg text-sm transition-colors ${
                filterStatus === 'all'
                  ? 'bg-gray-900 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              전체
            </button>
            <button
              onClick={() => setFilterStatus('paid')}
              className={`px-3 py-1 rounded-lg text-sm transition-colors ${
                filterStatus === 'paid'
                  ? 'bg-gray-900 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              결제완료
            </button>
            <button
              onClick={() => setFilterStatus('refunded')}
              className={`px-3 py-1 rounded-lg text-sm transition-colors ${
                filterStatus === 'refunded'
                  ? 'bg-gray-900 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              환불
            </button>
            <button
              onClick={() => setFilterStatus('failed')}
              className={`px-3 py-1 rounded-lg text-sm transition-colors ${
                filterStatus === 'failed'
                  ? 'bg-gray-900 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              실패
            </button>
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
              {filteredPayments.map((p) => (
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
                      <Button
                        size="sm"
                        variant="ghost"
                        className="h-8 w-8 p-0"
                        onClick={() => setSelectedPayment(p)}
                      >
                        <Eye className="w-4 h-4" />
                      </Button>
                      {p.status === 'paid' && (
                        <Button
                          size="sm"
                          variant="outline"
                          className="h-8 px-2 text-orange-600 border-orange-200 text-xs hover:bg-orange-50"
                          onClick={() => handleRefund(p)}
                        >
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

      {/* Detail Modal */}
      {selectedPayment && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          onClick={() => setSelectedPayment(null)}
        >
          <div
            className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
            onClick={e => e.stopPropagation()}
          >
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-bold text-gray-900">결제 상세 정보</h2>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => setSelectedPayment(null)}
                >
                  <XCircle className="w-5 h-5" />
                </Button>
              </div>
            </div>

            <div className="p-6 space-y-6">
              {/* Payment Info */}
              <div>
                <h3 className="font-semibold text-gray-900 mb-3">결제 정보</h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-500">주문번호</span>
                    <span className="font-mono text-gray-900">{selectedPayment.payment_order_id}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">캠페인</span>
                    <span className="font-medium text-gray-900">{selectedPayment.campaign_title}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">사용자</span>
                    <span className="text-gray-900">{selectedPayment.user_name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">결제 금액</span>
                    <span className="font-bold text-gray-900">{formatKRW(selectedPayment.amount_krw)}</span>
                  </div>
                  {selectedPayment.refunded_amount_krw > 0 && (
                    <div className="flex justify-between">
                      <span className="text-gray-500">환불 금액</span>
                      <span className="font-bold text-orange-600">{formatKRW(selectedPayment.refunded_amount_krw)}</span>
                    </div>
                  )}
                  <div className="flex justify-between">
                    <span className="text-gray-500">결제 수단</span>
                    <span className="text-gray-900">{getPaymentMethodLabel(selectedPayment.payment_method)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">결제 대행사</span>
                    <span className="text-gray-900">{selectedPayment.payment_provider}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">상태</span>
                    <span>{getStatusBadge(selectedPayment.status)}</span>
                  </div>
                </div>
              </div>

              {/* PG Transaction Info */}
              <div>
                <h3 className="font-semibold text-gray-900 mb-3">PG 트랜잭션 정보</h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-500">PG 트랜잭션 ID</span>
                    <span className="font-mono text-gray-900">{selectedPayment.pg_transaction_id || '-'}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">결제 일시</span>
                    <span className="text-gray-900">
                      {selectedPayment.paid_at ? formatDateTime(selectedPayment.paid_at) : '-'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-500">생성 일시</span>
                    <span className="text-gray-900">{formatDateTime(selectedPayment.created_at)}</span>
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-2 pt-4 border-t border-gray-200">
                {selectedPayment.status === 'paid' && (
                  <Button
                    variant="outline"
                    className="flex-1 text-orange-600 border-orange-200 hover:bg-orange-50"
                    onClick={() => {
                      handleRefund(selectedPayment)
                      setSelectedPayment(null)
                    }}
                  >
                    환불 처리
                  </Button>
                )}
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={() => setSelectedPayment(null)}
                >
                  닫기
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
