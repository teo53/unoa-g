'use client'

import { useState, useMemo } from 'react'
import { CampaignCard } from '@/components/campaign/campaign-card'
import { EmptyState } from '@/components/shared/empty-state'
import { PageLayout } from '@/components/shared/page-layout'
import { DEMO_MODE, mockCampaigns } from '@/lib/mock/demo-data'
import { cn } from '@/lib/utils/cn'
import { formatFundingAmount } from '@/lib/utils/format'

type SortType = 'latest' | 'popular' | 'ending-soon' | 'progress'
type CategoryType = 'all' | 'K-POP' | 'concert' | 'goods' | 'photobook' | 'fanmeeting'

const sortOptions: { key: SortType; label: string }[] = [
  { key: 'latest', label: '최신순' },
  { key: 'popular', label: '인기순' },
  { key: 'ending-soon', label: '마감임박' },
  { key: 'progress', label: '달성률순' },
]

const categories: { key: CategoryType; label: string }[] = [
  { key: 'all', label: '전체' },
  { key: 'K-POP', label: 'K-POP' },
  { key: 'concert', label: '콘서트' },
  { key: 'goods', label: '굿즈' },
  { key: 'photobook', label: '포토북' },
  { key: 'fanmeeting', label: '팬미팅' },
]

const statusFilters = [
  { key: 'active', label: '진행중' },
  { key: 'completed', label: '마감' },
  { key: 'all', label: '전체' },
] as const

type StatusFilter = typeof statusFilters[number]['key']

export default function FundingContent() {
  const [search, setSearch] = useState('')
  const [category, setCategory] = useState<CategoryType>('all')
  const [sort, setSort] = useState<SortType>('latest')
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('active')

  const allCampaigns = DEMO_MODE ? mockCampaigns : []

  const filteredCampaigns = useMemo(() => {
    let result = [...allCampaigns]

    // Status filter
    if (statusFilter !== 'all') {
      result = result.filter(c => c.status === statusFilter)
    }

    // Search
    if (search.trim()) {
      const q = search.trim().toLowerCase()
      result = result.filter(c =>
        c.title.toLowerCase().includes(q) ||
        c.subtitle?.toLowerCase().includes(q) ||
        c.creator?.display_name?.toLowerCase().includes(q)
      )
    }

    // Category
    if (category !== 'all') {
      result = result.filter(c =>
        c.category?.toLowerCase() === category.toLowerCase()
      )
    }

    // Sort
    switch (sort) {
      case 'popular':
        result.sort((a, b) => b.backer_count - a.backer_count)
        break
      case 'ending-soon':
        result = result.filter(c => c.end_at)
        result.sort((a, b) => new Date(a.end_at!).getTime() - new Date(b.end_at!).getTime())
        break
      case 'progress':
        result.sort((a, b) => {
          const pA = a.goal_amount_dt > 0 ? a.current_amount_dt / a.goal_amount_dt : 0
          const pB = b.goal_amount_dt > 0 ? b.current_amount_dt / b.goal_amount_dt : 0
          return pB - pA
        })
        break
      case 'latest':
      default:
        result.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    }

    return result
  }, [allCampaigns, search, category, sort, statusFilter])

  // Summary stats
  const totalFunding = allCampaigns.reduce((sum, c) => sum + c.current_amount_dt, 0)
  const activeCampaigns = allCampaigns.filter(c => c.status === 'active').length

  return (
    <PageLayout variant="public" maxWidth="wide">
      {/* Page Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-neutral-900 sm:text-3xl">펀딩 둘러보기</h1>
        <p className="mt-2 text-neutral-500">다양한 크리에이터들의 프로젝트를 만나보세요</p>

        {/* Quick Stats */}
        <div className="mt-4 flex gap-6 text-sm">
          <div>
            <span className="text-neutral-400">진행중 </span>
            <span className="font-semibold text-brand-500">{activeCampaigns}개</span>
          </div>
          <div>
            <span className="text-neutral-400">총 펀딩액 </span>
            <span className="font-semibold text-neutral-900">{formatFundingAmount(totalFunding)}</span>
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="mb-6">
        <div className="relative max-w-md">
          <svg className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-neutral-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input
            type="text"
            placeholder="캠페인 또는 크리에이터 검색..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-xl border border-neutral-200 bg-neutral-50 py-2.5 pl-10 pr-4 text-sm text-neutral-900 placeholder:text-neutral-400 transition-colors focus:border-brand-500 focus:bg-white focus:outline-none focus:ring-1 focus:ring-brand-500/20"
          />
          {search && (
            <button
              onClick={() => setSearch('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-neutral-600"
            >
              <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>
      </div>

      {/* Filters Row */}
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        {/* Status + Category */}
        <div className="flex flex-wrap gap-2">
          {/* Status Pills */}
          {statusFilters.map((f) => (
            <button
              key={f.key}
              onClick={() => setStatusFilter(f.key)}
              className={cn(
                'rounded-full px-3.5 py-1.5 text-xs font-medium transition-colors',
                statusFilter === f.key
                  ? 'bg-neutral-900 text-white'
                  : 'bg-neutral-100 text-neutral-600 hover:bg-neutral-200'
              )}
            >
              {f.label}
            </button>
          ))}

          <div className="mx-1 h-6 w-px bg-neutral-200 self-center" />

          {/* Category Pills */}
          {categories.map((c) => (
            <button
              key={c.key}
              onClick={() => setCategory(c.key)}
              className={cn(
                'rounded-full px-3.5 py-1.5 text-xs font-medium transition-colors',
                category === c.key
                  ? 'bg-brand-500 text-white'
                  : 'bg-neutral-50 text-neutral-500 hover:bg-neutral-100'
              )}
            >
              {c.label}
            </button>
          ))}
        </div>

        {/* Sort */}
        <select
          value={sort}
          onChange={(e) => setSort(e.target.value as SortType)}
          className="self-start rounded-lg border border-neutral-200 bg-white px-3 py-1.5 text-xs text-neutral-600 focus:border-brand-500 focus:outline-none"
        >
          {sortOptions.map((s) => (
            <option key={s.key} value={s.key}>{s.label}</option>
          ))}
        </select>
      </div>

      {/* Results count */}
      <div className="mb-4 text-sm text-neutral-400">
        {filteredCampaigns.length > 0
          ? `${filteredCampaigns.length}개의 캠페인`
          : null
        }
      </div>

      {/* Campaign Grid */}
      {filteredCampaigns.length === 0 ? (
        search ? (
          <EmptyState
            preset="noSearch"
            message={`"${search}"에 대한 결과가 없습니다. 다른 검색어로 시도해 보세요.`}
            action={{ label: '검색 초기화', onClick: () => { setSearch(''); setCategory('all'); setStatusFilter('active') } }}
          />
        ) : (
          <EmptyState
            preset="noCampaigns"
            action={{ label: '전체 보기', onClick: () => { setCategory('all'); setStatusFilter('all') } }}
          />
        )
      ) : (
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {filteredCampaigns.map((campaign) => (
            <CampaignCard key={campaign.id} campaign={{
              ...campaign,
              creator: campaign.creator ? {
                id: campaign.creator.id,
                display_name: campaign.creator.display_name || '알 수 없음',
                avatar_url: campaign.creator.avatar_url,
              } : undefined,
            }} />
          ))}
        </div>
      )}
    </PageLayout>
  )
}
