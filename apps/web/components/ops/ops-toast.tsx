'use client'

import { createContext, useContext, useCallback, useState, type ReactNode } from 'react'
import { X, CheckCircle, AlertTriangle, Info, XCircle } from 'lucide-react'

// ── Types ──

type ToastType = 'success' | 'error' | 'warning' | 'info'

interface ToastAction {
  label: string
  onClick: () => void
}

interface Toast {
  id: string
  type: ToastType
  title: string
  message?: string
  action?: ToastAction
  duration?: number
}

interface ToastContextType {
  toasts: Toast[]
  addToast: (toast: Omit<Toast, 'id'>) => void
  removeToast: (id: string) => void
  success: (title: string, message?: string) => void
  error: (title: string, message?: string) => void
  warning: (title: string, message?: string) => void
  info: (title: string, message?: string) => void
}

// ── Context ──

const ToastContext = createContext<ToastContextType | null>(null)

export function useToast(): ToastContextType {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error('useToast must be used within OpsToastProvider')
  return ctx
}

// ── Provider ──

const MAX_TOASTS = 3
const DEFAULT_DURATION = 3000

export function OpsToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  const addToast = useCallback(
    (toast: Omit<Toast, 'id'>) => {
      const id = `toast-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`
      const newToast: Toast = { ...toast, id }
      const duration = toast.duration ?? DEFAULT_DURATION

      setToasts((prev) => {
        const next = [...prev, newToast]
        // Keep max N toasts
        return next.length > MAX_TOASTS ? next.slice(-MAX_TOASTS) : next
      })

      // Auto-remove
      if (duration > 0) {
        setTimeout(() => removeToast(id), duration)
      }
    },
    [removeToast]
  )

  const success = useCallback(
    (title: string, message?: string) => addToast({ type: 'success', title, message }),
    [addToast]
  )
  const error = useCallback(
    (title: string, message?: string) => addToast({ type: 'error', title, message, duration: 5000 }),
    [addToast]
  )
  const warning = useCallback(
    (title: string, message?: string) => addToast({ type: 'warning', title, message }),
    [addToast]
  )
  const info = useCallback(
    (title: string, message?: string) => addToast({ type: 'info', title, message }),
    [addToast]
  )

  return (
    <ToastContext.Provider value={{ toasts, addToast, removeToast, success, error, warning, info }}>
      {children}
      <ToastContainer toasts={toasts} onRemove={removeToast} />
    </ToastContext.Provider>
  )
}

// ── Styling ──

const TOAST_STYLES: Record<ToastType, { icon: typeof CheckCircle; iconColor: string; border: string; bg: string }> = {
  success: {
    icon: CheckCircle,
    iconColor: 'text-green-500',
    border: 'border-green-200',
    bg: 'bg-green-50',
  },
  error: {
    icon: XCircle,
    iconColor: 'text-red-500',
    border: 'border-red-200',
    bg: 'bg-red-50',
  },
  warning: {
    icon: AlertTriangle,
    iconColor: 'text-yellow-500',
    border: 'border-yellow-200',
    bg: 'bg-yellow-50',
  },
  info: {
    icon: Info,
    iconColor: 'text-blue-500',
    border: 'border-blue-200',
    bg: 'bg-blue-50',
  },
}

// ── Toast Container (renders at top-right) ──

function ToastContainer({ toasts, onRemove }: { toasts: Toast[]; onRemove: (id: string) => void }) {
  if (toasts.length === 0) return null

  return (
    <div className="fixed top-4 right-4 z-[60] flex flex-col gap-2 max-w-sm w-full pointer-events-none">
      {toasts.map((toast) => (
        <ToastItem key={toast.id} toast={toast} onRemove={() => onRemove(toast.id)} />
      ))}
    </div>
  )
}

// ── Single Toast Item ──

function ToastItem({ toast, onRemove }: { toast: Toast; onRemove: () => void }) {
  const style = TOAST_STYLES[toast.type]
  const Icon = style.icon

  return (
    <div
      className={`
        pointer-events-auto flex items-start gap-3 p-4 rounded-lg border shadow-lg
        ${style.bg} ${style.border}
        animate-in slide-in-from-right duration-300
      `}
      role="alert"
    >
      <Icon className={`w-5 h-5 flex-shrink-0 mt-0.5 ${style.iconColor}`} />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-gray-900">{toast.title}</p>
        {toast.message && (
          <p className="text-xs text-gray-600 mt-0.5">{toast.message}</p>
        )}
        {toast.action && (
          <button
            className="text-xs font-medium text-blue-600 hover:text-blue-800 mt-1 underline"
            onClick={toast.action.onClick}
          >
            {toast.action.label}
          </button>
        )}
      </div>
      <button
        className="flex-shrink-0 p-0.5 text-gray-400 hover:text-gray-600 rounded"
        onClick={onRemove}
        aria-label="닫기"
      >
        <X className="w-4 h-4" />
      </button>
    </div>
  )
}
