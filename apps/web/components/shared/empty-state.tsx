import { cn } from '@/lib/utils/cn'

type EmptyStatePreset = 'noData' | 'noSearch' | 'noCampaigns' | 'noSettlements' | 'noActivity'

interface EmptyStateProps {
  preset?: EmptyStatePreset
  title?: string
  message?: string
  icon?: React.ReactNode
  action?: {
    label: string
    onClick: () => void
  }
  className?: string
}

const presets: Record<EmptyStatePreset, { title: string; message: string; icon: React.ReactNode }> = {
  noData: {
    title: '데이터가 없습니다',
    message: '아직 등록된 항목이 없습니다.',
    icon: <InboxIcon />,
  },
  noSearch: {
    title: '검색 결과가 없습니다',
    message: '다른 검색어로 시도해 보세요.',
    icon: <SearchIcon />,
  },
  noCampaigns: {
    title: '진행 중인 캠페인이 없습니다',
    message: '새로운 캠페인을 시작해 보세요.',
    icon: <RocketIcon />,
  },
  noSettlements: {
    title: '정산 내역이 없습니다',
    message: '아직 정산 요청이 없습니다.',
    icon: <WalletIcon />,
  },
  noActivity: {
    title: '활동 내역이 없습니다',
    message: '아직 기록된 활동이 없습니다.',
    icon: <ClockIcon />,
  },
}

/**
 * EmptyState
 *
 * Flutter EmptyState 미러링.
 * 빈 상태 아이콘 + 메시지 + 액션 버튼.
 */
export function EmptyState({
  preset,
  title,
  message,
  icon,
  action,
  className,
}: EmptyStateProps) {
  const p = preset ? presets[preset] : null

  const displayTitle = title || p?.title || '데이터가 없습니다'
  const displayMessage = message || p?.message || ''
  const displayIcon = icon || p?.icon || <InboxIcon />

  return (
    <div className={cn('flex flex-col items-center justify-center py-16 px-4', className)}>
      <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-neutral-100 text-neutral-400">
        {displayIcon}
      </div>

      <h3 className="mb-1 text-base font-semibold text-neutral-700">{displayTitle}</h3>
      {displayMessage && (
        <p className="mb-6 max-w-sm text-center text-sm text-neutral-500">{displayMessage}</p>
      )}

      {action && (
        <button
          onClick={action.onClick}
          className="rounded-lg bg-primary-600 px-5 py-2 text-sm font-medium text-white transition-colors hover:bg-primary-700"
        >
          {action.label}
        </button>
      )}
    </div>
  )
}

// ============================================================
// Icons (inline SVG — no external dependency)
// ============================================================
function InboxIcon() {
  return (
    <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 13.5h3.86a2.25 2.25 0 012.012 1.244l.256.512a2.25 2.25 0 002.013 1.244h3.218a2.25 2.25 0 002.013-1.244l.256-.512a2.25 2.25 0 012.013-1.244h3.859m-17.5 0V6a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121.75 6v7.5m-17.5 0v4.5A2.25 2.25 0 006.5 20.25h11a2.25 2.25 0 002.25-2.25V13.5" />
    </svg>
  )
}

function SearchIcon() {
  return (
    <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
    </svg>
  )
}

function RocketIcon() {
  return (
    <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M15.59 14.37a6 6 0 01-5.84 7.38v-4.8m5.84-2.58a14.98 14.98 0 006.16-12.12A14.98 14.98 0 009.63 8.41m5.96 5.96a14.926 14.926 0 01-5.841 2.58m-.119-8.54a6 6 0 00-7.381 5.84h4.8m2.581-5.84a14.927 14.927 0 00-2.58 5.84m2.699 2.7c-.103.021-.207.041-.311.06a15.09 15.09 0 01-2.448-2.448 14.9 14.9 0 01.06-.312m-2.24 2.39a4.493 4.493 0 00-1.757 4.306 4.493 4.493 0 004.306-1.758M16.5 9a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0z" />
    </svg>
  )
}

function WalletIcon() {
  return (
    <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M21 12a2.25 2.25 0 00-2.25-2.25H15a3 3 0 11-6 0H5.25A2.25 2.25 0 003 12m18 0v6a2.25 2.25 0 01-2.25 2.25H5.25A2.25 2.25 0 013 18v-6m18 0V9M3 12V9m18 0a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 9m18 0V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v3" />
    </svg>
  )
}

function ClockIcon() {
  return (
    <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
  )
}
