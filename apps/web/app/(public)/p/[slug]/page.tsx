import { notFound } from 'next/navigation'
import Link from 'next/link'
import {
  DEMO_MODE,
  getCampaignFullData,
  mockCampaigns
} from '@/lib/mock/demo-data'
import { formatPercent, formatBackerCount } from '@/lib/utils/format'
import { sanitizeJsonLdValue } from '@/lib/utils/sanitize'
import { CampaignDetailClient } from '@/components/campaign/campaign-detail-client'
import type { Metadata } from 'next'
import type {
  CampaignEnhanced,
  RewardTierEnhanced,
  CampaignUpdate_,
  FaqItem,
  CampaignComment,
  CampaignReview
} from '@/lib/types/database'

interface CampaignFullData {
  campaign: CampaignEnhanced
  tiers: RewardTierEnhanced[]
  updates: CampaignUpdate_[]
  faqs: FaqItem[]
  comments: CampaignComment[]
  reviews: CampaignReview[]
}

interface PageProps {
  params: Promise<{ slug: string }>
}

const IS_DEMO_BUILD = process.env.NEXT_PUBLIC_DEMO_BUILD === 'true'

function toSafeJsonLdScript(data: unknown): string {
  return JSON.stringify(data)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026')
    .replace(/\u2028/g, '\\u2028')
    .replace(/\u2029/g, '\\u2029')
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
    .single() as { data: (CampaignEnhanced & { id: string }) | null; error: unknown }

  if (error || !campaignData) {
    return null
  }

  const campaignId = campaignData.id

  // Get related data in parallel
  const [tiersResult, updatesResult, faqsResult, commentsResult, reviewsResult] = await Promise.all([
    supabase
      .from('funding_reward_tiers')
      .select('*')
      .eq('campaign_id', campaignId)
      .eq('is_active', true)
      .order('display_order'),

    supabase
      .from('funding_updates')
      .select('*')
      .eq('campaign_id', campaignId)
      .order('created_at', { ascending: false }),

    supabase
      .from('funding_faq_items')
      .select('*')
      .eq('campaign_id', campaignId)
      .order('display_order'),

    supabase
      .from('funding_comments' as any)
      .select(`
        *,
        user:user_profiles!user_id (
          id,
          display_name,
          avatar_url
        )
      `)
      .eq('campaign_id', campaignId)
      .order('created_at', { ascending: false })
      .limit(50) as any,

    supabase
      .from('funding_reviews' as any)
      .select(`
        *,
        user:user_profiles!user_id (
          id,
          display_name,
          avatar_url
        )
      `)
      .eq('campaign_id', campaignId)
      .order('created_at', { ascending: false })
      .limit(50) as any
  ])

  return {
    campaign: campaignData as CampaignEnhanced,
    tiers: (tiersResult.data || []) as RewardTierEnhanced[],
    updates: (updatesResult.data || []) as CampaignUpdate_[],
    faqs: (faqsResult.data || []) as FaqItem[],
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
  if (DEMO_MODE || IS_DEMO_BUILD) {
    return mockCampaigns.map((campaign) => ({
      slug: campaign.slug,
    }))
  }
  return []
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
  const campaignDescription =
    campaign.subtitle || campaign.description_html?.slice(0, 200).replace(/<[^>]*>/g, '') || ''

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: sanitizeJsonLdValue(campaign.title || ''),
    description: sanitizeJsonLdValue(campaignDescription),
    image: campaign.cover_image_url ? sanitizeJsonLdValue(campaign.cover_image_url) : undefined,
    offers: tiers.map((tier) => ({
      '@type': 'Offer',
      name: sanitizeJsonLdValue(tier.title || ''),
      price: tier.price_dt,
      priceCurrency: 'KRW',
      availability: tier.remaining_quantity === 0 ? 'https://schema.org/SoldOut' : 'https://schema.org/InStock',
    })),
  }

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: toSafeJsonLdScript(jsonLd) }}
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
