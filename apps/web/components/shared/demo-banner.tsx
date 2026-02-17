import { cn } from '@/lib/utils/cn'
import { appConfig } from '@/lib/config'

interface DemoBannerProps {
  className?: string
}

/**
 * DemoBanner
 *
 * 데모 모드일 때 상단에 표시하는 배너.
 * appConfig.isDemoMode 자동 체크.
 */
export function DemoBanner({ className }: DemoBannerProps) {
  if (!appConfig.isDemoMode) return null

  return (
    <div className={cn(
      'bg-semantic-warning-light border-b border-semantic-warning/20 px-4 py-2 text-center text-sm text-semantic-warning',
      className
    )}>
      <span className="font-medium">데모 모드</span>
      <span className="ml-1 text-neutral-600">— 실제 데이터가 아닌 샘플 데이터로 운영됩니다</span>
    </div>
  )
}
