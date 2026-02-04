import Link from 'next/link'
import { Clock, CheckCircle, XCircle, Eye } from 'lucide-react'
import { DEMO_MODE, mockCampaigns } from '@/lib/mock/demo-data'
import { Button } from '@/components/ui/button'
import { formatDate, formatDT } from '@/lib/utils/format'

interface Campaign {
  id: string
  title: string
  cover_image_url: string | null
  goal_amount_dt: number
  submitted_at: string | null
  status: string
}

async function getPendingCampaigns(): Promise<Campaign[]> {
  if (DEMO_MODE) {
    // Demo mode: return mock submitted campaigns (none for demo)
    return mockCampaigns
      .filter(c => c.status === 'submitted')
      .map(c => ({
        id: c.id,
        title: c.title,
        cover_image_url: c.cover_image_url,
        goal_amount_dt: c.goal_amount_dt,
        submitted_at: c.created_at,
        status: c.status,
      }))
  }

  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('funding_campaigns')
    .select('*')
    .eq('status', 'submitted')
    .order('submitted_at', { ascending: true })

  if (error) {
    console.error('Error fetching campaigns:', error)
    return []
  }

  return data || []
}

async function getStats() {
  if (DEMO_MODE) {
    // Demo mode: return mock stats
    const active = mockCampaigns.filter(c => c.status === 'active').length
    return {
      pending: 0,
      approved: active,
      rejected: 0,
    }
  }

  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  const [pending, approved, rejected] = await Promise.all([
    supabase.from('funding_campaigns').select('id', { count: 'exact' }).eq('status', 'submitted'),
    supabase.from('funding_campaigns').select('id', { count: 'exact' }).eq('status', 'active'),
    supabase.from('funding_campaigns').select('id', { count: 'exact' }).eq('status', 'rejected'),
  ])

  return {
    pending: pending.count || 0,
    approved: approved.count || 0,
    rejected: rejected.count || 0,
  }
}

export default async function AdminDashboardPage() {
  const [campaigns, stats] = await Promise.all([
    getPendingCampaigns(),
    getStats(),
  ])

  return (
    <div className="max-w-6xl mx-auto">
      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          Demo Mode - Mock data is displayed
        </div>
      )}

      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">관리자 대시보드</h1>
        <p className="text-gray-500 mt-1">캠페인 심사 및 관리</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-yellow-100 rounded-lg flex items-center justify-center">
              <Clock className="w-5 h-5 text-yellow-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{stats.pending}</div>
              <div className="text-sm text-gray-500">심사 대기</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <CheckCircle className="w-5 h-5 text-green-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{stats.approved}</div>
              <div className="text-sm text-gray-500">진행중</div>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
              <XCircle className="w-5 h-5 text-red-600" />
            </div>
            <div>
              <div className="text-2xl font-bold text-gray-900">{stats.rejected}</div>
              <div className="text-sm text-gray-500">반려됨</div>
            </div>
          </div>
        </div>
      </div>

      {/* Pending Campaigns */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-4 border-b border-gray-200">
          <h2 className="font-semibold text-gray-900">심사 대기 캠페인</h2>
        </div>

        {campaigns.length === 0 ? (
          <div className="p-12 text-center">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <CheckCircle className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">모든 심사 완료</h3>
            <p className="text-gray-500">대기 중인 캠페인이 없습니다</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {campaigns.map((campaign) => (
              <div key={campaign.id} className="p-4 hover:bg-gray-50 transition-colors">
                <div className="flex items-start gap-4">
                  {/* Thumbnail */}
                  <div className="w-20 h-14 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0">
                    {campaign.cover_image_url ? (
                      <img
                        src={campaign.cover_image_url}
                        alt={campaign.title}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-400 text-xs">
                        No Image
                      </div>
                    )}
                  </div>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <h3 className="font-medium text-gray-900 truncate">
                      {campaign.title}
                    </h3>
                    <div className="flex items-center gap-4 text-sm text-gray-500 mt-1">
                      <span>목표: {formatDT(campaign.goal_amount_dt)}</span>
                      {campaign.submitted_at && (
                        <span>제출: {formatDate(campaign.submitted_at)}</span>
                      )}
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <Link href={`/admin/campaigns/${campaign.id}`}>
                      <Button size="sm">
                        <Eye className="w-4 h-4 mr-1" />
                        심사하기
                      </Button>
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
