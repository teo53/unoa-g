'use client'

import { useState } from 'react'
import {
  CampaignEnhanced,
  RewardTierEnhanced,
  CampaignUpdate_,
  FaqItem,
  CampaignComment,
  CampaignReview
} from '@/lib/types/database'
import { CampaignHeader } from './campaign-header'
import { CampaignMetrics } from './campaign-metrics'
import { CampaignGallery } from './campaign-gallery'
import { CampaignTabs } from './campaign-tabs'
import { CampaignSidebar } from './campaign-sidebar'
import { EventScheduleBox } from './event-schedule-box'
import { BenefitsSection } from './benefits-section'
import {
  IntroTab,
  RewardsTab,
  UpdatesTab,
  FAQTab,
  CommunityTab,
  ReviewsTab
} from './tabs'

interface CampaignDetailClientProps {
  campaign: CampaignEnhanced
  tiers: RewardTierEnhanced[]
  updates: CampaignUpdate_[]
  faqs: FaqItem[]
  comments: CampaignComment[]
  reviews: CampaignReview[]
}

export function CampaignDetailClient({
  campaign,
  tiers: tiersProp,
  updates: updatesProp,
  faqs: faqsProp,
  comments: commentsProp,
  reviews: reviewsProp
}: CampaignDetailClientProps) {
  // Ensure arrays are never undefined
  const tiers = tiersProp || []
  const updates = updatesProp || []
  const faqs = faqsProp || []
  const comments = commentsProp || []
  const reviews = reviewsProp || []

  const [selectedTier, setSelectedTier] = useState<RewardTierEnhanced | null>(null)
  const [activeTab, setActiveTab] = useState('intro')

  const handlePledge = () => {
    if (selectedTier) {
      // In demo mode, just show alert
      alert(`"${selectedTier.title}" 리워드로 ${selectedTier.price_dt.toLocaleString()} DT 후원을 진행합니다.`)
    }
  }

  const handleAddComment = (content: string, parentId?: string) => {
    // In demo mode, just log
    console.log('New comment:', { content, parentId })
    alert('데모 모드에서는 댓글 작성이 지원되지 않습니다.')
  }

  // Tab counts for badges
  const tabCounts = {
    updates: updates.length,
    faq: faqs.length,
    community: comments.length,
    reviews: reviews.length
  }

  // Calculate enabled tabs with labels
  const enabledTabs = [
    { id: 'intro', label: '소개' },
    { id: 'rewards', label: '리워드', count: tiers.length },
    { id: 'updates', label: '새소식', count: updates.length },
    { id: 'faq', label: 'FAQ', count: faqs.length },
    { id: 'community', label: '커뮤니티', count: comments.length },
    { id: 'reviews', label: '후기', count: reviews.length },
  ].filter(tab => {
    // Always show intro and rewards
    if (tab.id === 'intro' || tab.id === 'rewards') return true
    // Show other tabs only if they have content
    return (tab.count || 0) > 0
  })

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Hero Section */}
      <section className="bg-white border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 py-6 lg:py-10">
          <div className="grid lg:grid-cols-[1fr_400px] gap-8">
            {/* Left Column - Gallery */}
            <div className="space-y-4">
              <CampaignGallery
                coverImage={campaign.cover_image_url}
                galleryImages={campaign.gallery_images}
                title={campaign.title}
              />
            </div>

            {/* Right Column - Campaign Info */}
            <div className="space-y-6">
              {/* Header */}
              <CampaignHeader campaign={campaign} />

              {/* Metrics */}
              <CampaignMetrics campaign={campaign} />

              {/* Event Schedule (Makestar style) */}
              {campaign.event_schedule && Object.keys(campaign.event_schedule).length > 0 && (
                <EventScheduleBox schedule={campaign.event_schedule} />
              )}

              {/* Mobile: Sidebar CTA (shows only on mobile) */}
              <div className="lg:hidden">
                <CampaignSidebar
                  campaign={campaign}
                  tiers={tiers}
                  selectedTier={selectedTier}
                  onSelectTier={setSelectedTier}
                  onPledge={handlePledge}
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Benefits Section (Makestar style) */}
      {campaign.benefits && campaign.benefits.length > 0 && (
        <section className="bg-white border-b border-gray-100">
          <div className="max-w-7xl mx-auto px-4 py-6">
            <BenefitsSection benefits={campaign.benefits} />
          </div>
        </section>
      )}

      {/* Main Content with Tabs */}
      <section className="max-w-7xl mx-auto px-4 py-6">
        <div className="grid lg:grid-cols-[1fr_400px] gap-8">
          {/* Left Column - Tabs & Content */}
          <div className="space-y-6">
            {/* Tab Navigation */}
            <CampaignTabs
              tabs={enabledTabs}
              activeTab={activeTab}
              onTabChange={setActiveTab}
            />

            {/* Tab Content */}
            <div className="bg-white rounded-2xl p-6 min-h-[400px]">
              {activeTab === 'intro' && (
                <IntroTab campaign={campaign} />
              )}
              {activeTab === 'rewards' && (
                <RewardsTab
                  tiers={tiers}
                  selectedTier={selectedTier}
                  onSelectTier={setSelectedTier}
                />
              )}
              {activeTab === 'updates' && (
                <UpdatesTab updates={updates} />
              )}
              {activeTab === 'faq' && (
                <FAQTab faqs={faqs} />
              )}
              {activeTab === 'community' && (
                <CommunityTab
                  comments={comments}
                  onAddComment={handleAddComment}
                />
              )}
              {activeTab === 'reviews' && (
                <ReviewsTab reviews={reviews} />
              )}
            </div>
          </div>

          {/* Right Column - Sticky Sidebar (desktop only) */}
          <div className="hidden lg:block">
            <div className="sticky top-24">
              <CampaignSidebar
                campaign={campaign}
                tiers={tiers}
                selectedTier={selectedTier}
                onSelectTier={setSelectedTier}
                onPledge={handlePledge}
              />
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
