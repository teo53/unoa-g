'use client'

import { useEffect, useState } from 'react'
import { Clock, User } from 'lucide-react'
import { listAuditLog } from '@/lib/ops/ops-client'
import type { OpsAuditEntry } from '@/lib/ops/ops-types'

interface OpsVersionTimelineProps {
  entityType: string
  entityId: string
}

/** Render a single diff field with color-coded before/after */
function DiffField({ fieldKey, before, after }: {
  fieldKey: string
  before: unknown
  after: unknown
}) {
  const hasBefore = before !== undefined
  const hasAfter = after !== undefined

  return (
    <div className="text-xs font-mono mt-1">
      <span className="text-gray-500">{fieldKey}: </span>
      {hasBefore && (
        <span className="bg-red-50 text-red-700 line-through px-1 rounded mr-1">
          {JSON.stringify(before)}
        </span>
      )}
      {hasAfter && (
        <span className="bg-green-50 text-green-700 px-1 rounded">
          {JSON.stringify(after)}
        </span>
      )}
    </div>
  )
}

/** Render diff between before and after JSONB */
function DiffView({ before, after }: {
  before: Record<string, unknown> | null
  after: Record<string, unknown> | null
}) {
  if (!before && !after) return null

  const allKeys = new Set<string>()
  if (before) Object.keys(before).forEach((k) => allKeys.add(k))
  if (after) Object.keys(after).forEach((k) => allKeys.add(k))

  if (allKeys.size === 0) return null

  return (
    <div className="mt-2 p-2 bg-gray-50 rounded text-xs">
      {Array.from(allKeys).map((key) => (
        <DiffField
          key={key}
          fieldKey={key}
          before={before?.[key]}
          after={after?.[key]}
        />
      ))}
    </div>
  )
}

const ACTION_LABELS: Record<string, string> = {
  'banner.create': '배너 생성',
  'banner.update': '배너 수정',
  'banner.submit_review': '검수 요청',
  'banner.publish': '배너 게시',
  'banner.rollback': '배너 롤백',
  'banner.archive': '배너 보관',
  'flag.create': '플래그 생성',
  'flag.update': '플래그 수정',
  'flag.publish': '플래그 게시',
  'flag.rollback': '플래그 롤백',
  'asset.upload': '에셋 업로드',
  'asset.delete': '에셋 삭제',
  'staff.create': '스태프 추가',
  'staff.update': '스태프 수정',
  'staff.remove': '스태프 삭제',
}

export function OpsVersionTimeline({ entityType, entityId }: OpsVersionTimelineProps) {
  const [entries, setEntries] = useState<OpsAuditEntry[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      try {
        const result = await listAuditLog({
          entity_type: entityType,
          entity_id: entityId,
          limit: 20,
        })
        setEntries(result.items)
      } catch {
        // Silently fail — timeline is supplementary
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [entityType, entityId])

  if (loading) {
    return (
      <div className="animate-pulse space-y-3">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-12 bg-gray-100 rounded" />
        ))}
      </div>
    )
  }

  if (entries.length === 0) {
    return (
      <p className="text-sm text-gray-500 py-4 text-center">
        변경 이력이 없습니다.
      </p>
    )
  }

  return (
    <div className="relative">
      {/* Vertical line */}
      <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-gray-200" />

      <div className="space-y-4">
        {entries.map((entry) => (
          <div key={entry.id} className="relative pl-10">
            {/* Dot */}
            <div className="absolute left-2.5 top-1.5 w-3 h-3 rounded-full bg-blue-500 border-2 border-white" />

            <div className="bg-white border border-gray-200 rounded-lg p-3">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-gray-900">
                  {ACTION_LABELS[entry.action] || entry.action}
                </span>
                <div className="flex items-center gap-1 text-xs text-gray-500">
                  <Clock className="w-3 h-3" />
                  {new Date(entry.created_at).toLocaleString('ko-KR')}
                </div>
              </div>

              <div className="flex items-center gap-1 mt-1 text-xs text-gray-500">
                <User className="w-3 h-3" />
                <span>{entry.actor_role}</span>
              </div>

              <DiffView before={entry.before} after={entry.after} />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
