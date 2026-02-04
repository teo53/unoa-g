'use client'

import { useState } from 'react'
import Link from 'next/link'
import { CampaignCard } from '@/components/campaign/campaign-card'
import { DEMO_MODE, mockCampaigns } from '@/lib/mock/demo-data'

type FilterType = 'active' | 'popular' | 'ending-soon' | 'completed'

interface Campaign {
  id: string
  slug: string
  title: string
  subtitle?: string | null
  cover_image_url?: string | null
  category?: string | null
  status: string
  goal_amount_dt: number
  current_amount_dt: number
  backer_count: number
  start_at?: string | null
  end_at?: string | null
  created_at: string
  creator?: {
    id: string
    display_name: string
    avatar_url?: string | null
  } | null
}

function filterCampaigns(campaigns: Campaign[], filter: FilterType): Campaign[] {
  switch (filter) {
    case 'active':
      return campaigns.filter(c => c.status === 'active')
    case 'popular':
      return campaigns.filter(c => c.status === 'active')
        .sort((a, b) => b.backer_count - a.backer_count)
    case 'ending-soon':
      return campaigns.filter(c => c.status === 'active' && c.end_at)
        .sort((a, b) => new Date(a.end_at!).getTime() - new Date(b.end_at!).getTime())
    case 'completed':
      return campaigns.filter(c => c.status === 'completed')
    default:
      return campaigns
  }
}

function CampaignGrid({ campaigns }: { campaigns: Campaign[] }) {
  if (campaigns.length === 0) {
    return (
      <div className="text-center py-20">
        <p className="text-gray-500">아직 진행 중인 펀딩이 없습니다.</p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {campaigns.map((campaign) => (
        <CampaignCard key={campaign.id} campaign={campaign} />
      ))}
    </div>
  )
}

export default function FundingContent() {
  const [filter, setFilter] = useState<FilterType>('active')

  // In demo mode, use mock data. In production, this would be fetched from server
  const allCampaigns = DEMO_MODE ? mockCampaigns : []
  const campaigns = filterCampaigns(allCampaigns as Campaign[], filter)

  const filters: { key: FilterType; label: string }[] = [
    { key: 'active', label: '진행중' },
    { key: 'popular', label: '인기' },
    { key: 'ending-soon', label: '마감임박' },
    { key: 'completed', label: '마감' },
  ]

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="bg-amber-50 border-b border-amber-200 px-4 py-2 text-center text-sm text-amber-800">
          🎭 Demo Mode - Mock data is displayed
        </div>
      )}

      {/* Header */}
      <header className="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary-500">
            UNO A
          </Link>
          <nav className="flex items-center gap-4">
            <Link
              href="/studio"
              className="px-4 py-2 bg-primary-500 text-white rounded-full hover:bg-primary-600 transition-colors text-sm"
            >
              크리에이터 스튜디오
            </Link>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-8">
        {/* Page Title */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">펀딩 둘러보기</h1>
          <p className="text-gray-500 mt-2">다양한 크리에이터들의 프로젝트를 만나보세요</p>
        </div>

        {/* Filters */}
        <div className="flex gap-2 mb-8 overflow-x-auto pb-2">
          {filters.map((f) => (
            <button
              key={f.key}
              onClick={() => setFilter(f.key)}
              className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
                filter === f.key
                  ? 'bg-primary-500 text-white'
                  : 'bg-white text-gray-600 hover:bg-gray-100'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        {/* Campaign Grid */}
        <CampaignGrid campaigns={campaigns} />
      </main>
    </div>
  )
}
