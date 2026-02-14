'use client'

import { useState, useMemo } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  ArrowLeft,
  Users,
  MessageSquare,
  Activity,
  Calendar,
  AlertTriangle,
  Ban,
  CheckCircle,
  DollarSign,
} from 'lucide-react'
import { formatKRW, formatDate, formatDateTime } from '@/lib/utils/format'

type Category = 'VTuber' | 'K-POP' | 'Idol'
type ActivityLevel = 'high' | 'medium' | 'low'
type CreatorStatus = 'active' | 'inactive' | 'suspended'
type MessageType = 'broadcast' | 'reply' | 'donation'
type MessageSender = 'creator' | 'fan'

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
  last_access: string
}

interface ChatMessage {
  id: string
  timestamp: string
  sender: MessageSender
  sender_name: string
  message: string
  type: MessageType
}

interface RevenueHistory {
  month: string
  subscription: number
  dt: number
  funding: number
  total: number
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
    last_access: '2026-02-13T08:30:00Z',
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
    last_access: '2026-02-13T09:15:00Z',
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
    last_access: '2026-02-08T14:20:00Z',
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
    last_access: '2026-01-21T10:45:00Z',
  },
]

const mockChatMessages: Record<string, ChatMessage[]> = {
  'creator-001': [
    { id: 'msg-001', timestamp: '2026-02-13T08:20:00Z', sender: 'creator', sender_name: '하늘달', message: '오늘 라이브 방송 시작합니다! 많이 와주세요~', type: 'broadcast' },
    { id: 'msg-002', timestamp: '2026-02-13T08:22:00Z', sender: 'fan', sender_name: '팬A', message: '기다렸어요! 바로 갑니다', type: 'reply' },
    { id: 'msg-003', timestamp: '2026-02-13T08:25:00Z', sender: 'fan', sender_name: '팬B', message: '응원합니다 ❤️', type: 'donation' },
    { id: 'msg-004', timestamp: '2026-02-13T08:30:00Z', sender: 'creator', sender_name: '하늘달', message: '감사합니다! 열심히 할게요', type: 'reply' },
    { id: 'msg-005', timestamp: '2026-02-13T07:15:00Z', sender: 'creator', sender_name: '하늘달', message: '새로운 캐릭터 디자인 공개합니다!', type: 'broadcast' },
  ],
  'creator-002': [
    { id: 'msg-101', timestamp: '2026-02-13T09:10:00Z', sender: 'creator', sender_name: '별빛', message: '신곡 발매 기념 팬미팅 일정 공지!', type: 'broadcast' },
    { id: 'msg-102', timestamp: '2026-02-13T09:12:00Z', sender: 'fan', sender_name: '팬C', message: '꼭 갈게요!', type: 'reply' },
    { id: 'msg-103', timestamp: '2026-02-13T09:15:00Z', sender: 'fan', sender_name: '팬D', message: '신곡 너무 좋아요 ㅠㅠ', type: 'donation' },
  ],
}

const mockRevenueHistory: Record<string, RevenueHistory[]> = {
  'creator-001': [
    { month: '2026-02', subscription: 4_500_000, dt: 1_200_000, funding: 2_750_000, total: 8_450_000 },
    { month: '2026-01', subscription: 4_100_000, dt: 980_000, funding: 2_120_000, total: 7_200_000 },
    { month: '2025-12', subscription: 3_800_000, dt: 850_000, funding: 1_950_000, total: 6_600_000 },
    { month: '2025-11', subscription: 3_600_000, dt: 720_000, funding: 1_680_000, total: 6_000_000 },
    { month: '2025-10', subscription: 3_400_000, dt: 680_000, funding: 1_420_000, total: 5_500_000 },
    { month: '2025-09', subscription: 3_200_000, dt: 600_000, funding: 1_200_000, total: 5_000_000 },
  ],
  'creator-002': [
    { month: '2026-02', subscription: 8_000_000, dt: 3_500_000, funding: 3_620_000, total: 15_120_000 },
    { month: '2026-01', subscription: 7_500_000, dt: 3_200_000, funding: 3_100_000, total: 13_800_000 },
    { month: '2025-12', subscription: 7_200_000, dt: 2_900_000, funding: 2_800_000, total: 12_900_000 },
    { month: '2025-11', subscription: 6_800_000, dt: 2_600_000, funding: 2_500_000, total: 11_900_000 },
    { month: '2025-10', subscription: 6_500_000, dt: 2_400_000, funding: 2_300_000, total: 11_200_000 },
    { month: '2025-09', subscription: 6_200_000, dt: 2_200_000, funding: 2_100_000, total: 10_500_000 },
  ],
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

const messageTypeLabels: Record<MessageType, string> = {
  broadcast: '브로드캐스트',
  reply: '답글',
  donation: '후원메시지',
}

const messageTypeColors: Record<MessageType, string> = {
  broadcast: 'bg-blue-100 text-blue-800',
  reply: 'bg-gray-100 text-gray-800',
  donation: 'bg-yellow-100 text-yellow-800',
}

export default function CreatorDetailClient({ id }: { id: string }) {
  const router = useRouter()
  const [adminNote, setAdminNote] = useState('')

  const creator = useMemo(() => {
    return mockCreators.find(c => c.id === id)
  }, [id])

  const chatMessages = useMemo(() => {
    return mockChatMessages[id] || []
  }, [id])

  const revenueHistory = useMemo(() => {
    return mockRevenueHistory[id] || []
  }, [id])

  if (!creator) {
    return (
      <div className="max-w-7xl mx-auto">
        <div className="text-center py-12">
          <p className="text-gray-500">크리에이터를 찾을 수 없습니다</p>
          <Button onClick={() => router.push('/admin/creators')} className="mt-4">
            목록으로 돌아가기
          </Button>
        </div>
      </div>
    )
  }

  const getAvatarUrl = (seed: string) => {
    return `https://picsum.photos/seed/${seed}/200`
  }

  const handleSendWarning = () => {
    if (window.confirm(`"${creator.name}"에게 경고를 발송하시겠습니까?`)) {
      alert(`${creator.name}에게 경고를 발송했습니다`)
    }
  }

  const handleToggleSuspension = () => {
    if (creator.status === 'suspended') {
      if (window.confirm(`"${creator.name}"의 정지를 해제하시겠습니까?`)) {
        alert(`${creator.name}의 정지를 해제했습니다`)
      }
    } else {
      if (window.confirm(`"${creator.name}"의 계정을 정지하시겠습니까?`)) {
        alert(`${creator.name}의 계정을 정지했습니다`)
      }
    }
  }

  const handleSaveNote = () => {
    alert('관리자 메모를 저장했습니다')
  }

  const calculateAvgFanReplies = () => {
    if (creator.messages_this_month === 0) return 0
    const broadcastCount = chatMessages.filter(m => m.type === 'broadcast').length
    const replyCount = chatMessages.filter(m => m.type === 'reply').length
    if (broadcastCount === 0) return 0
    return Math.round(replyCount / broadcastCount)
  }

  const formatActivityScore = () => {
    const messages = creator.messages_this_month
    const subscribers = creator.total_subscribers
    return `메시지 ${messages}개 / 구독자 ${subscribers}명`
  }

  return (
    <div className="max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <Button
          variant="outline"
          onClick={() => router.push('/admin/creators')}
          className="mb-4"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          목록으로
        </Button>

        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <div className="flex items-start gap-6">
            <img
              src={getAvatarUrl(creator.avatar_seed)}
              alt={creator.name}
              className="w-24 h-24 rounded-full object-cover"
            />
            <div className="flex-1">
              <div className="flex items-start justify-between">
                <div>
                  <h1 className="text-2xl font-bold text-gray-900">{creator.name}</h1>
                  <div className="flex items-center gap-3 mt-2">
                    <Badge variant="outline">{creator.category}</Badge>
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${statusColors[creator.status]}`}>
                      {statusLabels[creator.status]}
                    </span>
                  </div>
                  <p className="text-sm text-gray-500 mt-2">
                    가입일: {formatDate(creator.join_date)}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <Button
                    variant="outline"
                    onClick={handleSendWarning}
                    className="flex items-center gap-2"
                  >
                    <AlertTriangle className="w-4 h-4" />
                    경고 발송
                  </Button>
                  <Button
                    variant={creator.status === 'suspended' ? 'primary' : 'outline'}
                    onClick={handleToggleSuspension}
                    className={creator.status === 'suspended' ? 'bg-green-600 hover:bg-green-700' : 'text-red-600 hover:text-red-700'}
                  >
                    {creator.status === 'suspended' ? (
                      <>
                        <CheckCircle className="w-4 h-4 mr-2" />
                        정지 해제
                      </>
                    ) : (
                      <>
                        <Ban className="w-4 h-4 mr-2" />
                        계정 정지
                      </>
                    )}
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Subscription Breakdown */}
      <div className="mb-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4">구독 현황</h2>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <div className="text-sm text-gray-600 font-medium">총 구독자</div>
            <div className="text-2xl font-bold text-gray-900 mt-1">
              {creator.total_subscribers.toLocaleString()}
            </div>
          </div>
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="text-sm text-blue-600 font-medium">BASIC (₩4,900)</div>
            <div className="text-2xl font-bold text-blue-900 mt-1">
              {creator.basic_count}
            </div>
            <div className="text-xs text-blue-600 mt-1">
              {formatKRW(creator.basic_count * 4900)}
            </div>
          </div>
          <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
            <div className="text-sm text-purple-600 font-medium">STANDARD (₩9,900)</div>
            <div className="text-2xl font-bold text-purple-900 mt-1">
              {creator.standard_count}
            </div>
            <div className="text-xs text-purple-600 mt-1">
              {formatKRW(creator.standard_count * 9900)}
            </div>
          </div>
          <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
            <div className="text-sm text-orange-600 font-medium">VIP (₩19,900)</div>
            <div className="text-2xl font-bold text-orange-900 mt-1">
              {creator.vip_count}
            </div>
            <div className="text-xs text-orange-600 mt-1">
              {formatKRW(creator.vip_count * 19900)}
            </div>
          </div>
        </div>
      </div>

      {/* Activity Metrics */}
      <div className="mb-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4">활동 지표</h2>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <div className="flex items-center gap-2 text-sm text-gray-600 font-medium">
              <MessageSquare className="w-4 h-4" />
              이번 달 브로드캐스트
            </div>
            <div className="text-2xl font-bold text-gray-900 mt-1">
              {creator.messages_this_month}
            </div>
          </div>
          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <div className="flex items-center gap-2 text-sm text-gray-600 font-medium">
              <Users className="w-4 h-4" />
              평균 팬 답글
            </div>
            <div className="text-2xl font-bold text-gray-900 mt-1">
              {calculateAvgFanReplies()}
            </div>
          </div>
          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <div className="flex items-center gap-2 text-sm text-gray-600 font-medium">
              <Calendar className="w-4 h-4" />
              마지막 접속
            </div>
            <div className="text-sm font-medium text-gray-900 mt-1">
              {formatDateTime(creator.last_access)}
            </div>
          </div>
          <div className="bg-white border border-gray-200 rounded-lg p-4">
            <div className="flex items-center gap-2 text-sm text-gray-600 font-medium">
              <Activity className="w-4 h-4" />
              활동 점수
            </div>
            <div className="text-2xl font-bold text-gray-900 mt-1">
              {creator.activity_score}
            </div>
            <div className="text-xs text-gray-500 mt-1">
              {formatActivityScore()}
            </div>
          </div>
        </div>
      </div>

      {/* Recent Chat Log */}
      <div className="mb-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4">최근 채팅 로그</h2>
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">시간</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">발신자</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">메시지</th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">유형</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {chatMessages.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-4 py-8 text-center text-gray-500">
                      최근 채팅 로그가 없습니다
                    </td>
                  </tr>
                ) : (
                  chatMessages.map(msg => (
                    <tr key={msg.id} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-sm text-gray-500 whitespace-nowrap">
                        {formatDateTime(msg.timestamp)}
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-900">
                        {msg.sender === 'creator' ? (
                          <span className="font-medium">{msg.sender_name}</span>
                        ) : (
                          <span>{msg.sender_name}</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-600 max-w-md">
                        {msg.message.length > 50 ? msg.message.slice(0, 50) + '...' : msg.message}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${messageTypeColors[msg.type]}`}>
                          {messageTypeLabels[msg.type]}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Revenue History */}
      <div className="mb-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4">수익 내역 (최근 6개월)</h2>
        <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">월</th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">구독</th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">DT 후원</th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">펀딩</th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">합계</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {revenueHistory.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-gray-500">
                      수익 내역이 없습니다
                    </td>
                  </tr>
                ) : (
                  revenueHistory.map((rev, idx) => (
                    <tr key={idx} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-sm font-medium text-gray-900">
                        {rev.month}
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-900 text-right">
                        {formatKRW(rev.subscription)}
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-900 text-right">
                        {formatKRW(rev.dt)}
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-900 text-right">
                        {formatKRW(rev.funding)}
                      </td>
                      <td className="px-4 py-3 text-sm font-bold text-gray-900 text-right">
                        {formatKRW(rev.total)}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Admin Notes */}
      <div className="mb-6">
        <h2 className="text-lg font-bold text-gray-900 mb-4">관리자 메모</h2>
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <textarea
            value={adminNote}
            onChange={(e) => setAdminNote(e.target.value)}
            placeholder="이 크리에이터에 대한 관리자 메모를 작성하세요..."
            className="w-full h-32 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
          />
          <div className="flex justify-end mt-3">
            <Button onClick={handleSaveNote}>
              메모 저장
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
