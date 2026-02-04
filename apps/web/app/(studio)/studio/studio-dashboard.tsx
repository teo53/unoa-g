'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { Plus, Edit2, Eye, Clock, CheckCircle, XCircle, Megaphone } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { formatDT, formatDate, formatPercent } from '@/lib/utils/format'
import { DEMO_MODE, mockCampaigns } from '@/lib/mock/demo-data'
import type { Campaign } from '@/lib/types/database'

function getStatusBadge(status: Campaign['status']) {
  const configs = {
    draft: { label: '초안', color: 'bg-gray-100 text-gray-700', icon: Edit2 },
    submitted: { label: '심사중', color: 'bg-yellow-100 text-yellow-700', icon: Clock },
    approved: { label: '승인됨', color: 'bg-green-100 text-green-700', icon: CheckCircle },
    rejected: { label: '반려됨', color: 'bg-red-100 text-red-700', icon: XCircle },
    active: { label: '진행중', color: 'bg-primary-100 text-primary-700', icon: Eye },
    completed: { label: '완료', color: 'bg-blue-100 text-blue-700', icon: CheckCircle },
    cancelled: { label: '취소됨', color: 'bg-gray-100 text-gray-500', icon: XCircle },
  }

  const config = configs[status]
  const Icon = config.icon

  return (
    <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${config.color}`}>
      <Icon className="w-3 h-3" />
      {config.label}
    </span>
  )
}

export default function StudioDashboard() {
  const [campaigns, setCampaigns] = useState<Campaign[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    async function loadCampaigns() {
      if (DEMO_MODE) {
        // In demo mode, show mock campaigns
        setCampaigns(mockCampaigns as Campaign[])
        setIsLoading(false)
        return
      }

      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()

      if (!user) {
        setIsLoading(false)
        return
      }

      const { data, error } = await supabase
        .from('funding_campaigns')
        .select('*')
        .eq('creator_id', user.id)
        .order('created_at', { ascending: false })

      if (error) {
        console.error('Error fetching campaigns:', error)
      } else {
        setCampaigns((data || []) as Campaign[])
      }
      setIsLoading(false)
    }

    loadCampaigns()
  }, [])

  const stats = {
    total: campaigns.length,
    active: campaigns.filter(c => c.status === 'active').length,
    draft: campaigns.filter(c => c.status === 'draft').length,
    totalRaised: campaigns.reduce((sum, c) => sum + c.current_amount_dt, 0),
    totalBackers: campaigns.reduce((sum, c) => sum + c.backer_count, 0),
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-primary-500 border-t-transparent" />
      </div>
    )
  }

  return (
    <div className="max-w-6xl mx-auto">
      {/* Demo Mode Banner */}
      {DEMO_MODE && (
        <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-xl text-yellow-800 text-sm">
          🎭 데모 모드: 샘플 캠페인 데이터가 표시됩니다
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">대시보드</h1>
          <p className="text-gray-500 mt-1">캠페인을 관리하고 성과를 확인하세요</p>
        </div>
        <Link href="/studio/campaigns/new">
          <Button>
            <Plus className="w-4 h-4 mr-2" />
            새 캠페인
          </Button>
        </Link>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-white rounded-xl p-4 border border-gray-100">
          <div className="text-sm text-gray-500 mb-1">전체 캠페인</div>
          <div className="text-2xl font-bold text-gray-900">{stats.total}</div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-100">
          <div className="text-sm text-gray-500 mb-1">진행중</div>
          <div className="text-2xl font-bold text-primary-500">{stats.active}</div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-100">
          <div className="text-sm text-gray-500 mb-1">총 모금액</div>
          <div className="text-2xl font-bold text-gray-900">{formatDT(stats.totalRaised)}</div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-100">
          <div className="text-sm text-gray-500 mb-1">총 후원자</div>
          <div className="text-2xl font-bold text-gray-900">{stats.totalBackers}명</div>
        </div>
      </div>

      {/* Campaigns List */}
      <div className="bg-white rounded-xl border border-gray-100">
        <div className="p-4 border-b border-gray-100">
          <h2 className="font-semibold text-gray-900">내 캠페인</h2>
        </div>

        {campaigns.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Megaphone className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">아직 캠페인이 없어요</h3>
            <p className="text-gray-500 mb-4">첫 번째 펀딩 캠페인을 만들어보세요</p>
            <Link href="/studio/campaigns/new">
              <Button>
                <Plus className="w-4 h-4 mr-2" />
                캠페인 만들기
              </Button>
            </Link>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {campaigns.map((campaign) => {
              const percent = formatPercent(campaign.current_amount_dt, campaign.goal_amount_dt)

              return (
                <div key={campaign.id} className="p-4 hover:bg-gray-50 transition-colors">
                  <div className="flex items-start gap-4">
                    {/* Thumbnail */}
                    <div className="w-24 h-16 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0">
                      {campaign.cover_image_url ? (
                        <img
                          src={campaign.cover_image_url}
                          alt={campaign.title}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-gray-400">
                          <Megaphone className="w-6 h-6" />
                        </div>
                      )}
                    </div>

                    {/* Info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-medium text-gray-900 truncate">
                          {campaign.title}
                        </h3>
                        {getStatusBadge(campaign.status)}
                      </div>
                      <div className="flex items-center gap-4 text-sm text-gray-500">
                        <span>{percent}% 달성</span>
                        <span>{campaign.backer_count}명 후원</span>
                        <span>{formatDate(campaign.created_at)}</span>
                      </div>

                      {/* Rejection reason */}
                      {campaign.status === 'rejected' && campaign.rejection_reason && (
                        <div className="mt-2 p-2 bg-red-50 rounded text-sm text-red-600">
                          반려 사유: {campaign.rejection_reason}
                        </div>
                      )}
                    </div>

                    {/* Actions */}
                    <div className="flex items-center gap-2 flex-shrink-0">
                      {['draft', 'rejected'].includes(campaign.status) && (
                        <Link href={`/studio/campaigns/${campaign.id}/edit`}>
                          <Button variant="outline" size="sm">
                            <Edit2 className="w-4 h-4 mr-1" />
                            수정
                          </Button>
                        </Link>
                      )}
                      <Link href={`/studio/campaigns/${campaign.id}/preview`}>
                        <Button variant="ghost" size="sm">
                          <Eye className="w-4 h-4 mr-1" />
                          미리보기
                        </Button>
                      </Link>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
