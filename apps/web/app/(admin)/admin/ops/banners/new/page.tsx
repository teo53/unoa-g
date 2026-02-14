'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { ArrowLeft, Info } from 'lucide-react'
import Link from 'next/link'
import { createBanner } from '@/lib/ops/ops-client'
import type { BannerFormData, BannerPlacement, LinkType, TargetAudience } from '@/lib/ops/ops-types'
import { PLACEMENT_LABELS, PLACEMENT_DIMENSIONS } from '@/lib/ops/ops-types'
import { OpsImageUploader } from '@/components/ops/ops-image-uploader'

export default function NewBannerPage() {
  const router = useRouter()
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [form, setForm] = useState<BannerFormData>({
    title: '',
    placement: 'home_top',
    image_url: '',
    link_url: '',
    link_type: 'internal',
    priority: 0,
    start_at: '',
    end_at: '',
    target_audience: 'all',
  })

  function updateForm(key: keyof BannerFormData, value: string | number) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  async function handleSave() {
    if (!form.title.trim()) {
      setError('제목을 입력해주세요')
      return
    }
    setSaving(true)
    setError(null)
    try {
      const banner = await createBanner(form)
      router.push(`/admin/ops/banners/${banner.id}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : '생성 실패')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="max-w-3xl space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Link href="/admin/ops/banners" className="text-gray-500 hover:text-gray-700">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">새 배너</h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Form */}
      <div className="bg-white border border-gray-200 rounded-xl p-6 space-y-5">
        {/* Title */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">제목</label>
          <input
            type="text"
            className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            placeholder="배너 제목을 입력하세요"
            value={form.title}
            onChange={(e) => updateForm('title', e.target.value)}
          />
        </div>

        {/* Placement */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">배치 위치</label>
          <select
            className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
            value={form.placement}
            onChange={(e) => updateForm('placement', e.target.value as BannerPlacement)}
          >
            {Object.entries(PLACEMENT_LABELS).map(([key, label]) => (
              <option key={key} value={key}>{label}</option>
            ))}
          </select>

          {/* Dimension Guide */}
          {form.placement && PLACEMENT_DIMENSIONS[form.placement as BannerPlacement] && (
            <div className="mt-3 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-start gap-3">
                <Info className="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <div className="font-medium text-blue-900 text-sm">
                    권장 규격: {PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].width} x {PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].height}px
                    ({PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].aspectRatio})
                  </div>
                  <div className="text-blue-700 text-xs mt-1">
                    {PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].description}
                  </div>
                  {PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].safeZone && (
                    <div className="text-blue-600 text-xs mt-1">
                      안전 영역: {PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].safeZone}
                    </div>
                  )}
                  <div
                    className="mt-3 border-2 border-dashed border-blue-300 rounded bg-blue-100/50 flex items-center justify-center text-blue-400 text-xs"
                    style={{
                      aspectRatio: `${PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].width} / ${PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].height}`,
                      maxHeight: '150px',
                    }}
                  >
                    {PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].width} x {PLACEMENT_DIMENSIONS[form.placement as BannerPlacement].height}
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Image */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">배너 이미지</label>
          {form.image_url ? (
            <div className="relative">
              <img
                src={form.image_url}
                alt="Banner preview"
                className="w-full max-h-48 object-contain rounded-lg border"
              />
              <button
                className="absolute top-2 right-2 bg-white text-xs px-2 py-1 rounded shadow"
                onClick={() => updateForm('image_url', '')}
              >
                변경
              </button>
            </div>
          ) : (
            <OpsImageUploader
              onUploadComplete={(asset) => updateForm('image_url', asset.public_url)}
              tags={['banner']}
            />
          )}
        </div>

        {/* Link */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">링크 타입</label>
            <select
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
              value={form.link_type}
              onChange={(e) => updateForm('link_type', e.target.value as LinkType)}
            >
              <option value="internal">내부 링크</option>
              <option value="external">외부 링크</option>
              <option value="none">없음</option>
            </select>
          </div>
          {form.link_type !== 'none' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">링크 URL</label>
              <input
                type="text"
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
                placeholder={form.link_type === 'internal' ? '/discover' : 'https://...'}
                value={form.link_url}
                onChange={(e) => updateForm('link_url', e.target.value)}
              />
            </div>
          )}
        </div>

        {/* Priority + Target */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">우선순위</label>
            <input
              type="number"
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
              value={form.priority}
              onChange={(e) => updateForm('priority', parseInt(e.target.value) || 0)}
            />
            <p className="text-xs text-gray-400 mt-1">높을수록 먼저 표시</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">대상</label>
            <select
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
              value={form.target_audience}
              onChange={(e) => updateForm('target_audience', e.target.value as TargetAudience)}
            >
              <option value="all">전체</option>
              <option value="fans">팬</option>
              <option value="creators">크리에이터</option>
              <option value="vip">VIP</option>
            </select>
          </div>
        </div>

        {/* Schedule */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">시작일 (선택)</label>
            <input
              type="datetime-local"
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
              value={form.start_at}
              onChange={(e) => updateForm('start_at', e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">종료일 (선택)</label>
            <input
              type="datetime-local"
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
              value={form.end_at}
              onChange={(e) => updateForm('end_at', e.target.value)}
            />
          </div>
        </div>
      </div>

      {/* Actions */}
      <div className="flex justify-end gap-3">
        <Link
          href="/admin/ops/banners"
          className="px-4 py-2 text-sm text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
        >
          취소
        </Link>
        <button
          className="px-4 py-2 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
          disabled={saving}
          onClick={handleSave}
        >
          {saving ? '저장 중...' : '초안 저장'}
        </button>
      </div>
    </div>
  )
}
