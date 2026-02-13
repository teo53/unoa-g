'use client'

import { useState } from 'react'
import { Save, Send, Globe, RotateCcw, Archive } from 'lucide-react'
import type { BannerStatus, FlagStatus } from '@/lib/ops/ops-types'
import { OpsConfirmModal } from './ops-confirm-modal'

type ItemStatus = BannerStatus | FlagStatus

interface OpsPublishActionsProps {
  status: ItemStatus
  version: number
  hasPublishedSnapshot: boolean
  onSaveDraft: () => Promise<void>
  onSubmitReview?: () => Promise<void>
  onPublish: () => Promise<void>
  onRollback?: () => Promise<void>
  onArchive?: () => Promise<void>
  disabled?: boolean
  /** Item name for modal description */
  itemLabel?: string
}

type ModalConfig = {
  action: string
  title: string
  description: string
  variant: 'danger' | 'warning' | 'success' | 'info'
  confirmLabel: string
  fn: () => Promise<void>
}

export function OpsPublishActions({
  status,
  version,
  hasPublishedSnapshot,
  onSaveDraft,
  onSubmitReview,
  onPublish,
  onRollback,
  onArchive,
  disabled = false,
  itemLabel = '이 항목',
}: OpsPublishActionsProps) {
  const [loading, setLoading] = useState<string | null>(null)
  const [modalConfig, setModalConfig] = useState<ModalConfig | null>(null)

  async function handleAction(actionName: string, fn: () => Promise<void>) {
    setLoading(actionName)
    try {
      await fn()
    } finally {
      setLoading(null)
    }
  }

  async function handleConfirmAction() {
    if (!modalConfig) return
    setLoading(modalConfig.action)
    try {
      await modalConfig.fn()
    } finally {
      setLoading(null)
      setModalConfig(null)
    }
  }

  const isLoading = loading !== null

  return (
    <>
      <div className="flex flex-wrap items-center gap-2">
        {/* Save Draft */}
        {(status === 'draft' || status === 'in_review') && (
          <button
            className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
            disabled={disabled || isLoading}
            onClick={() => handleAction('save', onSaveDraft)}
          >
            {loading === 'save' ? (
              <span className="w-4 h-4 border-2 border-gray-400 border-t-transparent rounded-full animate-spin" />
            ) : (
              <Save className="w-4 h-4" />
            )}
            초안 저장
          </button>
        )}

        {/* Submit Review */}
        {status === 'draft' && onSubmitReview && (
          <button
            className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-yellow-700 bg-yellow-50 border border-yellow-200 rounded-lg hover:bg-yellow-100 disabled:opacity-50"
            disabled={disabled || isLoading}
            onClick={() => handleAction('submit', onSubmitReview)}
          >
            {loading === 'submit' ? (
              <span className="w-4 h-4 border-2 border-yellow-400 border-t-transparent rounded-full animate-spin" />
            ) : (
              <Send className="w-4 h-4" />
            )}
            검수 요청
          </button>
        )}

        {/* Publish */}
        {(status === 'draft' || status === 'in_review') && (
          <button
            className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-green-700 bg-green-50 border border-green-200 rounded-lg hover:bg-green-100 disabled:opacity-50"
            disabled={disabled || isLoading}
            onClick={() =>
              setModalConfig({
                action: 'publish',
                title: '게시 확인',
                description: `${itemLabel}이(가) 모든 사용자에게 표시됩니다.`,
                variant: 'success',
                confirmLabel: '게시',
                fn: onPublish,
              })
            }
          >
            {loading === 'publish' ? (
              <span className="w-4 h-4 border-2 border-green-400 border-t-transparent rounded-full animate-spin" />
            ) : (
              <Globe className="w-4 h-4" />
            )}
            게시
          </button>
        )}

        {/* Rollback */}
        {status === 'published' && hasPublishedSnapshot && onRollback && (
          <button
            className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-orange-700 bg-orange-50 border border-orange-200 rounded-lg hover:bg-orange-100 disabled:opacity-50"
            disabled={disabled || isLoading}
            onClick={() =>
              setModalConfig({
                action: 'rollback',
                title: '롤백 확인',
                description: `${itemLabel}을(를) 이전 상태로 되돌립니다. 게시가 해제됩니다.`,
                variant: 'warning',
                confirmLabel: '롤백',
                fn: onRollback,
              })
            }
          >
            {loading === 'rollback' ? (
              <span className="w-4 h-4 border-2 border-orange-400 border-t-transparent rounded-full animate-spin" />
            ) : (
              <RotateCcw className="w-4 h-4" />
            )}
            롤백
          </button>
        )}

        {/* Archive */}
        {status !== 'archived' && onArchive && (
          <button
            className="inline-flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-red-700 bg-red-50 border border-red-200 rounded-lg hover:bg-red-100 disabled:opacity-50"
            disabled={disabled || isLoading}
            onClick={() =>
              setModalConfig({
                action: 'archive',
                title: '보관 확인',
                description: `${itemLabel}을(를) 보관합니다. 사용자에게 더 이상 표시되지 않습니다.`,
                variant: 'danger',
                confirmLabel: '보관',
                fn: onArchive,
              })
            }
          >
            {loading === 'archive' ? (
              <span className="w-4 h-4 border-2 border-red-400 border-t-transparent rounded-full animate-spin" />
            ) : (
              <Archive className="w-4 h-4" />
            )}
            보관
          </button>
        )}

        {/* Version indicator */}
        <span className="text-xs text-gray-400 ml-2">v{version}</span>
      </div>

      {/* Confirmation Modal */}
      {modalConfig && (
        <OpsConfirmModal
          open={!!modalConfig}
          onClose={() => setModalConfig(null)}
          onConfirm={handleConfirmAction}
          title={modalConfig.title}
          description={modalConfig.description}
          variant={modalConfig.variant}
          confirmLabel={modalConfig.confirmLabel}
          loading={loading === modalConfig.action}
        />
      )}
    </>
  )
}
