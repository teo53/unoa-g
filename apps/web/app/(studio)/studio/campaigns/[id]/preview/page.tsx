import { notFound } from 'next/navigation'
import Link from 'next/link'
import { ArrowLeft, Edit2 } from 'lucide-react'
import { DEMO_MODE, getCampaignById, getTiersByCampaignId, getFAQsByCampaignId, getMockCampaignIds } from '@/lib/mock/demo-data'
import { formatDT, formatPercent, formatDate, formatBackerCount } from '@/lib/utils/format'
import { sanitizeHtml } from '@/lib/utils/sanitize'
import { Button } from '@/components/ui/button'

interface PageProps {
  params: Promise<{ id: string }>
}

// Generate static params for static export
export function generateStaticParams() {
  return getMockCampaignIds().map((id) => ({ id }))
}

export default async function PreviewCampaignPage({ params }: PageProps) {
  const { id } = await params

  let campaign: any = null
  let tiers: any[] = []
  let faqs: any[] = []

  if (DEMO_MODE) {
    campaign = getCampaignById(id)
    if (campaign) {
      tiers = getTiersByCampaignId(id)
      faqs = getFAQsByCampaignId(id)
    }
  } else {
    const { createClient } = await import('@/lib/supabase/server')
    const supabase = await createClient()

    const { data } = await supabase
      .from('funding_campaigns')
      .select(`
        *,
        funding_reward_tiers (*),
        funding_faq_items (*)
      `)
      .eq('id', id)
      .single()

    if (data) {
      campaign = data
      tiers = (data as any).funding_reward_tiers || []
      faqs = (data as any).funding_faq_items || []
    }
  }

  if (!campaign) {
    notFound()
  }

  const percent = formatPercent(campaign.current_amount_dt, campaign.goal_amount_dt)
  tiers = tiers.sort((a, b) => a.display_order - b.display_order)
  faqs = faqs.sort((a, b) => a.display_order - b.display_order)

  return (
    <div className="max-w-6xl mx-auto">
      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          Demo Mode - Mock data is displayed
        </div>
      )}

      {/* Preview Banner */}
      <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4 mb-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <span className="px-2 py-1 bg-yellow-200 text-yellow-800 text-xs font-medium rounded">
            미리보기
          </span>
          <span className="text-yellow-800">
            이것은 미리보기입니다. 실제 페이지와 다를 수 있습니다.
          </span>
        </div>
        <div className="flex items-center gap-3">
          <Link href={`/studio/campaigns/${id}/edit`}>
            <Button variant="outline" size="sm">
              <Edit2 className="w-4 h-4 mr-1" />
              수정
            </Button>
          </Link>
          <Link href="/studio">
            <Button variant="outline" size="sm">
              <ArrowLeft className="w-4 h-4 mr-1" />
              대시보드
            </Button>
          </Link>
        </div>
      </div>

      {/* Campaign Preview Content */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        {/* Cover Image */}
        <div className="aspect-[21/9] bg-gray-100 relative">
          {campaign.cover_image_url ? (
            <img
              src={campaign.cover_image_url}
              alt={campaign.title}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-gray-400">
              커버 이미지 없음
            </div>
          )}
        </div>

        <div className="p-8">
          <div className="grid lg:grid-cols-3 gap-8">
            {/* Main Content */}
            <div className="lg:col-span-2 space-y-6">
              {/* Category */}
              {campaign.category && (
                <span className="text-sm text-primary-500 font-medium">
                  {campaign.category}
                </span>
              )}

              {/* Title */}
              <h1 className="text-3xl font-bold text-gray-900">
                {campaign.title || '제목 없음'}
              </h1>

              {/* Subtitle */}
              {campaign.subtitle && (
                <p className="text-lg text-gray-600">{campaign.subtitle}</p>
              )}

              {/* Progress */}
              <div className="bg-gray-50 rounded-xl p-6">
                <div className="flex items-end gap-2 mb-4">
                  <span className="text-4xl font-bold text-primary-500">{percent}%</span>
                  <span className="text-gray-500 mb-1">달성</span>
                </div>
                <div className="h-3 bg-gray-200 rounded-full overflow-hidden mb-4">
                  <div
                    className="h-full bg-primary-500 rounded-full"
                    style={{ width: `${Math.min(percent, 100)}%` }}
                  />
                </div>
                <div className="grid grid-cols-3 gap-4 text-center text-sm">
                  <div>
                    <div className="font-bold text-gray-900">{formatDT(campaign.current_amount_dt)}</div>
                    <div className="text-gray-500">모인 금액</div>
                  </div>
                  <div>
                    <div className="font-bold text-gray-900">{formatBackerCount(campaign.backer_count)}</div>
                    <div className="text-gray-500">후원자</div>
                  </div>
                  <div>
                    <div className="font-bold text-gray-900">
                      {campaign.end_at ? formatDate(campaign.end_at) : '-'}
                    </div>
                    <div className="text-gray-500">마감일</div>
                  </div>
                </div>
              </div>

              {/* Description */}
              <div>
                <h2 className="text-xl font-bold mb-4">프로젝트 소개</h2>
                {campaign.description_html ? (
                  <div
                    className="prose prose-gray max-w-none"
                    dangerouslySetInnerHTML={{ __html: sanitizeHtml(campaign.description_html) }}
                  />
                ) : campaign.description_md ? (
                  <div className="prose prose-gray max-w-none whitespace-pre-wrap">
                    {campaign.description_md}
                  </div>
                ) : (
                  <p className="text-gray-500">프로젝트 소개가 없습니다.</p>
                )}
              </div>

              {/* FAQ */}
              {faqs.length > 0 && (
                <div>
                  <h2 className="text-xl font-bold mb-4">자주 묻는 질문</h2>
                  <div className="space-y-4">
                    {faqs.map((faq) => (
                      <div key={faq.id} className="border-b border-gray-100 pb-4">
                        <h3 className="font-medium text-gray-900 mb-1">Q. {faq.question}</h3>
                        <p className="text-gray-600">A. {faq.answer}</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Sidebar - Reward Tiers */}
            <div className="space-y-4">
              <h2 className="text-xl font-bold">리워드</h2>
              {tiers.length > 0 ? (
                tiers.map((tier) => (
                  <div
                    key={tier.id}
                    className={`bg-white rounded-xl p-5 border-2 ${
                      tier.is_featured ? 'border-primary-500' : 'border-gray-200'
                    }`}
                  >
                    {tier.is_featured && (
                      <span className="inline-block px-2 py-1 bg-primary-500 text-white text-xs font-medium rounded mb-2">
                        추천
                      </span>
                    )}
                    <div className="text-2xl font-bold text-gray-900 mb-2">
                      {formatDT(tier.price_dt)}
                    </div>
                    <h3 className="font-semibold text-gray-900 mb-2">{tier.title}</h3>
                    {tier.description && (
                      <p className="text-sm text-gray-600 mb-3">{tier.description}</p>
                    )}
                    {tier.total_quantity && (
                      <p className="text-sm text-gray-500">
                        {tier.remaining_quantity}/{tier.total_quantity} 남음
                      </p>
                    )}
                  </div>
                ))
              ) : (
                <p className="text-gray-500 text-center py-8">
                  등록된 리워드가 없습니다
                </p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
