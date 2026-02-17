'use client'

import { cn } from '@/lib/utils/cn'

interface ErrorDisplayProps {
  title?: string
  message?: string
  errorCode?: string
  onRetry?: () => void
  compact?: boolean
  className?: string
}

/**
 * ErrorDisplay
 *
 * Flutter ErrorDisplay 미러링.
 * 에러 표시 + 재시도 버튼 + 에러 코드 (고객지원용).
 */
export function ErrorDisplay({
  title = '오류가 발생했습니다',
  message = '잠시 후 다시 시도해 주세요.',
  errorCode,
  onRetry,
  compact = false,
  className,
}: ErrorDisplayProps) {
  if (compact) {
    return (
      <div className={cn('flex items-center gap-3 rounded-lg border border-semantic-danger/20 bg-semantic-danger-light p-3', className)}>
        <svg className="h-5 w-5 shrink-0 text-semantic-danger" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
        </svg>
        <p className="text-sm text-neutral-700">{message}</p>
        {onRetry && (
          <button
            onClick={onRetry}
            className="ml-auto shrink-0 text-sm font-medium text-semantic-danger hover:underline"
          >
            재시도
          </button>
        )}
      </div>
    )
  }

  return (
    <div className={cn('flex flex-col items-center justify-center py-16 px-4', className)}>
      <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-semantic-danger-light">
        <svg className="h-8 w-8 text-semantic-danger" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126z" />
        </svg>
      </div>

      <h3 className="mb-2 text-lg font-semibold text-neutral-900">{title}</h3>
      <p className="mb-6 max-w-sm text-center text-sm text-neutral-500">{message}</p>

      {onRetry && (
        <button
          onClick={onRetry}
          className="rounded-lg bg-primary-600 px-6 py-2.5 text-sm font-medium text-white transition-colors hover:bg-primary-700 active:bg-primary-800"
        >
          다시 시도
        </button>
      )}

      {errorCode && (
        <p className="mt-4 text-xs text-neutral-400">
          에러 코드: {errorCode}
        </p>
      )}
    </div>
  )
}
