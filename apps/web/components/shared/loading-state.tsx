import { cn } from '@/lib/utils/cn'

interface LoadingStateProps {
  message?: string
  compact?: boolean
  className?: string
}

/**
 * LoadingState
 *
 * Flutter LoadingState 미러링.
 * 로딩 스피너 + 메시지.
 */
export function LoadingState({
  message = '로딩 중...',
  compact = false,
  className,
}: LoadingStateProps) {
  if (compact) {
    return (
      <div className={cn('flex items-center justify-center gap-2 py-4', className)}>
        <LoadingSpinner size="sm" />
        <span className="text-sm text-neutral-500">{message}</span>
      </div>
    )
  }

  return (
    <div className={cn('flex flex-col items-center justify-center py-16', className)}>
      <LoadingSpinner size="lg" />
      <p className="mt-4 text-sm text-neutral-500">{message}</p>
    </div>
  )
}

/**
 * LoadingSpinner
 */
function LoadingSpinner({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) {
  const sizeClasses = {
    sm: 'h-4 w-4 border-2',
    md: 'h-8 w-8 border-2',
    lg: 'h-10 w-10 border-3',
  }

  return (
    <div
      className={cn(
        'animate-spin rounded-full border-primary-200 border-t-primary-600',
        sizeClasses[size]
      )}
    />
  )
}

/**
 * SkeletonBox
 *
 * 스켈레톤 로딩 블록.
 */
export function SkeletonBox({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('animate-pulse rounded-md bg-neutral-200', className)}
      {...props}
    />
  )
}

/**
 * SkeletonCard
 *
 * 카드형 스켈레톤 프리셋.
 */
export function SkeletonCard({ className }: { className?: string }) {
  return (
    <div className={cn('overflow-hidden rounded-xl border border-neutral-200 bg-white', className)}>
      <SkeletonBox className="h-48 w-full rounded-none" />
      <div className="p-4 space-y-3">
        <SkeletonBox className="h-4 w-3/4" />
        <SkeletonBox className="h-3 w-1/2" />
        <SkeletonBox className="h-2 w-full rounded-full" />
        <div className="flex justify-between pt-1">
          <SkeletonBox className="h-3 w-20" />
          <SkeletonBox className="h-3 w-16" />
        </div>
      </div>
    </div>
  )
}

/**
 * SkeletonList
 *
 * 리스트 스켈레톤 프리셋.
 */
export function SkeletonList({ count = 3, className }: { count?: number; className?: string }) {
  return (
    <div className={cn('space-y-4', className)}>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="flex items-center gap-3">
          <SkeletonBox className="h-10 w-10 shrink-0 rounded-full" />
          <div className="flex-1 space-y-2">
            <SkeletonBox className="h-4 w-3/4" />
            <SkeletonBox className="h-3 w-1/2" />
          </div>
        </div>
      ))}
    </div>
  )
}
