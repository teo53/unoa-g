'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { ArrowLeft } from 'lucide-react'
import { getFlag, updateFlag, publishFlag, rollbackFlag } from '@/lib/ops/ops-client'
import type { OpsFeatureFlag } from '@/lib/ops/ops-types'
import { OpsStatusBadge } from '@/components/ops/ops-status-badge'
import { OpsPublishActions } from '@/components/ops/ops-publish-actions'
import { OpsVersionTimeline } from '@/components/ops/ops-version-timeline'
import { OpsToggleSwitch, RolloutGauge } from '@/components/ops/ops-toggle-switch'
import { useToast } from '@/components/ops/ops-toast'

export default function FlagDetailClient({ id }: { id: string }) {
  const toast = useToast()
  const [flag, setFlag] = useState<OpsFeatureFlag | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [enabled, setEnabled] = useState(false)
  const [rolloutPercent, setRolloutPercent] = useState(100)
  const [payloadJson, setPayloadJson] = useState('{}')

  const loadFlag = useCallback(async () => {
    try {
      const data = await getFlag(id)
      setFlag(data)
      setTitle(data.title)
      setDescription(data.description)
      setEnabled(data.enabled)
      setRolloutPercent(data.rollout_percent)
      setPayloadJson(JSON.stringify(data.payload, null, 2))
    } catch (err) {
      toast.error('로딩 실패', err instanceof Error ? err.message : '플래그를 불러올 수 없습니다')
    } finally {
      setLoading(false)
    }
  }, [id])

  useEffect(() => { loadFlag() }, [loadFlag])

  async function handleSaveDraft() {
    if (!flag) return
    setSaving(true)
    try {
      let payload_data: Record<string, unknown> = {}
      try {
        payload_data = JSON.parse(payloadJson)
      } catch {
        toast.warning('검증 오류', '페이로드 JSON이 올바르지 않습니다')
        setSaving(false)
        return
      }
      const updated = await updateFlag(id, flag.version, {
        title, description, enabled, rollout_percent: rolloutPercent, payload_data,
      })
      setFlag(updated)
      toast.success('저장 완료', '초안이 저장되었습니다')
    } catch (err) {
      toast.error('저장 실패', err instanceof Error ? err.message : '저장 실패')
    } finally {
      setSaving(false)
    }
  }

  async function handlePublish() {
    if (!flag) return
    try {
      const updated = await publishFlag(id, flag.version)
      setFlag(updated)
      toast.success('게시 완료', '플래그가 게시되었습니다')
    } catch (err) {
      toast.error('게시 실패', err instanceof Error ? err.message : '게시 실패')
    }
  }

  async function handleRollback() {
    if (!flag) return
    try {
      const updated = await rollbackFlag(id)
      setFlag(updated)
      toast.success('롤백 완료', '이전 상태로 되돌렸습니다')
    } catch (err) {
      toast.error('롤백 실패', err instanceof Error ? err.message : '롤백 실패')
    }
  }

  if (loading) {
    return <div className="h-64 bg-gray-100 rounded-xl animate-pulse" />
  }

  if (!flag) {
    return <p className="text-gray-500">플래그를 찾을 수 없습니다.</p>
  }

  const isEditable = flag.status === 'draft'

  return (
    <div className="max-w-4xl space-y-6">
      <div className="flex items-center gap-3">
        <Link href="/admin/ops/flags" className="text-gray-500 hover:text-gray-700">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="text-2xl font-bold text-gray-900">{flag.title}</h1>
        <OpsStatusBadge status={flag.status} />
        <code className="text-xs bg-gray-100 px-2 py-1 rounded ml-2">{flag.flag_key}</code>
      </div>

      <OpsPublishActions
        status={flag.status}
        version={flag.version}
        hasPublishedSnapshot={!!flag.published_snapshot}
        onSaveDraft={handleSaveDraft}
        onPublish={handlePublish}
        onRollback={handleRollback}
        disabled={saving}
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-5 bg-white border border-gray-200 rounded-xl p-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">이름</label>
            <input
              type="text"
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              disabled={!isEditable}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">설명</label>
            <textarea
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm disabled:bg-gray-50"
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              disabled={!isEditable}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">활성 상태</label>
              <OpsToggleSwitch
                checked={enabled}
                onChange={(v) => isEditable && setEnabled(v)}
                label={enabled ? '활성' : '비활성'}
                disabled={!isEditable}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                롤아웃 비율: {rolloutPercent}%
              </label>
              <input
                type="range"
                min={0}
                max={100}
                step={5}
                className="w-full"
                value={rolloutPercent}
                onChange={(e) => setRolloutPercent(parseInt(e.target.value))}
                disabled={!isEditable}
              />
              <div className="mt-2">
                <RolloutGauge percent={rolloutPercent} size="sm" />
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">페이로드 (JSON)</label>
            <textarea
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm font-mono disabled:bg-gray-50"
              rows={5}
              value={payloadJson}
              onChange={(e) => setPayloadJson(e.target.value)}
              disabled={!isEditable}
            />
          </div>
        </div>

        <div className="space-y-4">
          <h3 className="font-semibold text-gray-900">변경 이력</h3>
          <OpsVersionTimeline entityType="ops_feature_flags" entityId={id} />
        </div>
      </div>
    </div>
  )
}
