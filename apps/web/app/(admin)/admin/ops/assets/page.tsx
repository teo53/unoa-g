'use client'

import { useEffect, useState, useMemo, useRef, useCallback } from 'react'
import {
  Trash2, Copy, Check, Image as ImageIcon,
  Search, X, LayoutGrid, List, ChevronLeft, ChevronRight,
} from 'lucide-react'
import { listAssets, deleteAsset } from '@/lib/ops/ops-client'
import type { OpsAsset } from '@/lib/ops/ops-types'
import { OpsImageUploader } from '@/components/ops/ops-image-uploader'
import { OpsConfirmModal } from '@/components/ops/ops-confirm-modal'
import { DEMO_MODE } from '@/lib/mock/demo-data'

const PAGE_SIZE = 12

type SortKey = 'newest' | 'name' | 'size'

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

// ── Asset Card (Grid view) ──

function AssetCard({ asset, onDelete }: { asset: OpsAsset; onDelete: () => void }) {
  const [copied, setCopied] = useState(false)

  function handleCopy() {
    navigator.clipboard.writeText(asset.public_url)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="bg-white border border-gray-200 rounded-lg overflow-hidden group">
      <div className="aspect-video bg-gray-100 relative">
        <img
          src={asset.public_url}
          alt={asset.alt_text || asset.file_name}
          className="w-full h-full object-contain"
        />
        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors" />
      </div>
      <div className="p-3">
        <p className="text-sm font-medium text-gray-900 truncate">{asset.file_name}</p>
        <div className="flex items-center gap-2 mt-1">
          <span className="text-xs text-gray-400">{formatFileSize(asset.file_size)}</span>
          {asset.width && asset.height && (
            <span className="text-xs text-gray-400">{asset.width}x{asset.height}</span>
          )}
        </div>
        {asset.tags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-2">
            {asset.tags.map((tag) => (
              <span key={tag} className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded">
                {tag}
              </span>
            ))}
          </div>
        )}
        <div className="flex items-center gap-1 mt-2">
          <button
            className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded"
            onClick={handleCopy}
            title="URL 복사"
          >
            {copied ? <Check className="w-3.5 h-3.5 text-green-600" /> : <Copy className="w-3.5 h-3.5" />}
          </button>
          <button
            className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded"
            onClick={onDelete}
            title="삭제"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>
  )
}

// ── Asset Row (List view) ──

function AssetRow({ asset, onDelete }: { asset: OpsAsset; onDelete: () => void }) {
  const [copied, setCopied] = useState(false)

  function handleCopy() {
    navigator.clipboard.writeText(asset.public_url)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="flex items-center gap-4 px-4 py-3 bg-white border-b border-gray-100 last:border-0 hover:bg-gray-50">
      <div className="w-16 h-12 bg-gray-100 rounded overflow-hidden flex-shrink-0">
        <img
          src={asset.public_url}
          alt={asset.alt_text || asset.file_name}
          className="w-full h-full object-contain"
        />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-900 truncate">{asset.file_name}</p>
        <div className="flex items-center gap-2 mt-0.5">
          <span className="text-xs text-gray-400">{formatFileSize(asset.file_size)}</span>
          {asset.width && asset.height && (
            <span className="text-xs text-gray-400">{asset.width}x{asset.height}</span>
          )}
          <span className="text-xs text-gray-400">
            {new Date(asset.created_at).toLocaleDateString('ko-KR')}
          </span>
        </div>
      </div>
      {asset.tags.length > 0 && (
        <div className="flex gap-1 flex-shrink-0">
          {asset.tags.slice(0, 2).map((tag) => (
            <span key={tag} className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded">
              {tag}
            </span>
          ))}
          {asset.tags.length > 2 && (
            <span className="text-xs text-gray-400">+{asset.tags.length - 2}</span>
          )}
        </div>
      )}
      <div className="flex items-center gap-1 flex-shrink-0">
        <button
          className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded"
          onClick={handleCopy}
          title="URL 복사"
        >
          {copied ? <Check className="w-3.5 h-3.5 text-green-600" /> : <Copy className="w-3.5 h-3.5" />}
        </button>
        <button
          className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded"
          onClick={onDelete}
          title="삭제"
        >
          <Trash2 className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  )
}

// ── Main Page ──

export default function AssetsPage() {
  const [assets, setAssets] = useState<OpsAsset[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)

  // Search, filter, sort, pagination, view
  const [searchQuery, setSearchQuery] = useState('')
  const [debouncedQuery, setDebouncedQuery] = useState('')
  const [selectedTag, setSelectedTag] = useState<string | null>(null)
  const [sortKey, setSortKey] = useState<SortKey>('newest')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [page, setPage] = useState(0)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  // Debounce search input
  const handleSearchChange = useCallback((value: string) => {
    setSearchQuery(value)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => {
      setDebouncedQuery(value)
      setPage(0)
    }, 300)
  }, [])

  async function load() {
    setLoading(true)
    try {
      const result = await listAssets({ limit: 200 })
      setAssets(result.items)
      setTotal(result.total)
    } catch {
      // silent
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [])

  // Collect all unique tags
  const allTags = useMemo(() => {
    const tagSet = new Set<string>()
    assets.forEach((a) => a.tags.forEach((t) => tagSet.add(t)))
    return Array.from(tagSet).sort()
  }, [assets])

  // Filter + sort
  const filtered = useMemo(() => {
    let result = assets

    // Search by filename
    if (debouncedQuery.trim()) {
      const q = debouncedQuery.toLowerCase()
      result = result.filter((a) => a.file_name.toLowerCase().includes(q))
    }

    // Tag filter
    if (selectedTag) {
      result = result.filter((a) => a.tags.includes(selectedTag))
    }

    // Sort
    switch (sortKey) {
      case 'newest':
        result = [...result].sort((a, b) =>
          new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        )
        break
      case 'name':
        result = [...result].sort((a, b) => a.file_name.localeCompare(b.file_name))
        break
      case 'size':
        result = [...result].sort((a, b) => b.file_size - a.file_size)
        break
    }

    return result
  }, [assets, debouncedQuery, selectedTag, sortKey])

  // Pagination
  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))
  const paged = filtered.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE)

  // Reset page when filter changes
  useEffect(() => { setPage(0) }, [selectedTag, sortKey])

  async function handleDeleteConfirm() {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await deleteAsset(deleteTarget)
      setAssets((prev) => prev.filter((a) => a.id !== deleteTarget))
      setTotal((prev) => prev - 1)
    } catch {
      // handled
    } finally {
      setDeleting(false)
      setDeleteTarget(null)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">에셋 라이브러리</h1>
          <p className="text-sm text-gray-500 mt-1">
            {filtered.length === total
              ? `${total}개 파일`
              : `${filtered.length} / ${total}개 파일`}
          </p>
        </div>
      </div>

      {/* Upload */}
      <OpsImageUploader
        onUploadComplete={(asset) => {
          setAssets((prev) => [asset, ...prev])
          setTotal((prev) => prev + 1)
        }}
        maxSizeMb={10}
      />

      {/* Search + Filter + Sort + View Mode */}
      <div className="flex flex-wrap items-center gap-3">
        {/* Search bar */}
        <div className="relative flex-1 min-w-[200px] max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            className="w-full pl-9 pr-8 py-2 text-sm border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            placeholder="파일명 검색..."
            value={searchQuery}
            onChange={(e) => handleSearchChange(e.target.value)}
          />
          {searchQuery && (
            <button
              className="absolute right-2 top-1/2 -translate-y-1/2 p-0.5 text-gray-400 hover:text-gray-600"
              onClick={() => { setSearchQuery(''); setDebouncedQuery(''); setPage(0) }}
            >
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>

        {/* Sort */}
        <select
          className="text-sm border border-gray-300 rounded-lg px-3 py-2"
          value={sortKey}
          onChange={(e) => setSortKey(e.target.value as SortKey)}
        >
          <option value="newest">최신순</option>
          <option value="name">이름순</option>
          <option value="size">크기순</option>
        </select>

        {/* View mode toggle */}
        <div className="flex border border-gray-300 rounded-lg overflow-hidden">
          <button
            className={`p-2 ${viewMode === 'grid' ? 'bg-gray-100 text-gray-900' : 'bg-white text-gray-400 hover:text-gray-600'}`}
            onClick={() => setViewMode('grid')}
            title="그리드 보기"
          >
            <LayoutGrid className="w-4 h-4" />
          </button>
          <button
            className={`p-2 ${viewMode === 'list' ? 'bg-gray-100 text-gray-900' : 'bg-white text-gray-400 hover:text-gray-600'}`}
            onClick={() => setViewMode('list')}
            title="리스트 보기"
          >
            <List className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Tag filter chips */}
      {allTags.length > 0 && (
        <div className="flex flex-wrap gap-1.5">
          <button
            className={`text-xs px-2.5 py-1 rounded-full border transition-colors ${
              selectedTag === null
                ? 'bg-gray-900 text-white border-gray-900'
                : 'bg-white text-gray-600 border-gray-300 hover:border-gray-400'
            }`}
            onClick={() => setSelectedTag(null)}
          >
            전체
          </button>
          {allTags.map((tag) => (
            <button
              key={tag}
              className={`text-xs px-2.5 py-1 rounded-full border transition-colors ${
                selectedTag === tag
                  ? 'bg-gray-900 text-white border-gray-900'
                  : 'bg-white text-gray-600 border-gray-300 hover:border-gray-400'
              }`}
              onClick={() => setSelectedTag(selectedTag === tag ? null : tag)}
            >
              {tag}
            </button>
          ))}
        </div>
      )}

      {/* Content */}
      {loading ? (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="aspect-video bg-gray-100 rounded-lg animate-pulse" />
          ))}
        </div>
      ) : paged.length === 0 ? (
        <div className="text-center py-12 bg-white border border-gray-200 rounded-lg">
          <ImageIcon className="w-12 h-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">
            {debouncedQuery || selectedTag
              ? '검색 결과가 없습니다'
              : DEMO_MODE
                ? '데모 모드에서는 업로드된 에셋이 표시되지 않습니다'
                : '에셋을 업로드해주세요'}
          </p>
        </div>
      ) : viewMode === 'grid' ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {paged.map((asset) => (
            <AssetCard
              key={asset.id}
              asset={asset}
              onDelete={() => setDeleteTarget(asset.id)}
            />
          ))}
        </div>
      ) : (
        <div className="bg-white border border-gray-200 rounded-lg overflow-hidden">
          {paged.map((asset) => (
            <AssetRow
              key={asset.id}
              asset={asset}
              onDelete={() => setDeleteTarget(asset.id)}
            />
          ))}
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <span className="text-xs text-gray-500">
            {filtered.length}개 중 {page * PAGE_SIZE + 1}-
            {Math.min((page + 1) * PAGE_SIZE, filtered.length)}
          </span>
          <div className="flex items-center gap-1">
            <button
              className="p-1.5 rounded hover:bg-gray-200 disabled:opacity-30"
              disabled={page === 0}
              onClick={() => setPage(page - 1)}
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="text-xs text-gray-600 px-2">
              {page + 1} / {totalPages}
            </span>
            <button
              className="p-1.5 rounded hover:bg-gray-200 disabled:opacity-30"
              disabled={page >= totalPages - 1}
              onClick={() => setPage(page + 1)}
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Delete Confirm Modal */}
      <OpsConfirmModal
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDeleteConfirm}
        title="에셋 삭제"
        description="이 에셋을 삭제하시겠습니까? 삭제된 파일은 복구할 수 없습니다."
        variant="danger"
        confirmLabel="삭제"
        loading={deleting}
      />
    </div>
  )
}
