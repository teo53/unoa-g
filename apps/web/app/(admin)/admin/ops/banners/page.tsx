'use client'

import { Suspense, useEffect, useState, useCallback } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { Plus, GripVertical, ArrowUpDown } from 'lucide-react'
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core'
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { listBanners, updateBanner } from '@/lib/ops/ops-client'
import type { OpsBanner } from '@/lib/ops/ops-types'
import { PLACEMENT_LABELS } from '@/lib/ops/ops-types'
import { OpsStatusBadge } from '@/components/ops/ops-status-badge'
import { OpsDataTable } from '@/components/ops/ops-data-table'

// ── Sortable Banner Row ──

function SortableBannerRow({
  banner,
  onClick,
}: {
  banner: OpsBanner
  onClick: () => void
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: banner.id })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={`flex items-center gap-3 px-4 py-3 bg-white border border-gray-200 rounded-lg ${
        isDragging ? 'shadow-lg opacity-75 z-10' : ''
      }`}
    >
      {/* Drag handle */}
      <button
        className="flex-shrink-0 p-1 text-gray-400 hover:text-gray-600 cursor-grab active:cursor-grabbing rounded"
        {...attributes}
        {...listeners}
        aria-label="드래그하여 순서 변경"
      >
        <GripVertical className="w-4 h-4" />
      </button>

      {/* Priority number */}
      <span className="flex-shrink-0 w-8 h-8 flex items-center justify-center text-xs font-mono text-gray-500 bg-gray-100 rounded">
        {banner.priority}
      </span>

      {/* Content — clickable to navigate */}
      <div
        className="flex-1 min-w-0 flex items-center gap-4 cursor-pointer"
        onClick={onClick}
      >
        <span className="font-medium text-gray-900 truncate">{banner.title}</span>
        <span className="text-xs text-gray-500 flex-shrink-0">
          {PLACEMENT_LABELS[banner.placement] || banner.placement}
        </span>
        <OpsStatusBadge status={banner.status} size="sm" />
        <span className="text-xs text-gray-400 ml-auto flex-shrink-0">v{banner.version}</span>
      </div>
    </div>
  )
}

// ── Main Page ──

export default function BannersPageWrapper() {
  return (
    <Suspense fallback={<div className="h-64 bg-gray-100 rounded-xl animate-pulse" />}>
      <BannersPage />
    </Suspense>
  )
}

function BannersPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const statusFilter = searchParams.get('status') || ''
  const placementFilter = searchParams.get('placement') || ''

  const [banners, setBanners] = useState<OpsBanner[]>([])
  const [loading, setLoading] = useState(true)
  const [reorderMode, setReorderMode] = useState(false)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    async function load() {
      setLoading(true)
      try {
        const data = await listBanners({
          status: statusFilter || undefined,
          placement: placementFilter || undefined,
        })
        setBanners(data)
      } catch {
        // Error handled by demo mode fallback
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [statusFilter, placementFilter])

  // DnD sensors
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  )

  // Sort banners by priority for reorder mode
  const sortedBanners = [...banners].sort((a, b) => a.priority - b.priority)

  const handleDragEnd = useCallback(
    async (event: DragEndEvent) => {
      const { active, over } = event
      if (!over || active.id === over.id) return

      const oldIndex = sortedBanners.findIndex((b) => b.id === active.id)
      const newIndex = sortedBanners.findIndex((b) => b.id === over.id)
      if (oldIndex === -1 || newIndex === -1) return

      const reordered = arrayMove(sortedBanners, oldIndex, newIndex)

      // Update priorities: 1-based sequential
      const updated = reordered.map((b, i) => ({ ...b, priority: i + 1 }))
      setBanners(updated)

      // Persist changed priorities to server
      setSaving(true)
      try {
        const promises = updated
          .filter((b, i) => {
            const original = sortedBanners.find((sb) => sb.id === b.id)
            return original && original.priority !== i + 1
          })
          .map((b) => updateBanner(b.id, b.version, { priority: b.priority }))
        await Promise.all(promises)
        // Update versions from response (optimistic: already reflected)
      } catch {
        // Revert on error — reload from server
        const data = await listBanners({
          status: statusFilter || undefined,
          placement: placementFilter || undefined,
        })
        setBanners(data)
      } finally {
        setSaving(false)
      }
    },
    [sortedBanners, statusFilter, placementFilter]
  )

  const columns = [
    {
      key: 'title',
      label: '제목',
      sortable: true,
      render: (item: OpsBanner) => (
        <span className="font-medium text-gray-900">{item.title}</span>
      ),
    },
    {
      key: 'placement',
      label: '배치',
      render: (item: OpsBanner) => (
        <span className="text-sm text-gray-600">
          {PLACEMENT_LABELS[item.placement] || item.placement}
        </span>
      ),
    },
    {
      key: 'status',
      label: '상태',
      sortable: true,
      render: (item: OpsBanner) => <OpsStatusBadge status={item.status} size="sm" />,
    },
    {
      key: 'priority',
      label: '우선순위',
      sortable: true,
      className: 'text-center',
      render: (item: OpsBanner) => (
        <span className="text-sm text-gray-600">{item.priority}</span>
      ),
    },
    {
      key: 'version',
      label: '버전',
      className: 'text-center',
      render: (item: OpsBanner) => (
        <span className="text-xs text-gray-400">v{item.version}</span>
      ),
    },
    {
      key: 'updated_at',
      label: '수정일',
      sortable: true,
      render: (item: OpsBanner) => (
        <span className="text-sm text-gray-500">
          {new Date(item.updated_at).toLocaleDateString('ko-KR')}
        </span>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">배너 관리</h1>
        <div className="flex items-center gap-2">
          <button
            className={`inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium rounded-lg border transition-colors ${
              reorderMode
                ? 'bg-blue-50 text-blue-700 border-blue-200'
                : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
            }`}
            onClick={() => setReorderMode(!reorderMode)}
            disabled={saving}
          >
            <ArrowUpDown className="w-4 h-4" />
            {reorderMode ? '순서 조정 완료' : '순서 조정'}
          </button>
          <Link
            href="/admin/ops/banners/new"
            className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium"
          >
            <Plus className="w-4 h-4" />
            새 배너
          </Link>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3">
        <select
          className="text-sm border border-gray-300 rounded-lg px-3 py-2"
          value={statusFilter}
          onChange={(e) => {
            const params = new URLSearchParams(searchParams.toString())
            if (e.target.value) params.set('status', e.target.value)
            else params.delete('status')
            router.push(`/admin/ops/banners?${params.toString()}`)
          }}
        >
          <option value="">모든 상태</option>
          <option value="draft">초안</option>
          <option value="in_review">검수 중</option>
          <option value="published">게시됨</option>
          <option value="archived">보관됨</option>
        </select>

        <select
          className="text-sm border border-gray-300 rounded-lg px-3 py-2"
          value={placementFilter}
          onChange={(e) => {
            const params = new URLSearchParams(searchParams.toString())
            if (e.target.value) params.set('placement', e.target.value)
            else params.delete('placement')
            router.push(`/admin/ops/banners?${params.toString()}`)
          }}
        >
          <option value="">모든 배치</option>
          {Object.entries(PLACEMENT_LABELS).map(([key, label]) => (
            <option key={key} value={key}>{label}</option>
          ))}
        </select>

        {saving && (
          <span className="text-xs text-gray-500 flex items-center gap-1.5">
            <span className="w-3 h-3 border-2 border-gray-400 border-t-transparent rounded-full animate-spin" />
            저장 중...
          </span>
        )}
      </div>

      {/* Reorder Mode: DnD sortable list */}
      {reorderMode ? (
        <DndContext
          sensors={sensors}
          collisionDetection={closestCenter}
          onDragEnd={handleDragEnd}
        >
          <SortableContext
            items={sortedBanners.map((b) => b.id)}
            strategy={verticalListSortingStrategy}
          >
            <div className="space-y-2">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <div key={i} className="h-14 bg-gray-100 rounded-lg animate-pulse" />
                ))
              ) : sortedBanners.length === 0 ? (
                <div className="text-center py-8 text-gray-500 bg-white border border-gray-200 rounded-lg">
                  등록된 배너가 없습니다.
                </div>
              ) : (
                sortedBanners.map((banner) => (
                  <SortableBannerRow
                    key={banner.id}
                    banner={banner}
                    onClick={() => router.push(`/admin/ops/banners/${banner.id}`)}
                  />
                ))
              )}
            </div>
          </SortableContext>
        </DndContext>
      ) : (
        /* Normal Table Mode */
        <OpsDataTable
          data={banners as unknown as Record<string, unknown>[]}
          columns={columns as never}
          loading={loading}
          emptyMessage="등록된 배너가 없습니다."
          onRowClick={(item) => router.push(`/admin/ops/banners/${(item as unknown as OpsBanner).id}`)}
        />
      )}
    </div>
  )
}
