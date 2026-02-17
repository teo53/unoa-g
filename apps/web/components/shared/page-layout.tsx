import { cn } from '@/lib/utils/cn'
import { SiteHeader } from './site-header'
import { SiteFooter } from './site-footer'
import { DemoBanner } from './demo-banner'

type LayoutVariant = 'public' | 'studio' | 'admin' | 'agency'

interface PageLayoutProps {
  children: React.ReactNode
  variant?: LayoutVariant
  maxWidth?: 'narrow' | 'content' | 'wide' | 'full'
  showHeader?: boolean
  showFooter?: boolean
  showDemoBanner?: boolean
  className?: string
  contentClassName?: string
}

const maxWidthClasses = {
  narrow: 'max-w-narrow',
  content: 'max-w-content',
  wide: 'max-w-wide',
  full: 'max-w-full',
}

/**
 * PageLayout
 *
 * SiteHeader + children + SiteFooter 통합 레이아웃.
 * 모든 페이지에서 일관된 구조 보장.
 */
export function PageLayout({
  children,
  variant = 'public',
  maxWidth = 'content',
  showHeader = true,
  showFooter = true,
  showDemoBanner = true,
  className,
  contentClassName,
}: PageLayoutProps) {
  return (
    <div className={cn('flex min-h-screen flex-col bg-white', className)}>
      {showDemoBanner && <DemoBanner />}
      {showHeader && <SiteHeader variant={variant} />}

      <main className={cn('mx-auto w-full flex-1 px-4 py-6', maxWidthClasses[maxWidth], contentClassName)}>
        {children}
      </main>

      {showFooter && <SiteFooter />}
    </div>
  )
}
