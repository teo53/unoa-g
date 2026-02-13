'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Plus, ToggleLeft, ToggleRight } from 'lucide-react'
import { listFlags, createFlag } from '@/lib/ops/ops-client'
import type { OpsFeatureFlag } from '@/lib/ops/ops-types'
import { OpsStatusBadge } from '@/components/ops/ops-status-badge'
import { OpsDataTable } from '@/components/ops/ops-data-table'

export default function FlagsPage() {
  const router = useRouter()
  const [flags, setFlags] = useState<OpsFeatureFlag[]>([])
  const [loading, setLoading] = useState(true)
  const [showNew, setShowNew] = useState(false)
  const [newKey, setNewKey] = useState('')
  const [newTitle, setNewTitle] = useState('')
  const [creating, setCreating] = useState(false)

  useEffect(() => {
    async function load() {
      try {
        const data = await listFlags()
        setFlags(data)
      } catch {
        // demo fallback
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [])

  async function handleCreate() {
    if (!newKey.trim() || !newTitle.trim()) return
    setCreating(true)
    try {
      const flag = await createFlag({
        flag_key: newKey.trim(),
        title: newTitle.trim(),
        description: '',
        enabled: false,
        rollout_percent: 100,
        payload_data: {},
      })
      router.push(`/admin/ops/flags/${flag.id}`)
    } catch {
      // handled
    } finally {
      setCreating(false)
    }
  }

  const columns = [
    {
      key: 'flag_key',
      label: '키',
      sortable: true,
      render: (item: OpsFeatureFlag) => (
        <code className="text-sm bg-gray-100 px-2 py-0.5 rounded">{item.flag_key}</code>
      ),
    },
    {
      key: 'title',
      label: '이름',
      sortable: true,
      render: (item: OpsFeatureFlag) => (
        <span className="font-medium text-gray-900">{item.title}</span>
      ),
    },
    {
      key: 'enabled',
      label: '활성',
      render: (item: OpsFeatureFlag) =>
        item.enabled ? (
          <ToggleRight className="w-5 h-5 text-green-600" />
        ) : (
          <ToggleLeft className="w-5 h-5 text-gray-400" />
        ),
    },
    {
      key: 'rollout_percent',
      label: '롤아웃',
      render: (item: OpsFeatureFlag) => (
        <span className="text-sm text-gray-600">{item.rollout_percent}%</span>
      ),
    },
    {
      key: 'status',
      label: '상태',
      sortable: true,
      render: (item: OpsFeatureFlag) => <OpsStatusBadge status={item.status} size="sm" />,
    },
    {
      key: 'version',
      label: 'v',
      className: 'text-center',
      render: (item: OpsFeatureFlag) => (
        <span className="text-xs text-gray-400">v{item.version}</span>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">기능 플래그</h1>
        <button
          className="inline-flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm font-medium"
          onClick={() => setShowNew(!showNew)}
        >
          <Plus className="w-4 h-4" />
          새 플래그
        </button>
      </div>

      {/* Inline create */}
      {showNew && (
        <div className="bg-white border border-gray-200 rounded-lg p-4 flex items-end gap-3">
          <div className="flex-1">
            <label className="block text-xs text-gray-500 mb-1">키 (영문, _)</label>
            <input
              type="text"
              className="w-full border border-gray-300 rounded px-3 py-2 text-sm"
              placeholder="my_feature_flag"
              value={newKey}
              onChange={(e) => setNewKey(e.target.value.replace(/[^a-z0-9_]/gi, '_').toLowerCase())}
            />
          </div>
          <div className="flex-1">
            <label className="block text-xs text-gray-500 mb-1">이름</label>
            <input
              type="text"
              className="w-full border border-gray-300 rounded px-3 py-2 text-sm"
              placeholder="새 기능 이름"
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
            />
          </div>
          <button
            className="px-4 py-2 bg-green-600 text-white rounded text-sm disabled:opacity-50"
            disabled={creating || !newKey || !newTitle}
            onClick={handleCreate}
          >
            {creating ? '생성 중...' : '생성'}
          </button>
          <button
            className="px-4 py-2 text-gray-500 text-sm"
            onClick={() => setShowNew(false)}
          >
            취소
          </button>
        </div>
      )}

      <OpsDataTable
        data={flags as unknown as Record<string, unknown>[]}
        columns={columns as never}
        loading={loading}
        emptyMessage="등록된 플래그가 없습니다."
        onRowClick={(item) => router.push(`/admin/ops/flags/${(item as unknown as OpsFeatureFlag).id}`)}
      />
    </div>
  )
}
