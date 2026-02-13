'use client'

import { useEffect, useRef, useCallback, type ReactNode } from 'react'
import { X, AlertTriangle, CheckCircle, Trash2, RotateCcw } from 'lucide-react'

type ModalVariant = 'danger' | 'warning' | 'success' | 'info'

interface OpsConfirmModalProps {
  open: boolean
  onClose: () => void
  onConfirm: () => void | Promise<void>
  title: string
  description?: string
  children?: ReactNode
  variant?: ModalVariant
  confirmLabel?: string
  cancelLabel?: string
  /** If set, user must type this text to enable confirm */
  confirmText?: string
  loading?: boolean
}

const VARIANT_STYLES: Record<ModalVariant, { icon: typeof AlertTriangle; iconColor: string; btnColor: string }> = {
  danger: {
    icon: Trash2,
    iconColor: 'text-red-600 bg-red-100',
    btnColor: 'bg-red-600 hover:bg-red-700 focus-visible:ring-red-500',
  },
  warning: {
    icon: RotateCcw,
    iconColor: 'text-orange-600 bg-orange-100',
    btnColor: 'bg-orange-600 hover:bg-orange-700 focus-visible:ring-orange-500',
  },
  success: {
    icon: CheckCircle,
    iconColor: 'text-green-600 bg-green-100',
    btnColor: 'bg-green-600 hover:bg-green-700 focus-visible:ring-green-500',
  },
  info: {
    icon: AlertTriangle,
    iconColor: 'text-blue-600 bg-blue-100',
    btnColor: 'bg-blue-600 hover:bg-blue-700 focus-visible:ring-blue-500',
  },
}

export function OpsConfirmModal({
  open,
  onClose,
  onConfirm,
  title,
  description,
  children,
  variant = 'info',
  confirmLabel = '확인',
  cancelLabel = '취소',
  confirmText,
  loading = false,
}: OpsConfirmModalProps) {
  const overlayRef = useRef<HTMLDivElement>(null)
  const confirmBtnRef = useRef<HTMLButtonElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  // Track typed confirmation text
  const typedTextRef = useRef('')

  // Focus trap
  useEffect(() => {
    if (!open) return

    // Focus the input if confirmation text is required, otherwise focus confirm button
    const timer = setTimeout(() => {
      if (confirmText && inputRef.current) {
        inputRef.current.focus()
      } else if (confirmBtnRef.current) {
        confirmBtnRef.current.focus()
      }
    }, 50)

    return () => clearTimeout(timer)
  }, [open, confirmText])

  // ESC to close
  useEffect(() => {
    if (!open) return
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        onClose()
      }
    }
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [open, onClose])

  // Prevent body scroll when modal is open
  useEffect(() => {
    if (!open) return
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => { document.body.style.overflow = prev }
  }, [open])

  const handleOverlayClick = useCallback(
    (e: React.MouseEvent) => {
      if (e.target === overlayRef.current) {
        onClose()
      }
    },
    [onClose]
  )

  if (!open) return null

  const style = VARIANT_STYLES[variant]
  const Icon = style.icon

  // Check if confirm button should be disabled (needs typed confirmation)
  const needsTypedConfirmation = !!confirmText

  return (
    <div
      ref={overlayRef}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm animate-in fade-in duration-200"
      onClick={handleOverlayClick}
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
    >
      <div className="bg-white rounded-xl shadow-xl max-w-md w-full mx-4 animate-in zoom-in-95 duration-200">
        {/* Header */}
        <div className="flex items-start gap-4 p-6 pb-4">
          <div className={`flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${style.iconColor}`}>
            <Icon className="w-5 h-5" />
          </div>
          <div className="flex-1 min-w-0">
            <h3 id="modal-title" className="text-lg font-semibold text-gray-900">
              {title}
            </h3>
            {description && (
              <p className="mt-1 text-sm text-gray-500">{description}</p>
            )}
          </div>
          <button
            className="flex-shrink-0 p-1 text-gray-400 hover:text-gray-600 rounded-lg hover:bg-gray-100"
            onClick={onClose}
            aria-label="닫기"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        {children && (
          <div className="px-6 pb-4">
            {children}
          </div>
        )}

        {/* Typed confirmation */}
        {needsTypedConfirmation && (
          <div className="px-6 pb-4">
            <label className="block text-sm text-gray-600 mb-2">
              계속하려면 <span className="font-mono font-bold text-gray-900">{confirmText}</span>을(를) 입력하세요
            </label>
            <input
              ref={inputRef}
              type="text"
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder={confirmText}
              onChange={(e) => { typedTextRef.current = e.target.value }}
              autoComplete="off"
              spellCheck={false}
            />
          </div>
        )}

        {/* Actions */}
        <div className="flex items-center justify-end gap-3 px-6 py-4 bg-gray-50 rounded-b-xl">
          <button
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus-visible:ring-2 focus-visible:ring-gray-500 disabled:opacity-50"
            onClick={onClose}
            disabled={loading}
          >
            {cancelLabel}
          </button>
          <button
            ref={confirmBtnRef}
            className={`px-4 py-2 text-sm font-medium text-white rounded-lg focus-visible:ring-2 focus-visible:ring-offset-2 disabled:opacity-50 ${style.btnColor}`}
            onClick={async () => {
              if (needsTypedConfirmation && typedTextRef.current !== confirmText) {
                return // Don't proceed if text doesn't match
              }
              await onConfirm()
            }}
            disabled={loading}
          >
            {loading ? (
              <span className="flex items-center gap-2">
                <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                처리 중...
              </span>
            ) : (
              confirmLabel
            )}
          </button>
        </div>
      </div>
    </div>
  )
}
