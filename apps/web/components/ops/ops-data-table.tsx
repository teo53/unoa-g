'use client'

import { useState, useMemo, useCallback, useRef } from 'react'
import { ChevronUp, ChevronDown, ChevronLeft, ChevronRight } from 'lucide-react'

interface Column<T> {
  key: string
  label: string
  sortable?: boolean
  render?: (item: T) => React.ReactNode
  className?: string
}

interface BulkAction {
  label: string
  variant?: 'default' | 'danger'
  onAction: (selectedIds: string[]) => void | Promise<void>
}

interface OpsDataTableProps<T> {
  data: T[]
  columns: Column<T>[]
  keyField?: string
  pageSize?: number
  emptyMessage?: string
  onRowClick?: (item: T) => void
  loading?: boolean
  /** Enable multi-select checkboxes */
  selectable?: boolean
  /** Bulk actions shown when items are selected */
  bulkActions?: BulkAction[]
}

export function OpsDataTable<T extends Record<string, unknown>>({
  data,
  columns,
  keyField = 'id',
  pageSize = 10,
  emptyMessage = '데이터가 없습니다.',
  onRowClick,
  loading = false,
  selectable = false,
  bulkActions = [],
}: OpsDataTableProps<T>) {
  const [sortKey, setSortKey] = useState<string | null>(null)
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc')
  const [page, setPage] = useState(0)
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const lastClickedIndexRef = useRef<number | null>(null)

  function handleSort(key: string) {
    if (sortKey === key) {
      setSortDir(sortDir === 'asc' ? 'desc' : 'asc')
    } else {
      setSortKey(key)
      setSortDir('asc')
    }
    setPage(0)
  }

  const sorted = useMemo(() => {
    if (!sortKey) return data
    return [...data].sort((a, b) => {
      const aVal = a[sortKey]
      const bVal = b[sortKey]
      if (aVal == null) return 1
      if (bVal == null) return -1
      if (typeof aVal === 'string' && typeof bVal === 'string') {
        return sortDir === 'asc'
          ? aVal.localeCompare(bVal)
          : bVal.localeCompare(aVal)
      }
      if (typeof aVal === 'number' && typeof bVal === 'number') {
        return sortDir === 'asc' ? aVal - bVal : bVal - aVal
      }
      return 0
    })
  }, [data, sortKey, sortDir])

  const totalPages = Math.max(1, Math.ceil(sorted.length / pageSize))
  const paged = sorted.slice(page * pageSize, (page + 1) * pageSize)

  // Selection helpers
  const allPageIds = paged.map((item) => String(item[keyField]))
  const allPageSelected = allPageIds.length > 0 && allPageIds.every((id) => selectedIds.has(id))
  const somePageSelected = allPageIds.some((id) => selectedIds.has(id))

  const toggleAll = useCallback(() => {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (allPageSelected) {
        allPageIds.forEach((id) => next.delete(id))
      } else {
        allPageIds.forEach((id) => next.add(id))
      }
      return next
    })
  }, [allPageIds, allPageSelected])

  const toggleOne = useCallback(
    (id: string, index: number, shiftKey: boolean) => {
      setSelectedIds((prev) => {
        const next = new Set(prev)

        // Shift+click range selection
        if (shiftKey && lastClickedIndexRef.current !== null) {
          const start = Math.min(lastClickedIndexRef.current, index)
          const end = Math.max(lastClickedIndexRef.current, index)
          for (let i = start; i <= end; i++) {
            const rowId = String(paged[i]?.[keyField])
            if (rowId) next.add(rowId)
          }
        } else {
          if (next.has(id)) {
            next.delete(id)
          } else {
            next.add(id)
          }
        }

        return next
      })
      lastClickedIndexRef.current = index
    },
    [paged, keyField]
  )

  const clearSelection = useCallback(() => {
    setSelectedIds(new Set())
    lastClickedIndexRef.current = null
  }, [])

  const selectedCount = selectedIds.size

  if (loading) {
    return (
      <div className="space-y-2">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="h-12 bg-gray-100 rounded animate-pulse" />
        ))}
      </div>
    )
  }

  return (
    <div className="bg-white border border-gray-200 rounded-lg overflow-hidden">
      {/* Bulk action bar */}
      {selectable && selectedCount > 0 && (
        <div className="flex items-center gap-3 px-4 py-2 bg-blue-50 border-b border-blue-200">
          <span className="text-sm text-blue-700 font-medium">
            {selectedCount}개 선택됨
          </span>
          <div className="flex items-center gap-2 ml-auto">
            {bulkActions.map((action) => (
              <button
                key={action.label}
                className={`px-3 py-1.5 text-xs font-medium rounded-lg ${
                  action.variant === 'danger'
                    ? 'bg-red-600 text-white hover:bg-red-700'
                    : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
                }`}
                onClick={() => action.onAction(Array.from(selectedIds))}
              >
                {action.label}
              </button>
            ))}
            <button
              className="px-3 py-1.5 text-xs text-gray-500 hover:text-gray-700"
              onClick={clearSelection}
            >
              선택 해제
            </button>
          </div>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              {selectable && (
                <th className="px-4 py-3 w-10">
                  <input
                    type="checkbox"
                    className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    checked={allPageSelected}
                    ref={(el) => {
                      if (el) el.indeterminate = somePageSelected && !allPageSelected
                    }}
                    onChange={toggleAll}
                  />
                </th>
              )}
              {columns.map((col) => (
                <th
                  key={col.key}
                  className={`px-4 py-3 text-left font-medium text-gray-600 ${
                    col.sortable ? 'cursor-pointer select-none hover:text-gray-900' : ''
                  } ${col.className || ''}`}
                  onClick={() => col.sortable && handleSort(col.key)}
                >
                  <div className="flex items-center gap-1">
                    {col.label}
                    {col.sortable && sortKey === col.key && (
                      sortDir === 'asc'
                        ? <ChevronUp className="w-3 h-3" />
                        : <ChevronDown className="w-3 h-3" />
                    )}
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {paged.length === 0 ? (
              <tr>
                <td
                  colSpan={columns.length + (selectable ? 1 : 0)}
                  className="px-4 py-8 text-center text-gray-500"
                >
                  {emptyMessage}
                </td>
              </tr>
            ) : (
              paged.map((item, idx) => {
                const rowId = String(item[keyField])
                const isSelected = selectedIds.has(rowId)

                return (
                  <tr
                    key={rowId}
                    className={`border-b border-gray-100 last:border-0 ${
                      isSelected ? 'bg-blue-50' : ''
                    } ${onRowClick ? 'cursor-pointer hover:bg-gray-50' : ''}`}
                    onClick={() => onRowClick?.(item)}
                  >
                    {selectable && (
                      <td className="px-4 py-3 w-10">
                        <input
                          type="checkbox"
                          className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                          checked={isSelected}
                          onChange={(e) => {
                            e.stopPropagation()
                            toggleOne(rowId, idx, e.nativeEvent instanceof MouseEvent && e.nativeEvent.shiftKey)
                          }}
                          onClick={(e) => e.stopPropagation()}
                        />
                      </td>
                    )}
                    {columns.map((col) => (
                      <td
                        key={col.key}
                        className={`px-4 py-3 ${col.className || ''}`}
                      >
                        {col.render
                          ? col.render(item)
                          : String(item[col.key] ?? '-')}
                      </td>
                    ))}
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200 bg-gray-50">
          <span className="text-xs text-gray-500">
            {sorted.length}개 중 {page * pageSize + 1}-
            {Math.min((page + 1) * pageSize, sorted.length)}
          </span>
          <div className="flex items-center gap-1">
            <button
              className="p-1 rounded hover:bg-gray-200 disabled:opacity-30"
              disabled={page === 0}
              onClick={() => setPage(page - 1)}
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="text-xs text-gray-600 px-2">
              {page + 1} / {totalPages}
            </span>
            <button
              className="p-1 rounded hover:bg-gray-200 disabled:opacity-30"
              disabled={page >= totalPages - 1}
              onClick={() => setPage(page + 1)}
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
