'use client'

import { useEffect, useState } from 'react'
import { Clock, User, Filter } from 'lucide-react'
import { listAuditLog } from '@/lib/ops/ops-client'
import type { OpsAuditEntry } from '@/lib/ops/ops-types'

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
    <div className="mt-2 p-2 bg-gray-50 rounded text-xs font-mono space-y-1">
      {Array.from(allKeys).map((key) => (
        <div key={key}>
          <span className="text-gray-500">{key}: </span>
          {before?.[key] !== undefined && (
            <span className="bg-red-50 text-red-700 line-through px-1 rounded mr-1">
              {JSON.stringify(before[key])}
            </span>
          )}
          {after?.[key] !== undefined && (
            <span className="bg-green-50 text-green-700 px-1 rounded">
              {JSON.stringify(after[key])}
            </span>
          )}
        </div>
      ))}
    </div>
  )
}

export default function AuditPage() {
  const [entries, setEntries] = useState<OpsAuditEntry[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [entityFilter, setEntityFilter] = useState('')
  const [page, setPage] = useState(0)
  const limit = 20

  useEffect(() => {
    async function load() {
      setLoading(true)
      try {
        const result = await listAuditLog({
          entity_type: entityFilter || undefined,
          limit,
          offset: page * limit,
        })
        setEntries(result.items)
        setTotal(result.total)
      } catch {
        // silent
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [entityFilter, page])

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">감사 로그</h1>

      {/* Filters */}
      <div className="flex items-center gap-3">
        <Filter className="w-4 h-4 text-gray-400" />
        <select
          className="text-sm border border-gray-300 rounded-lg px-3 py-2"
          value={entityFilter}
          onChange={(e) => { setEntityFilter(e.target.value); setPage(0) }}
        >
          <option value="">모든 유형</option>
          <option value="ops_banners">배너</option>
          <option value="ops_feature_flags">플래그</option>
          <option value="ops_assets">에셋</option>
          <option value="ops_staff">스태프</option>
        </select>
        <span className="text-sm text-gray-500">총 {total}건</span>
      </div>

      {/* Timeline */}
      {loading ? (
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="h-20 bg-gray-100 rounded-lg animate-pulse" />
          ))}
        </div>
      ) : entries.length === 0 ? (
        <p className="text-sm text-gray-500 text-center py-12">로그가 없습니다.</p>
      ) : (
        <div className="relative">
          <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-gray-200" />
          <div className="space-y-4">
            {entries.map((entry) => (
              <div key={entry.id} className="relative pl-10">
                <div className="absolute left-2.5 top-2 w-3 h-3 rounded-full bg-blue-500 border-2 border-white" />
                <div className="bg-white border border-gray-200 rounded-lg p-4">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <span className="font-medium text-gray-900">
                        {ACTION_LABELS[entry.action] || entry.action}
                      </span>
                      {entry.entity_id && (
                        <span className="ml-2 text-xs text-gray-400 font-mono">
                          {entry.entity_id.slice(0, 8)}...
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-2 text-xs text-gray-500 shrink-0">
                      <User className="w-3 h-3" />
                      <span>{entry.actor_role}</span>
                      <Clock className="w-3 h-3 ml-1" />
                      <span>{new Date(entry.created_at).toLocaleString('ko-KR')}</span>
                    </div>
                  </div>
                  <DiffView before={entry.before} after={entry.after} />
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Pagination */}
      {total > limit && (
        <div className="flex justify-center gap-2">
          <button
            className="px-3 py-1 text-sm border rounded disabled:opacity-30"
            disabled={page === 0}
            onClick={() => setPage(page - 1)}
          >
            이전
          </button>
          <span className="px-3 py-1 text-sm text-gray-600">
            {page + 1} / {Math.ceil(total / limit)}
          </span>
          <button
            className="px-3 py-1 text-sm border rounded disabled:opacity-30"
            disabled={(page + 1) * limit >= total}
            onClick={() => setPage(page + 1)}
          >
            다음
          </button>
        </div>
      )}
    </div>
  )
}
