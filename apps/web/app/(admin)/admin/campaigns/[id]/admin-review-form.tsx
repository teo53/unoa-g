'use client'

import { useState, useEffect, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { ArrowLeft, CheckCircle, XCircle, ExternalLink } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { formatDT, formatDate } from '@/lib/utils/format'
import { DEMO_MODE, getCampaignById, getTiersByCampaignId } from '@/lib/mock/demo-data'
import type { CampaignWithTiers } from '@/lib/types/database'

interface AdminReviewFormProps {
  id: string
}

export default function AdminReviewForm({ id }: AdminReviewFormProps) {
  const router = useRouter()

  const [campaign, setCampaign] = useState<CampaignWithTiers | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [rejectReason, setRejectReason] = useState('')
  const [showRejectForm, setShowRejectForm] = useState(false)

  // Create supabase client only in non-demo mode
  const supabase = useMemo(() => {
    if (DEMO_MODE) return null
    const { createClient } = require('@/lib/supabase/client')
    return createClient()
  }, [])

  useEffect(() => {
    async function loadCampaign() {
      if (DEMO_MODE) {
        // Use mock data in demo mode
        const mockCampaign = getCampaignById(id)
        if (mockCampaign) {
          const tiers = getTiersByCampaignId(id)
          setCampaign({
            ...mockCampaign,
            funding_reward_tiers: tiers,
          } as CampaignWithTiers)
        } else {
          setError('캠페인을 찾을 수 없습니다')
        }
        setIsLoading(false)
        return
      }

      if (!supabase) return

      const { data, error } = await supabase
        .from('funding_campaigns')
        .select(`
          *,
          funding_reward_tiers (*)
        `)
        .eq('id', id)
        .single()

      if (error || !data) {
        setError('캠페인을 찾을 수 없습니다')
      } else {
        setCampaign(data as CampaignWithTiers)
      }
      setIsLoading(false)
    }

    loadCampaign()
  }, [id, supabase])

  const handleApprove = async () => {
    if (DEMO_MODE || !supabase) {
      alert('데모 모드에서는 승인 기능을 사용할 수 없습니다')
      return
    }

    setIsSubmitting(true)
    setError(null)

    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) throw new Error('로그인이 필요합니다')

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/funding-admin-review`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            campaignId: id,
            action: 'approve',
          }),
        }
      )

      const result = await response.json()

      if (!result.success) {
        throw new Error(result.error || '승인에 실패했습니다')
      }

      router.push('/admin')
    } catch (err) {
      setError(err instanceof Error ? err.message : '승인에 실패했습니다')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleReject = async () => {
    if (!rejectReason.trim()) {
      setError('반려 사유를 입력해주세요')
      return
    }

    if (DEMO_MODE || !supabase) {
      alert('데모 모드에서는 반려 기능을 사용할 수 없습니다')
      return
    }

    setIsSubmitting(true)
    setError(null)

    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) throw new Error('로그인이 필요합니다')

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/funding-admin-review`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            campaignId: id,
            action: 'reject',
            reason: rejectReason,
          }),
        }
      )

      const result = await response.json()

      if (!result.success) {
        throw new Error(result.error || '반려에 실패했습니다')
      }

      router.push('/admin')
    } catch (err) {
      setError(err instanceof Error ? err.message : '반려에 실패했습니다')
    } finally {
      setIsSubmitting(false)
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-primary-500 border-t-transparent" />
      </div>
    )
  }

  if (!campaign) {
    return (
      <div className="max-w-2xl mx-auto text-center py-12">
        <p className="text-red-500 mb-4">{error || '캠페인을 찾을 수 없습니다'}</p>
        <Link href="/admin">
          <Button variant="outline">대시보드로 돌아가기</Button>
        </Link>
      </div>
    )
  }

  const tiers = (campaign.funding_reward_tiers || []).sort((a, b) => a.display_order - b.display_order)

  return (
    <div className="max-w-4xl mx-auto">
      {/* Demo Mode Banner */}
      {DEMO_MODE && (
        <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-xl text-yellow-800 text-sm">
          🎭 데모 모드: 실제 승인/반려 기능은 비활성화되어 있습니다
        </div>
      )}

      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        <Link href="/admin" className="text-gray-500 hover:text-gray-700">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-gray-900">캠페인 심사</h1>
          <p className="text-gray-500 mt-1">캠페인 내용을 검토하고 승인 또는 반려해주세요</p>
        </div>
        <Link
          href={`/p/${campaign.slug}`}
          target="_blank"
          className="text-primary-500 hover:text-primary-600 flex items-center gap-1"
        >
          <span>미리보기</span>
          <ExternalLink className="w-4 h-4" />
        </Link>
      </div>

      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-xl text-red-600">
          {error}
        </div>
      )}

      <div className="grid lg:grid-cols-3 gap-6">
        {/* Campaign Info */}
        <div className="lg:col-span-2 space-y-6">
          {/* Cover */}
          <div className="aspect-[16/9] bg-gray-100 rounded-xl overflow-hidden">
            {campaign.cover_image_url ? (
              <img
                src={campaign.cover_image_url}
                alt={campaign.title}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-gray-400">
                No Image
              </div>
            )}
          </div>

          {/* Basic Info */}
          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <h2 className="text-lg font-semibold mb-4">기본 정보</h2>
            <dl className="grid grid-cols-2 gap-4">
              <div>
                <dt className="text-sm text-gray-500">제목</dt>
                <dd className="font-medium">{campaign.title}</dd>
              </div>
              <div>
                <dt className="text-sm text-gray-500">카테고리</dt>
                <dd className="font-medium">{campaign.category || '-'}</dd>
              </div>
              <div>
                <dt className="text-sm text-gray-500">목표 금액</dt>
                <dd className="font-medium">{formatDT(campaign.goal_amount_dt)}</dd>
              </div>
              <div>
                <dt className="text-sm text-gray-500">종료일</dt>
                <dd className="font-medium">
                  {campaign.end_at ? formatDate(campaign.end_at) : '-'}
                </dd>
              </div>
              <div className="col-span-2">
                <dt className="text-sm text-gray-500">부제목</dt>
                <dd className="font-medium">{campaign.subtitle || '-'}</dd>
              </div>
            </dl>
          </div>

          {/* Description */}
          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <h2 className="text-lg font-semibold mb-4">프로젝트 소개</h2>
            {campaign.description_md ? (
              <div className="prose prose-gray max-w-none whitespace-pre-wrap">
                {campaign.description_md}
              </div>
            ) : (
              <p className="text-gray-500">소개 없음</p>
            )}
          </div>

          {/* Tiers */}
          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <h2 className="text-lg font-semibold mb-4">리워드 티어 ({tiers.length}개)</h2>
            {tiers.length > 0 ? (
              <div className="space-y-3">
                {tiers.map((tier) => (
                  <div key={tier.id} className="p-4 bg-gray-50 rounded-lg">
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-medium">{tier.title}</span>
                      <span className="font-bold text-primary-500">{formatDT(tier.price_dt)}</span>
                    </div>
                    {tier.description && (
                      <p className="text-sm text-gray-600">{tier.description}</p>
                    )}
                    <div className="mt-2 text-xs text-gray-500">
                      {tier.total_quantity ? `수량: ${tier.total_quantity}개` : '무제한'}
                      {tier.is_featured && ' • 추천 리워드'}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500">등록된 리워드 없음</p>
            )}
          </div>
        </div>

        {/* Actions Sidebar */}
        <div className="space-y-6">
          {/* Status */}
          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <h2 className="text-lg font-semibold mb-4">상태</h2>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-gray-600">현재 상태</span>
                <span className="px-2 py-1 bg-yellow-100 text-yellow-800 text-sm font-medium rounded">
                  {campaign.status === 'submitted' ? '심사 대기' : campaign.status}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-gray-600">생성일</span>
                <span>{formatDate(campaign.created_at)}</span>
              </div>
            </div>
          </div>

          {/* Review Actions */}
          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <h2 className="text-lg font-semibold mb-4">심사</h2>

            {showRejectForm ? (
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    반려 사유 *
                  </label>
                  <textarea
                    value={rejectReason}
                    onChange={(e) => setRejectReason(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                    rows={4}
                    placeholder="반려 사유를 입력해주세요"
                  />
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    className="flex-1"
                    onClick={() => {
                      setShowRejectForm(false)
                      setRejectReason('')
                    }}
                  >
                    취소
                  </Button>
                  <Button
                    variant="danger"
                    className="flex-1"
                    onClick={handleReject}
                    loading={isSubmitting}
                  >
                    반려하기
                  </Button>
                </div>
              </div>
            ) : (
              <div className="space-y-3">
                <Button
                  className="w-full"
                  onClick={handleApprove}
                  loading={isSubmitting}
                >
                  <CheckCircle className="w-4 h-4 mr-2" />
                  승인하기
                </Button>
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={() => setShowRejectForm(true)}
                >
                  <XCircle className="w-4 h-4 mr-2" />
                  반려하기
                </Button>
              </div>
            )}
          </div>

          ```tsx
          {/* Checklist */}
          <div className="bg-white rounded-xl p-6 border border-gray-200">
            <h2 className="text-lg font-semibold mb-4">검토 항목</h2>
            <ul className="space-y-3 text-sm text-gray-600">
              {[
                { id: 'check-content', label: '제목과 내용이 일치' },
                { id: 'check-image', label: '커버 이미지 적절' },
                { id: 'check-price', label: '리워드 가격 적정' },
                { id: 'check-inappropriate', label: '부적절한 내용 없음' },
                { id: 'check-copyright', label: '저작권 문제 없음' },
              ].map((item) => (
                <li key={item.id} className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id={item.id}
                    className="w-4 h-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500 cursor-pointer"
                  />
                  <label htmlFor={item.id} className="cursor-pointer select-none">
                    {item.label}
                  </label>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}