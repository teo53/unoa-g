'use client'

import { useState, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Users, TrendingUp, TrendingDown, Search, ChevronDown, Eye, AlertTriangle, Ban } from 'lucide-react'
import { formatKRW } from '@/lib/utils/format'

type Category = 'VTuber' | 'K-POP' | 'Idol'
type ActivityLevel = 'high' | 'medium' | 'low'
type CreatorStatus = 'active' | 'inactive' | 'suspended'

interface Creator {
  id: string
  name: string
  category: Category
  avatar_seed: string
  basic_count: number
  standard_count: number
  vip_count: number
  total_subscribers: number
  monthly_revenue_krw: number
  messages_this_month: number
  activity_score: number
  activity_level: ActivityLevel
  status: CreatorStatus
  last_broadcast: string
  join_date: string
}

const mockCreators: Creator[] = [
  {
    id: 'creator-001',
    name: '하늘달',
    category: 'VTuber',
    avatar_seed: 'vtuber1',
    basic_count: 450,
    standard_count: 320,
    vip_count: 150,
    total_subscribers: 920,
    monthly_revenue_krw: 8_450_000,
    messages_this_month: 145,
    activity_score: 92,
    activity_level: 'high',
    status: 'active',
    last_broadcast: '2시간 전',
    join_date: '2025-08-15',
  },
  {
    id: 'creator-002',
    name: '별빛',
    category: 'K-POP',
    avatar_seed: 'vtuber2',
    basic_count: 780,
    standard_count: 560,
    vip_count: 280,
    total_subscribers: 1620,
    monthly_revenue_krw: 15_120_000,
    messages_this_month: 210,
    activity_score: 98,
    activity_level: 'high',
    status: 'active',
    last_broadcast: '1시간 전',
    join_date: '2025-06-20',
  },
  {
    id: 'creator-003',
    name: '민서',
    category: 'Idol',
    avatar_seed: 'vtuber3',
    basic_count: 220,
    standard_count: 180,
    vip_count: 90,
    total_subscribers: 490,
    monthly_revenue_krw: 4_560_000,
    messages_this_month: 68,
    activity_score: 54,
    activity_level: 'medium',
    status: 'active',
    last_broadcast: '5일 전',
    join_date: '2025-11-10',
  },
  {
    id: 'creator-004',
    name: '루나',
    category: 'VTuber',
    avatar_seed: 'vtuber4',
    basic_count: 120,
    standard_count: 85,
    vip_count: 40,
    total_subscribers: 245,
    monthly_revenue_krw: 2_280_000,
    messages_this_month: 12,
    activity_score: 28,
    activity_level: 'low',
    status: 'inactive',
    last_broadcast: '23일 전',
    join_date: '2025-09-05',
  },
]

const activityLevelLabels: Record<ActivityLevel, string> = {
  high: '높음',
  medium: '보통',
  low: '낮음',
}

const activityLevelColors: Record<ActivityLevel, string> = {
  high: 'bg-green-100 text-green-800',
  medium: 'bg-orange-100 text-orange-800',
  low: 'bg-red-100 text-red-800',
}

const statusLabels: Record<CreatorStatus, string> = {
  active: '활성',
  inactive: '비활성',
  suspended: '정지',
}

const statusColors: Record<CreatorStatus, string> = {
  active: 'bg-green-100 text-green-800',
  inactive: 'bg-gray-100 text-gray-800',
  suspended: 'bg-red-100 text-red-800',
}

type SortKey = 'revenue' | 'subscribers' | 'activity'

export default function CreatorsPage() {
  const router = useRouter()
  const [searchQuery, setSearchQuery] = useState('')
  const [sortBy, setSortBy] = useState<SortKey>('revenue')

  const filteredAndSortedCreators = useMemo(() => {
    let filtered = mockCreators.filter(creator =>
      creator.name.toLowerCase().includes(searchQuery.toLowerCase())
    )

    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'revenue':
          return b.monthly_revenue_krw - a.monthly_revenue_krw
        case 'subscribers':
          return b.total_subscribers - a.total_subscribers
        case 'activity':
          return b.activity_score - a.activity_score
        default:
          return 0
      }
    })

    return filtered
  }, [searchQuery, sortBy])

  const stats = {
    total: mockCreators.length,
    active: mockCreators.filter(c => c.status === 'active').length,
    inactive: mockCreators.filter(c => c.status === 'inactive').length,
    totalSubscribers: mockCreators.reduce((sum, c) => sum + c.total_subscribers, 0),
  }

  const getAvatarUrl = (seed: string) => {
    return `https://picsum.photos/seed/${seed}/200`
  }

  const handleViewDetail = (id: string) => {
    router.push(`/admin/creators/${id}`)
  }

  const handleSendWarning = (creator: Creator) => {
    if (window.confirm(`"${creator.name}"에게 경고를 발송하시겠습니까?`)) {
      alert(`${creator.name}에게 경고를 발송했습니다`)
    }
  }

  const handleSuspend = (creator: Creator) => {
    if (window.confirm(`"${creator.name}"의 계정을 정지하시겠습니까?`)) {
      alert(`${creator.name}의 계정을 정지했습니다`)
    }
  }

  return (
    <div className="max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">크리에이터 관리</h1>
        <p className="text-gray-500 mt-1">플랫폼 크리에이터 현황 및 관리</p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div className="text-sm text-blue-600 font-medium">총 크리에이터</div>
            <Users className="w-5 h-5 text-blue-500" />
          </div>
          <div className="text-2xl font-bold text-blue-900 mt-1">{stats.total}</div>
        </div>
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div className="text-sm text-green-600 font-medium">활성</div>
            <TrendingUp className="w-5 h-5 text-green-500" />
          </div>
          <div className="text-2xl font-bold text-green-900 mt-1">{stats.active}</div>
        </div>
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-600 font-medium">비활성</div>
            <TrendingDown className="w-5 h-5 text-gray-500" />
          </div>
          <div className="text-2xl font-bold text-gray-900 mt-1">{stats.inactive}</div>
        </div>
        <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div className="text-sm text-purple-600 font-medium">총 구독자</div>
            <Users className="w-5 h-5 text-purple-500" />
          </div>
          <div className="text-2xl font-bold text-purple-900 mt-1">{stats.totalSubscribers.toLocaleString()}</div>
        </div>
      </div>

      {/* Search and Sort */}
      <div className="bg-white border border-gray-200 rounded-lg p-4 mb-6">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="크리에이터 이름 검색..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="flex items-center gap-2">
            <label className="text-sm text-gray-600 whitespace-nowrap">정렬:</label>
            <div className="relative">
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as SortKey)}
                className="appearance-none pl-3 pr-10 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
              >
                <option value="revenue">수익순</option>
                <option value="subscribers">구독자순</option>
                <option value="activity">활동도순</option>
              </select>
              <ChevronDown className="absolute right-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none" />
            </div>
          </div>
        </div>
      </div>

      {/* Creators Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">프로필</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">카테고리</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">구독자 수</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">월 수익</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">활동도</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">마지막 브로드캐스트</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">상태</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">액션</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredAndSortedCreators.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-4 py-12 text-center text-gray-500">
                    검색 결과가 없습니다
                  </td>
                </tr>
              ) : (
                filteredAndSortedCreators.map(creator => (
                  <tr key={creator.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <img
                          src={getAvatarUrl(creator.avatar_seed)}
                          alt={creator.name}
                          className="w-10 h-10 rounded-full object-cover"
                        />
                        <div className="font-medium text-gray-900">{creator.name}</div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <Badge variant="outline" className="text-xs">
                        {creator.category}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">
                      <div className="group relative">
                        <div className="text-sm font-medium text-gray-900">
                          {creator.total_subscribers.toLocaleString()}
                        </div>
                        <div className="absolute left-0 top-full mt-1 hidden group-hover:block bg-gray-900 text-white text-xs rounded-lg px-3 py-2 whitespace-nowrap z-10">
                          <div>BASIC: {creator.basic_count}</div>
                          <div>STANDARD: {creator.standard_count}</div>
                          <div>VIP: {creator.vip_count}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="text-sm font-medium text-gray-900">
                        {formatKRW(creator.monthly_revenue_krw)}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${activityLevelColors[creator.activity_level]}`}>
                        {activityLevelLabels[creator.activity_level]}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-500">
                      {creator.last_broadcast}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${statusColors[creator.status]}`}>
                        {statusLabels[creator.status]}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleViewDetail(creator.id)}
                          className="h-8 px-2"
                          title="상세보기"
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleSendWarning(creator)}
                          className="h-8 px-2"
                          title="경고"
                        >
                          <AlertTriangle className="w-4 h-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleSuspend(creator)}
                          className="h-8 px-2 text-red-600 hover:text-red-700"
                          title="정지"
                        >
                          <Ban className="w-4 h-4" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
