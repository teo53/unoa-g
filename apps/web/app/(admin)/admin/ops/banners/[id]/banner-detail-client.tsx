'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { ArrowLeft } from 'lucide-react'
import {
  getBanner,
  updateBanner,
  submitBannerReview,
  publishBanner,
  rollbackBanner,
  archiveBanner,
} from '@/lib/ops/ops-client'
import type { OpsBanner, BannerPlacement, LinkType, TargetAudience } from '@/lib/ops/ops-types'
import { PLACEMENT_LABELS } from '@/lib/ops/ops-types'
import { OpsStatusBadge } from '@/components/ops/ops-status-badge'
import { OpsPublishActions } from '@/components/ops/ops-publish-actions'
import { OpsVersionTimeline } from '@/components/ops/ops-version-timeline'
import { OpsImageUploader } from '@/components/ops/ops-image-uploader'

export default function BannerDetailClient({ id }: { id: string }) {
  const [banner, setBanner] = useState<OpsBanner | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [successMsg, setSuccessMsg] = useState<string | null>(null)

  // Editable fields
  const [title, setTitle] = useState('')
  const [placement, setPlacement] = useState<BannerPlacement>('home_top')
  const [imageUrl, setImageUrl] = useState('')
  const [linkUrl, setLinkUrl] = useState('')
  const [linkType, setLinkType] = useState<LinkType>('internal')
  const [priority, setPriority] = useState(0)
  const [startAt, setStartAt] = useState('')
  const [endAt, setEndAt] = useState('')
  const [targetAudience, setTargetAudience] = useState<TargetAudience>('all')

  const loadBanner = useCallback(async () => {
    try {
      const data = await getBanner(id)
      setBanner(data)
      setTitle(data.title)
      setPlacement(data.placement)
      setImageUrl(data.image_url)
      setLinkUrl(data.link_url)
      setLinkType(data.link_type)
      setPriority(data.priority)
      setStartAt(data.start_at || '')
      setEndAt(data.end_at || '')
      setTargetAudience(data.target_audience)
    } catch (err) {
      setError(err instanceof Error ? err.message : '배너를 불러올 수 없습니다')
    } finally {
      setLoading(false)
    }
  }, [id])

  useEffect(() => {
    loadBanner()
  }, [loadBanner])

  function showSuccess(msg: string) {
    setSuccessMsg(msg)
    setTimeout(() => setSuccessMsg(null), 3000)
  }

  async function handleSaveDraft() {
    if (!banner) return
    setSaving(true)
    setError(null)
    try {
      const updated = await updateBanner(id, banner.version, {
        title, placement, image_url: imageUrl, link_url: linkUrl,
        link_type: linkType, priority, start_at: startAt, end_at: endAt,
        target_audience: targetAudience,
      })
      setBanner(updated)
      showSuccess('초안이 저장되었습니다')
    } catch (err) {
      setError(err instanceof Error ? err.message : '저장 실패')
    } finally {
      setSaving(false)
    }
  }

  async function handleSubmitReview() {
    if (!banner) return
    try {
      const updated = await submitBannerReview(id, banner.version)
      setBanner(updated)
      showSuccess('검수 요청이 완료되었습니다')
    } catch (err) {
      setError(err instanceof Error ? err.message : '검수 요청 실패')
    }
  }

  async function handlePublish() {
    if (!banner) return
    try {
      const updated = await publishBanner(id, banner.version)
      setBanner(updated)
      showSuccess('배너가 게시되었습니다')
    } catch (err) {
      setError(err instanceof Error ? err.message : '게시 실패')
    }
  }

  async function handleRollback() {
    if (!banner) return
    try {
      const updated = await rollbackBanner(id)
      setBanner(updated)
      showSuccess('롤백이 완료되었습니다')
    } catch (err) {
      setError(err instanceof Error ? err.message : '롤백 실패')
    }
  }

  async function handleArchive() {
    if (!banner) return
    try {
      const updated = await archiveBanner(id, banner.version)
      setBanner(updated)
      showSuccess('배너가 보관되었습니다')
    } catch (err) {
      setError(err instanceof Error ? err.message : '보관 실패')
    }
  }

  if (loading) {
    return <div className="space-y-4">
      <div className="h-8 w-48 bg-gray-100 rounded animate-pulse" />
      <div className="h-64 bg-gray-100 rounded-xl animate-pulse" />
    </div>
  }

  if (!banner) {
    return <p className="text-gray-500">배너를 찾을 수 없습니다.</p>
  }

  const isEditable = banner.status === 'draft' || banner.status === 'in_review'

  return (
    <div className="max-w-4xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link href="/admin/ops/banners" className="text-gray-500 hover:text-gray-700">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">{banner.title}</h1>
        <OpsStatusBadge status={banner.status} />
      </div>

      {/* Messages */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-3 text-sm text-red-700">
          {error}
          <button className="ml-2 underline" onClick={() => setError(null)}>닫기</button>
        </div>
      )}
      {successMsg && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-3 text-sm text-green-700">
          {successMsg}
        </div>
      )}

      {/* Actions */}
      <OpsPublishActions
        status={banner.status}
        version={banner.version}
        hasPublishedSnapshot={!!banner.published_snapshot}
        onSaveDraft={handleSaveDraft}
        onSubmitReview={handleSubmitReview}
        onPublish={handlePublish}
        onRollback={handleRollback}
        onArchive={handleArchive}
        disabled={saving}
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Form */}
        <div className="lg:col-span-2 space-y-5 bg-white border border-gray-200 rounded-xl p-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">제목</label>
            <input
              type="text"
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              disabled={!isEditable}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">배치 위치</label>
            <select
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
              value={placement}
              onChange={(e) => setPlacement(e.target.value as BannerPlacement)}
              disabled={!isEditable}
            >
              {Object.entries(PLACEMENT_LABELS).map(([key, label]) => (
                <option key={key} value={key}>{label}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">이미지</label>
            {imageUrl ? (
              <div className="relative">
                <img src={imageUrl} alt="Banner" className="w-full max-h-48 object-contain rounded border" />
                {isEditable && (
                  <button
                    className="absolute top-2 right-2 bg-white text-xs px-2 py-1 rounded shadow"
                    onClick={() => setImageUrl('')}
                  >
                    변경
                  </button>
                )}
              </div>
            ) : isEditable ? (
              <OpsImageUploader
                onUploadComplete={(asset) => setImageUrl(asset.public_url)}
                tags={['banner']}
              />
            ) : (
              <p className="text-sm text-gray-500">이미지 없음</p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">링크 타입</label>
              <select
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
                value={linkType}
                onChange={(e) => setLinkType(e.target.value as LinkType)}
                disabled={!isEditable}
              >
                <option value="internal">내부</option>
                <option value="external">외부</option>
                <option value="none">없음</option>
              </select>
            </div>
            {linkType !== 'none' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">링크 URL</label>
                <input
                  type="text"
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
                  value={linkUrl}
                  onChange={(e) => setLinkUrl(e.target.value)}
                  disabled={!isEditable}
                />
              </div>
            )}
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">우선순위</label>
              <input
                type="number"
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
                value={priority}
                onChange={(e) => setPriority(parseInt(e.target.value) || 0)}
                disabled={!isEditable}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">대상</label>
              <select
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
                value={targetAudience}
                onChange={(e) => setTargetAudience(e.target.value as TargetAudience)}
                disabled={!isEditable}
              >
                <option value="all">전체</option>
                <option value="fans">팬</option>
                <option value="creators">크리에이터</option>
                <option value="vip">VIP</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">시작일</label>
              <input
                type="datetime-local"
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
                value={startAt}
                onChange={(e) => setStartAt(e.target.value)}
                disabled={!isEditable}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">종료일</label>
              <input
                type="datetime-local"
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
                value={endAt}
                onChange={(e) => setEndAt(e.target.value)}
                disabled={!isEditable}
              />
            </div>
          </div>
        </div>

        {/* Timeline */}
        <div className="space-y-4">
          <h3 className="font-semibold text-gray-900">변경 이력</h3>
          <OpsVersionTimeline entityType="ops_banners" entityId={id} />
        </div>
      </div>
    </div>
  )
}
