'use client'

import { useCallback, useEffect, useMemo, useState } from 'react'
import { format } from 'date-fns'
import { ko } from 'date-fns/locale'
import { approveFanAd, listFanAds, rejectFanAd } from '@/lib/ops/ops-client'
import { PLACEMENT_LABELS } from '@/lib/ops/ops-types'
import type { BannerPlacement, FanAdListResult, FanAdStatus, OpsFanAd } from '@/lib/ops/ops-types'

const PAGE_SIZE = 50

const STATUS_TABS: { key: FanAdStatus | 'all'; label: string }[] = [
  { key: 'all', label: '전체' },
  { key: 'pending_review', label: '심사 대기' },
  { key: 'approved', label: '승인됨' },
  { key: 'active', label: '노출 중' },
  { key: 'rejected', label: '거절됨' },
]

const STATUS_LABELS: Record<FanAdStatus, string> = {
  pending_review: '심사 대기',
  approved: '승인됨',
  active: '노출 중',
  completed: '완료',
  rejected: '거절됨',
  cancelled: '취소됨',
}

const STATUS_COLORS: Record<FanAdStatus, string> = {
  pending_review: 'bg-yellow-100 text-yellow-800',
  approved: 'bg-blue-100 text-blue-800',
  active: 'bg-green-100 text-green-800',
  completed: 'bg-gray-100 text-gray-600',
  rejected: 'bg-red-100 text-red-800',
  cancelled: 'bg-gray-100 text-gray-500',
}

const PLACEMENTS = Object.entries(PLACEMENT_LABELS) as Array<[BannerPlacement, string]>

export default function FanAdsAdminPage() {
  const [result, setResult] = useState<FanAdListResult>({
    items: [],
    total: 0,
    limit: PAGE_SIZE,
    offset: 0,
  })
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<FanAdStatus | 'all'>('pending_review')
  const [page, setPage] = useState(0)
  const [selected, setSelected] = useState<OpsFanAd | null>(null)
  const [placement, setPlacement] = useState<BannerPlacement>('home_top')
  const [rejectReason, setRejectReason] = useState('')
  const [actionLoading, setActionLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadAds = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await listFanAds({
        status: activeTab === 'all' ? undefined : activeTab,
        limit: PAGE_SIZE,
        offset: page * PAGE_SIZE,
      })
      setResult(data)
    } catch (e) {
      setError(e instanceof Error ? e.message : '로드 실패')
    } finally {
      setLoading(false)
    }
  }, [activeTab, page])

  useEffect(() => {
    void loadAds()
  }, [loadAds])

  const ads = result.items
  const totalPages = useMemo(() => Math.max(1, Math.ceil(result.total / PAGE_SIZE)), [result.total])
  const pageStart = result.total === 0 ? 0 : result.offset + 1
  const pageEnd = Math.min(result.offset + ads.length, result.total)
  const canPrev = page > 0
  const canNext = (page + 1) * PAGE_SIZE < result.total

  const openReview = (ad: OpsFanAd) => {
    setSelected(ad)
    setPlacement('home_top')
    setRejectReason('')
  }

  const handleApprove = async (ad: OpsFanAd) => {
    if (ad.payment_status !== 'paid') {
      setError('결제 완료된 광고만 승인할 수 있습니다.')
      return
    }
    setActionLoading(true)
    setError(null)
    try {
      await approveFanAd(ad.id, placement)
      setSelected(null)
      await loadAds()
    } catch (e) {
      setError(e instanceof Error ? e.message : '승인 실패')
    } finally {
      setActionLoading(false)
    }
  }

  const handleReject = async (ad: OpsFanAd) => {
    const reason = rejectReason.trim()
    if (!reason) {
      setError('거절 사유를 입력해주세요')
      return
    }

    setActionLoading(true)
    setError(null)
    try {
      await rejectFanAd(ad.id, reason)
      setSelected(null)
      setRejectReason('')
      await loadAds()
    } catch (e) {
      setError(e instanceof Error ? e.message : '거절 처리 실패')
    } finally {
      setActionLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">팬 광고 심사</h1>
          <p className="mt-1 text-sm text-gray-500">팬이 구매한 광고를 심사하고 승인/거절 처리합니다</p>
          <p className="mt-1 text-xs text-gray-400">
            총 {result.total.toLocaleString()}건 · {pageStart.toLocaleString()}-{pageEnd.toLocaleString()} 표시
          </p>
        </div>
        <button
          onClick={() => void loadAds()}
          className="rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm transition-colors hover:bg-gray-50"
        >
          새로 고침
        </button>
      </div>

      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
          <button onClick={() => setError(null)} className="ml-2 font-medium underline">
            닫기
          </button>
        </div>
      )}

      <div className="flex w-fit gap-1 rounded-lg bg-gray-100 p-1">
        {STATUS_TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => {
              setActiveTab(tab.key)
              setPage(0)
              setSelected(null)
            }}
            className={`rounded-md px-4 py-2 text-sm font-medium transition-colors ${
              activeTab === tab.key ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="py-12 text-center text-gray-500">로딩 중...</div>
      ) : ads.length === 0 ? (
        <div className="py-12 text-center text-gray-400">해당 상태의 광고가 없습니다</div>
      ) : (
        <div className="overflow-hidden rounded-xl border border-gray-200 bg-white">
          <table className="w-full text-sm">
            <thead className="border-b border-gray-200 bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left font-medium text-gray-500">광고 제목</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">상태</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">결제</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">금액</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">노출 기간</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">등록일</th>
                <th className="px-4 py-3 text-left font-medium text-gray-500">액션</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {ads.map((ad) => (
                <tr key={ad.id} className="transition-colors hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <div className="font-medium text-gray-900">{ad.title}</div>
                    {ad.body && <div className="mt-0.5 max-w-xs truncate text-xs text-gray-500">{ad.body}</div>}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${STATUS_COLORS[ad.status]}`}>
                      {STATUS_LABELS[ad.status]}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                        ad.payment_status === 'paid' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                      }`}
                    >
                      {ad.payment_status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-700">{ad.payment_amount_krw.toLocaleString()}원</td>
                  <td className="px-4 py-3 text-xs text-gray-500">
                    {format(new Date(ad.start_at), 'MM.dd', { locale: ko })} ~{' '}
                    {format(new Date(ad.end_at), 'MM.dd', { locale: ko })}
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500">
                    {format(new Date(ad.created_at), 'MM.dd HH:mm', { locale: ko })}
                  </td>
                  <td className="px-4 py-3">
                    {ad.status === 'pending_review' && (
                      <button
                        onClick={() => openReview(ad)}
                        className="rounded-lg bg-gray-900 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-gray-700"
                      >
                        심사하기
                      </button>
                    )}
                    {ad.rejection_reason && <span className="text-xs text-red-500">{ad.rejection_reason}</span>}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="flex items-center justify-between">
        <div className="text-xs text-gray-500">
          페이지 {page + 1} / {totalPages}
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setPage((prev) => Math.max(prev - 1, 0))}
            disabled={!canPrev || loading}
            className="rounded-lg border border-gray-200 px-3 py-1.5 text-xs disabled:cursor-not-allowed disabled:opacity-40"
          >
            이전
          </button>
          <button
            onClick={() => setPage((prev) => prev + 1)}
            disabled={!canNext || loading}
            className="rounded-lg border border-gray-200 px-3 py-1.5 text-xs disabled:cursor-not-allowed disabled:opacity-40"
          >
            다음
          </button>
        </div>
      </div>

      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="mx-4 w-full max-w-lg space-y-4 rounded-2xl bg-white p-6 shadow-xl">
            <h2 className="text-lg font-bold text-gray-900">광고 심사</h2>

            <div className="space-y-2 rounded-xl bg-gray-50 p-4 text-sm">
              <div className="font-semibold text-gray-900">{selected.title}</div>
              {selected.body && <div className="text-gray-500">{selected.body}</div>}
              <div className="flex gap-4 text-xs text-gray-400">
                <span>금액: {selected.payment_amount_krw.toLocaleString()}원</span>
                <span>
                  {format(new Date(selected.start_at), 'MM.dd')} ~ {format(new Date(selected.end_at), 'MM.dd')}
                </span>
              </div>
              {selected.link_url && <div className="truncate text-xs text-blue-600">{selected.link_url}</div>}
            </div>

            {selected.payment_status !== 'paid' && (
              <div className="rounded-lg border border-yellow-200 bg-yellow-50 px-3 py-2 text-xs text-yellow-800">
                결제 상태가 `paid`가 아니므로 승인을 진행할 수 없습니다.
              </div>
            )}

            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">노출 위치</label>
              <select
                value={placement}
                onChange={(e) => setPlacement(e.target.value as BannerPlacement)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900"
              >
                {PLACEMENTS.map(([key, label]) => (
                  <option key={key} value={key}>
                    {label} ({key})
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                거절 사유 <span className="text-gray-400">(거절 시 필수)</span>
              </label>
              <textarea
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                rows={3}
                placeholder="예: 부적절한 콘텐츠, 규정 위반 등"
                className="w-full resize-none rounded-lg border border-gray-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-gray-900"
              />
            </div>

            <div className="flex gap-3 pt-2">
              <button
                onClick={() => setSelected(null)}
                className="flex-1 rounded-xl border border-gray-200 px-4 py-2.5 text-sm font-medium transition-colors hover:bg-gray-50"
                disabled={actionLoading}
              >
                취소
              </button>
              <button
                onClick={() => void handleReject(selected)}
                className="flex-1 rounded-xl border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-medium text-red-700 transition-colors hover:bg-red-100"
                disabled={actionLoading}
              >
                {actionLoading ? '처리 중...' : '거절'}
              </button>
              <button
                onClick={() => void handleApprove(selected)}
                className={`flex-1 rounded-xl px-4 py-2.5 text-sm font-medium text-white transition-colors ${
                  selected.payment_status === 'paid'
                    ? 'bg-gray-900 hover:bg-gray-700'
                    : 'bg-gray-300 cursor-not-allowed'
                }`}
                disabled={actionLoading || selected.payment_status !== 'paid'}
              >
                {actionLoading ? '처리 중...' : '승인'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
