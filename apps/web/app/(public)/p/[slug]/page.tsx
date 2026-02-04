import { notFound } from 'next/navigation'
import Link from 'next/link'
import {
  DEMO_MODE,
  getCampaignFullData,
  mockCampaigns
} from '@/lib/mock/demo-data'
import { formatPercent, formatBackerCount } from '@/lib/utils/format'
import { CampaignDetailClient } from '@/components/campaign/campaign-detail-client'
import type { Metadata } from 'next'
import type {
  CampaignEnhanced,
  RewardTierEnhanced,
  CampaignUpdate,
  FAQItem,
  CampaignComment,
  CampaignReview
} from '@/lib/types/database'

interface CampaignFullData {
  campaign: CampaignEnhanced
  tiers: RewardTierEnhanced[]
  updates: CampaignUpdate[]
  faqs: FAQItem[]
  comments: CampaignComment[]
  reviews: CampaignReview[]
}

interface PageProps {
  params: Promise<{ slug: string }>
}

async function getCampaignData(slug: string): Promise<CampaignFullData | null> {
  // Demo mode: return mock data
  if (DEMO_MODE) {
    return getCampaignFullData(slug)
  }

  // Production mode: use Supabase
  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  // Get campaign with enhanced data
  const { data: campaignData, error } = await supabase
    .from('funding_campaigns')
    .select(`
      *,
      creator:user_profiles!creator_id (
        id,
        display_name,
        avatar_url,
        bio
      )
    `)
    .eq('slug', slug)
    .in('status', ['active', 'completed', 'approved'])
    .single()

  if (error || !campaignData) {
    return null
  }

  // Get related data in parallel
  const [tiersResult, updatesResult, faqsResult, commentsResult, reviewsResult] = await Promise.all([
    supabase
      .from('funding_reward_tiers')
      .select('*')
      .eq('campaign_id', campaignData.id)
      .eq('is_active', true)
      .order('display_order'),

    supabase
      .from('funding_updates')
      .select('*')
      .eq('campaign_id', campaignData.id)
      .order('created_at', { ascending: false }),

    supabase
      .from('funding_faq_items')
      .select('*')
      .eq('campaign_id', campaignData.id)
      .order('display_order'),

    supabase
      .from('funding_comments')
      .select(`
        *,
        user:user_profiles!user_id (
          id,
          display_name,
          avatar_url
        )
      `)
      .eq('campaign_id', campaignData.id)
      .order('created_at', { ascending: false })
      .limit(50),

    supabase
      .from('funding_reviews')
      .select(`
        *,
        user:user_profiles!user_id (
          id,
          display_name,
          avatar_url
        )
      `)
      .eq('campaign_id', campaignData.id)
      .order('created_at', { ascending: false })
      .limit(50)
  ])

  return {
    campaign: campaignData as CampaignEnhanced,
    tiers: (tiersResult.data || []) as RewardTierEnhanced[],
    updates: (updatesResult.data || []) as CampaignUpdate[],
    faqs: (faqsResult.data || []) as FAQItem[],
    comments: (commentsResult.data || []) as CampaignComment[],
    reviews: (reviewsResult.data || []) as CampaignReview[]
  }
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params
  const data = await getCampaignData(slug)

  if (!data) {
    return {
      title: '캠페인을 찾을 수 없습니다',
    }
  }

  const { campaign } = data
  const percent = formatPercent(campaign.current_amount_dt, campaign.goal_amount_dt)

  return {
    title: campaign.title,
    description: campaign.subtitle || `${percent}% 달성 | ${formatBackerCount(campaign.backer_count)} 후원`,
    openGraph: {
      title: campaign.title,
      description: campaign.subtitle || `${percent}% 달성`,
      images: campaign.cover_image_url ? [campaign.cover_image_url] : [],
      type: 'website',
    },
    twitter: {
      card: 'summary_large_image',
      title: campaign.title,
      description: campaign.subtitle || `${percent}% 달성`,
      images: campaign.cover_image_url ? [campaign.cover_image_url] : [],
    },
  }
}

// Generate static params for popular campaigns
export async function generateStaticParams() {
  // Demo mode: return mock slugs
  if (DEMO_MODE) {
    return mockCampaigns.map((campaign) => ({
      slug: campaign.slug,
    }))
  }

  // Production mode: use Supabase
  const { createClient } = await import('@/lib/supabase/server')
  const supabase = await createClient()

  const { data } = await supabase
    .from('funding_campaigns')
    .select('slug')
    .in('status', ['active', 'completed'])
    .order('backer_count', { ascending: false })
    .limit(50)

  return (data || []).map((campaign: { slug: string }) => ({
    slug: campaign.slug,
  }))
}

export const revalidate = 60

export default async function CampaignDetailPage({ params }: PageProps) {
  const { slug } = await params
  const data = await getCampaignData(slug)

  if (!data) {
    notFound()
  }

  const { campaign, tiers, updates, faqs, comments, reviews } = data

  // JSON-LD structured data
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: campaign.title,
    description: campaign.subtitle || campaign.description_html?.slice(0, 200).replace(/<[^>]*>/g, ''),
    image: campaign.cover_image_url,
    offers: tiers.map((tier) => ({
      '@type': 'Offer',
      name: tier.title,
      price: tier.price_dt * 100, // Convert to KRW (1 DT = 100 KRW approx)
      priceCurrency: 'KRW',
      availability: tier.remaining_quantity === 0 ? 'https://schema.org/SoldOut' : 'https://schema.org/InStock',
    })),
  }

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />

      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="bg-amber-50 border-b border-amber-200 px-4 py-2 text-center text-sm text-amber-800">
          🎨 Demo Mode - Makestar/Tumblbug 스타일 목업 데이터 표시 중
        </div>
      )}

      {/* Header */}
      <header className="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 h-14 flex items-center justify-between">
          <Link href="/" className="text-xl font-bold text-pink-500">
            UNO A
          </Link>
          <nav className="flex items-center gap-4">
            <Link href="/funding" className="text-sm text-gray-600 hover:text-gray-900">
              펀딩 둘러보기
            </Link>
            <a
              href={`com.unoa.app://funding/${campaign.id}`}
              className="text-sm text-pink-600 hover:text-pink-700 font-medium"
            >
              앱에서 열기
            </a>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <CampaignDetailClient
        campaign={campaign}
        tiers={tiers}
        updates={updates}
        faqs={faqs}
        comments={comments}
        reviews={reviews}
      />
    </>
  )
}
