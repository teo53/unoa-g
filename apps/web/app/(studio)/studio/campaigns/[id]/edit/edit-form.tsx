'use client'

import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Save, Eye, Send, Plus, Trash2, GripVertical, ArrowLeft, ChevronDown, ChevronUp } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { ImageUploader } from '@/components/ui/image-uploader'
import { TiptapEditor } from '@/components/studio/tiptap-editor'
import { DEMO_MODE, getCampaignById, getTiersByCampaignId, getFAQsByCampaignId } from '@/lib/mock/demo-data'
import {
  GalleryEditor,
  EventScheduleEditor,
  BenefitsEditor,
  StretchGoalsEditor,
  BudgetEditor,
  ScheduleEditor,
  TeamEditor,
  NoticesEditor,
  RewardAdvancedEditor,
} from '@/components/studio/editors'
import {
  GalleryImage,
  EventSchedule,
  Benefit,
  StretchGoal,
  BudgetInfo,
  ScheduleMilestone,
  TeamInfo,
  Notice,
  RewardTierEnhanced,
} from '@/lib/types/database'

// Local types for this page
interface Campaign {
  id: string
  creator_id: string
  title: string
  subtitle?: string | null
  category?: string | null
  cover_image_url?: string | null
  description_md?: string | null
  description_html?: string | null
  goal_amount_dt: number
  current_amount_dt: number
  end_at?: string | null
  status: string
  // Enhanced fields
  gallery_images?: GalleryImage[]
  event_schedule?: EventSchedule
  benefits?: Benefit[]
  stretch_goals?: StretchGoal[]
  budget_info?: BudgetInfo
  schedule_info?: ScheduleMilestone[]
  team_info?: TeamInfo
  notices?: Notice[]
}

interface RewardTier {
  id: string
  campaign_id: string
  title: string
  description?: string | null
  price_dt: number
  total_quantity?: number | null
  remaining_quantity?: number | null
  display_order: number
  is_active: boolean
  is_featured: boolean
  pledge_count: number
  // Enhanced fields
  badge_type?: string
  badge_label?: string
  member_options?: Array<{ member_name: string; member_id: string; avatar_url?: string; additional_info?: string }>
  has_member_selection?: boolean
  included_items?: Array<{ name: string; quantity: number; description?: string; image_url?: string }>
  estimated_delivery_at?: string
  shipping_info?: string
}

interface FaqItem {
  id: string
  campaign_id: string
  question: string
  answer: string
  display_order: number
}

interface EditFormProps {
  id: string
}

// Collapsible Section Component
function Section({
  title,
  children,
  defaultOpen = true,
}: {
  title: string
  children: React.ReactNode
  defaultOpen?: boolean
}) {
  const [isOpen, setIsOpen] = useState(defaultOpen)

  return (
    <section className="bg-white rounded-xl border border-gray-100 overflow-hidden">
      <button
        type="button"
        className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
        onClick={() => setIsOpen(!isOpen)}
      >
        <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
        {isOpen ? (
          <ChevronUp className="h-5 w-5 text-gray-400" />
        ) : (
          <ChevronDown className="h-5 w-5 text-gray-400" />
        )}
      </button>
      {isOpen && <div className="px-6 pb-6">{children}</div>}
    </section>
  )
}

export default function EditForm({ id }: EditFormProps) {
  const router = useRouter()

  const [campaign, setCampaign] = useState<Campaign | null>(null)
  const [tiers, setTiers] = useState<RewardTier[]>([])
  const [faqs, setFaqs] = useState<FaqItem[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [lastSaved, setLastSaved] = useState<Date | null>(null)

  // Basic Form state
  const [title, setTitle] = useState('')
  const [subtitle, setSubtitle] = useState('')
  const [category, setCategory] = useState('')
  const [coverImageUrl, setCoverImageUrl] = useState('')
  const [descriptionMd, setDescriptionMd] = useState('')
  const [descriptionHtml, setDescriptionHtml] = useState('')
  const [goalAmountDt, setGoalAmountDt] = useState(0)
  const [currentAmountDt, setCurrentAmountDt] = useState(0)
  const [endAt, setEndAt] = useState('')

  // Enhanced Form state
  const [galleryImages, setGalleryImages] = useState<GalleryImage[]>([])
  const [eventSchedule, setEventSchedule] = useState<EventSchedule>({})
  const [benefits, setBenefits] = useState<Benefit[]>([])
  const [stretchGoals, setStretchGoals] = useState<StretchGoal[]>([])
  const [budgetInfo, setBudgetInfo] = useState<BudgetInfo>({ items: [], total: 0, currency: 'KRW' })
  const [scheduleInfo, setScheduleInfo] = useState<ScheduleMilestone[]>([])
  const [teamInfo, setTeamInfo] = useState<TeamInfo>({ members: [] })
  const [notices, setNotices] = useState<Notice[]>([])

  // Expanded tier for advanced editing
  const [expandedTierId, setExpandedTierId] = useState<string | null>(null)

  // Load campaign data
  useEffect(() => {
    async function loadCampaign() {
      setIsLoading(true)

      // Demo mode
      if (DEMO_MODE) {
        const campaignData = getCampaignById(id)
        if (!campaignData) {
          setError('캠페인을 찾을 수 없습니다')
          setIsLoading(false)
          return
        }

        setCampaign(campaignData as unknown as Campaign)
        setTitle(campaignData.title)
        setSubtitle(campaignData.subtitle || '')
        setCategory(campaignData.category || '')
        setCoverImageUrl(campaignData.cover_image_url || '')
        setDescriptionMd(campaignData.description_md || '')
        setDescriptionHtml(campaignData.description_html || '')
        setGoalAmountDt(campaignData.goal_amount_dt)
        setCurrentAmountDt(campaignData.current_amount_dt || 0)
        setEndAt(campaignData.end_at ? campaignData.end_at.split('T')[0] : '')

        // Enhanced fields
        setGalleryImages(campaignData.gallery_images || [])
        setEventSchedule(campaignData.event_schedule || {})
        setBenefits(campaignData.benefits || [])
        setStretchGoals(campaignData.stretch_goals || [])
        setBudgetInfo(campaignData.budget_info || { items: [], total: 0, currency: 'KRW' })
        setScheduleInfo(campaignData.schedule_info || [])
        setTeamInfo(campaignData.team_info || { members: [] })
        setNotices(campaignData.notices || [])

        const tiersData = getTiersByCampaignId(id)
        setTiers(tiersData as unknown as RewardTier[])
        setFaqs(getFAQsByCampaignId(id) as FaqItem[])
        setIsLoading(false)
        return
      }

      // Production mode
      const { createClient } = await import('@/lib/supabase/client')
      const supabase = createClient()

      const { data: campaignData, error: campaignError } = await supabase
        .from('funding_campaigns')
        .select('*')
        .eq('id', id)
        .single()

      if (campaignError || !campaignData) {
        setError('캠페인을 찾을 수 없습니다')
        setIsLoading(false)
        return
      }

      // Check ownership
      const { data: { user } } = await supabase.auth.getUser()
      if ((campaignData as Campaign).creator_id !== user?.id) {
        setError('이 캠페인을 수정할 권한이 없습니다')
        setIsLoading(false)
        return
      }

      // Check status
      if (!['draft', 'rejected'].includes((campaignData as Campaign).status)) {
        setError('이 캠페인은 수정할 수 없습니다')
        setIsLoading(false)
        return
      }

      const typedCampaign = campaignData as Campaign
      setCampaign(typedCampaign)
      setTitle(typedCampaign.title)
      setSubtitle(typedCampaign.subtitle || '')
      setCategory(typedCampaign.category || '')
      setCoverImageUrl(typedCampaign.cover_image_url || '')
      setDescriptionMd(typedCampaign.description_md || '')
      setDescriptionHtml(typedCampaign.description_html || '')
      setGoalAmountDt(typedCampaign.goal_amount_dt)
      setCurrentAmountDt(typedCampaign.current_amount_dt || 0)
      setEndAt(typedCampaign.end_at ? typedCampaign.end_at.split('T')[0] : '')

      // Enhanced fields
      setGalleryImages(typedCampaign.gallery_images || [])
      setEventSchedule(typedCampaign.event_schedule || {})
      setBenefits(typedCampaign.benefits || [])
      setStretchGoals(typedCampaign.stretch_goals || [])
      setBudgetInfo(typedCampaign.budget_info || { items: [], total: 0, currency: 'KRW' })
      setScheduleInfo(typedCampaign.schedule_info || [])
      setTeamInfo(typedCampaign.team_info || { members: [] })
      setNotices(typedCampaign.notices || [])

      // Load tiers
      const { data: tiersData } = await supabase
        .from('funding_reward_tiers')
        .select('*')
        .eq('campaign_id', id)
        .order('display_order')

      setTiers((tiersData || []) as RewardTier[])

      // Load FAQs
      const { data: faqsData } = await supabase
        .from('funding_faq_items')
        .select('*')
        .eq('campaign_id', id)
        .order('display_order')

      setFaqs((faqsData || []) as FaqItem[])

      setIsLoading(false)
    }

    loadCampaign()
  }, [id])

  // Save campaign
  const saveCampaign = useCallback(async () => {
    setIsSaving(true)
    setError(null)

    try {
      // Demo mode: just simulate save
      if (DEMO_MODE) {
        await new Promise(resolve => setTimeout(resolve, 500))
        setLastSaved(new Date())
        return
      }

      const { createClient } = await import('@/lib/supabase/client')
      const supabase = createClient()

      const { error: updateError } = await supabase
        .from('funding_campaigns')
        .update({
          title,
          subtitle: subtitle || null,
          category: category || null,
          cover_image_url: coverImageUrl || null,
          description_md: descriptionMd || null,
          description_html: descriptionHtml || null,
          goal_amount_dt: goalAmountDt,
          end_at: endAt ? new Date(endAt).toISOString() : null,
          // Enhanced fields
          gallery_images: galleryImages,
          event_schedule: eventSchedule,
          benefits,
          stretch_goals: stretchGoals,
          budget_info: budgetInfo,
          schedule_info: scheduleInfo,
          team_info: teamInfo,
          notices,
        } as never)
        .eq('id', id)

      if (updateError) throw updateError

      setLastSaved(new Date())
    } catch (err) {
      setError(err instanceof Error ? err.message : '저장에 실패했습니다')
    } finally {
      setIsSaving(false)
    }
  }, [id, title, subtitle, category, coverImageUrl, descriptionMd, descriptionHtml, goalAmountDt, endAt, galleryImages, eventSchedule, benefits, stretchGoals, budgetInfo, scheduleInfo, teamInfo, notices])

  // Auto-save every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      if (campaign && !isSaving) {
        saveCampaign()
      }
    }, 30000)

    return () => clearInterval(interval)
  }, [campaign, isSaving, saveCampaign])

  // Add tier
  const addTier = async () => {
    // Demo mode: add locally
    if (DEMO_MODE) {
      const newTier: RewardTier = {
        id: `tier-${Date.now()}`,
        campaign_id: id,
        title: '새 리워드',
        price_dt: 100,
        display_order: tiers.length,
        is_active: true,
        is_featured: false,
        pledge_count: 0,
        member_options: [],
        included_items: [],
      }
      setTiers([...tiers, newTier])
      setExpandedTierId(newTier.id)
      return
    }

    const { createClient } = await import('@/lib/supabase/client')
    const supabase = createClient()

    const { data, error } = await supabase
      .from('funding_reward_tiers')
      .insert({
        campaign_id: id,
        title: '새 리워드',
        price_dt: 100,
        display_order: tiers.length,
      } as never)
      .select()
      .single()

    if (!error && data) {
      setTiers([...tiers, data as RewardTier])
      setExpandedTierId((data as RewardTier).id)
    }
  }

  // Update tier
  const updateTier = async (tierId: string, updates: Partial<RewardTier>) => {
    // Demo mode: update locally only
    if (DEMO_MODE) {
      setTiers(tiers.map(t => t.id === tierId ? { ...t, ...updates } : t))
      return
    }

    const { createClient } = await import('@/lib/supabase/client')
    const supabase = createClient()

    const { error } = await supabase
      .from('funding_reward_tiers')
      .update(updates as never)
      .eq('id', tierId)

    if (!error) {
      setTiers(tiers.map(t => t.id === tierId ? { ...t, ...updates } : t))
    }
  }

  // Delete tier
  const deleteTier = async (tierId: string) => {
    // Demo mode: delete locally only
    if (DEMO_MODE) {
      setTiers(tiers.filter(t => t.id !== tierId))
      return
    }

    const { createClient } = await import('@/lib/supabase/client')
    const supabase = createClient()

    const { error } = await supabase
      .from('funding_reward_tiers')
      .delete()
      .eq('id', tierId)

    if (!error) {
      setTiers(tiers.filter(t => t.id !== tierId))
    }
  }

  // Add FAQ
  const addFaq = async () => {
    // Demo mode: add locally
    if (DEMO_MODE) {
      const newFaq: FaqItem = {
        id: `faq-${Date.now()}`,
        campaign_id: id,
        question: '질문을 입력하세요',
        answer: '답변을 입력하세요',
        display_order: faqs.length,
      }
      setFaqs([...faqs, newFaq])
      return
    }

    const { createClient } = await import('@/lib/supabase/client')
    const supabase = createClient()

    const { data, error } = await supabase
      .from('funding_faq_items')
      .insert({
        campaign_id: id,
        question: '질문을 입력하세요',
        answer: '답변을 입력하세요',
        display_order: faqs.length,
      } as never)
      .select()
      .single()

    if (!error && data) {
      setFaqs([...faqs, data as FaqItem])
    }
  }

  // Update FAQ
  const updateFaq = async (faqId: string, updates: Partial<FaqItem>) => {
    // Demo mode: update locally only
    if (DEMO_MODE) {
      setFaqs(faqs.map(f => f.id === faqId ? { ...f, ...updates } : f))
      return
    }

    const { createClient } = await import('@/lib/supabase/client')
    const supabase = createClient()

    const { error } = await supabase
      .from('funding_faq_items')
      .update(updates as never)
      .eq('id', faqId)

    if (!error) {
      setFaqs(faqs.map(f => f.id === faqId ? { ...f, ...updates } : f))
    }
  }

  // Delete FAQ
  const deleteFaq = async (faqId: string) => {
    // Demo mode: delete locally only
    if (DEMO_MODE) {
      setFaqs(faqs.filter(f => f.id !== faqId))
      return
    }

    const { createClient } = await import('@/lib/supabase/client')
    const supabase = createClient()

    const { error } = await supabase
      .from('funding_faq_items')
      .delete()
      .eq('id', faqId)

    if (!error) {
      setFaqs(faqs.filter(f => f.id !== faqId))
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-primary-500 border-t-transparent" />
      </div>
    )
  }

  if (error && !campaign) {
    return (
      <div className="max-w-2xl mx-auto text-center py-12">
        <p className="text-red-500 mb-4">{error}</p>
        <Link href="/studio">
          <Button variant="outline">대시보드로 돌아가기</Button>
        </Link>
      </div>
    )
  }

  const categories = ['K-POP', '음악', '영상', '굿즈', '이벤트', '기타']

  return (
    <div className="max-w-4xl mx-auto pb-20">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-gray-50 py-4 mb-6 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link href="/studio" className="text-gray-500 hover:text-gray-700">
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div>
              <h1 className="text-xl font-bold text-gray-900">캠페인 수정</h1>
              {lastSaved && (
                <p className="text-sm text-gray-500">
                  마지막 저장: {lastSaved.toLocaleTimeString()}
                </p>
              )}
            </div>
          </div>
          <div className="flex items-center gap-3">
            <Button variant="outline" onClick={saveCampaign} loading={isSaving}>
              <Save className="w-4 h-4 mr-2" />
              저장
            </Button>
            <Link href={`/studio/campaigns/${id}/preview`}>
              <Button variant="outline">
                <Eye className="w-4 h-4 mr-2" />
                미리보기
              </Button>
            </Link>
            <Link href={`/studio/campaigns/${id}/submit`}>
              <Button>
                <Send className="w-4 h-4 mr-2" />
                제출하기
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-xl text-red-600">
          {error}
        </div>
      )}

      <div className="space-y-6">
        {/* 1. Basic Info */}
        <Section title="기본 정보" defaultOpen={true}>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                캠페인 제목 *
              </label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                maxLength={100}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                부제목
              </label>
              <input
                type="text"
                value={subtitle}
                onChange={(e) => setSubtitle(e.target.value)}
                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                maxLength={200}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                카테고리
              </label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              >
                <option value="">선택하세요</option>
                {categories.map((cat) => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                커버 이미지
              </label>
              <ImageUploader
                bucket="campaign-images"
                folder={`campaign-${id}/cover`}
                value={coverImageUrl}
                onChange={setCoverImageUrl}
                aspectRatio={16 / 9}
                placeholder="커버 이미지 업로드 (권장 비율 16:9)"
                maxSizeMB={5}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  목표 금액 (원) *
                </label>
                <input
                  type="number"
                  value={goalAmountDt}
                  onChange={(e) => setGoalAmountDt(parseInt(e.target.value) || 0)}
                  className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  min={100}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  종료일 *
                </label>
                <input
                  type="date"
                  value={endAt}
                  onChange={(e) => setEndAt(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                  min={new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]}
                />
              </div>
            </div>
          </div>
        </Section>

        {/* 2. Gallery Images */}
        <Section title="갤러리 이미지" defaultOpen={false}>
          <GalleryEditor images={galleryImages} onChange={setGalleryImages} />
        </Section>

        {/* 3. Story */}
        <Section title="프로젝트 소개" defaultOpen={false}>
          <TiptapEditor
            content={descriptionHtml}
            onChange={(text, html) => {
              setDescriptionMd(text)
              setDescriptionHtml(html)
            }}
            campaignId={id}
          />
        </Section>

        {/* 4. Event Schedule (Makestar style) */}
        <Section title="이벤트 일정 (Makestar 스타일)" defaultOpen={false}>
          <EventScheduleEditor schedule={eventSchedule} onChange={setEventSchedule} />
        </Section>

        {/* 5. Benefits (Makestar style) */}
        <Section title="특전 안내 (Makestar 스타일)" defaultOpen={false}>
          <BenefitsEditor benefits={benefits} onChange={setBenefits} />
        </Section>

        {/* 6. Stretch Goals (Tumblbug style) */}
        <Section title="스트레치 골 (Tumblbug 스타일)" defaultOpen={false}>
          <StretchGoalsEditor
            goals={stretchGoals}
            currentAmountDt={currentAmountDt}
            onChange={setStretchGoals}
          />
        </Section>

        {/* 7. Budget Info */}
        <Section title="예산 정보" defaultOpen={false}>
          <BudgetEditor budget={budgetInfo} onChange={setBudgetInfo} />
        </Section>

        {/* 8. Schedule Info */}
        <Section title="일정 정보" defaultOpen={false}>
          <ScheduleEditor schedule={scheduleInfo} onChange={setScheduleInfo} />
        </Section>

        {/* 9. Team Info */}
        <Section title="팀 소개" defaultOpen={false}>
          <TeamEditor team={teamInfo} onChange={setTeamInfo} />
        </Section>

        {/* 10. Reward Tiers (Enhanced) */}
        <Section title="리워드 티어" defaultOpen={true}>
          <div className="space-y-4">
            <div className="flex justify-end">
              <Button variant="outline" size="sm" onClick={addTier}>
                <Plus className="w-4 h-4 mr-1" />
                리워드 추가
              </Button>
            </div>

            {tiers.length === 0 ? (
              <p className="text-gray-500 text-center py-8">
                아직 리워드가 없습니다. 리워드를 추가해주세요.
              </p>
            ) : (
              <div className="space-y-4">
                {tiers.map((tier) => {
                  const isExpanded = expandedTierId === tier.id

                  return (
                    <div key={tier.id} className="border border-gray-200 rounded-lg overflow-hidden">
                      {/* Tier Header */}
                      <div
                        className="flex items-center gap-3 p-4 bg-gray-50 cursor-pointer hover:bg-gray-100"
                        onClick={() => setExpandedTierId(isExpanded ? null : tier.id)}
                      >
                        <GripVertical className="w-5 h-5 text-gray-400 cursor-grab" />
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-gray-900">{tier.title}</span>
                            <span className="text-sm text-pink-600 font-bold">{tier.price_dt.toLocaleString()}원</span>
                            {tier.badge_type && (
                              <span className="text-xs px-2 py-0.5 bg-pink-100 text-pink-700 rounded-full">
                                {tier.badge_label || tier.badge_type}
                              </span>
                            )}
                          </div>
                          {tier.description && (
                            <p className="text-sm text-gray-500 mt-1 line-clamp-1">{tier.description}</p>
                          )}
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            onClick={(e) => {
                              e.stopPropagation()
                              deleteTier(tier.id)
                            }}
                            className="p-2 text-gray-400 hover:text-red-500 transition-colors"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                          {isExpanded ? (
                            <ChevronUp className="w-5 h-5 text-gray-400" />
                          ) : (
                            <ChevronDown className="w-5 h-5 text-gray-400" />
                          )}
                        </div>
                      </div>

                      {/* Tier Content */}
                      {isExpanded && (
                        <div className="p-4 space-y-4 border-t border-gray-200">
                          {/* Basic Fields */}
                          <div className="grid grid-cols-2 gap-3">
                            <div>
                              <label className="block text-xs text-gray-500 mb-1">리워드 이름 *</label>
                              <input
                                type="text"
                                value={tier.title}
                                onChange={(e) => updateTier(tier.id, { title: e.target.value })}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                                placeholder="리워드 이름"
                              />
                            </div>
                            <div>
                              <label className="block text-xs text-gray-500 mb-1">가격 (원) *</label>
                              <input
                                type="number"
                                value={tier.price_dt}
                                onChange={(e) => updateTier(tier.id, { price_dt: parseInt(e.target.value) || 0 })}
                                className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                                placeholder="가격 (원)"
                                min={1}
                              />
                            </div>
                          </div>

                          <div>
                            <label className="block text-xs text-gray-500 mb-1">설명</label>
                            <textarea
                              value={tier.description || ''}
                              onChange={(e) => updateTier(tier.id, { description: e.target.value })}
                              className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                              placeholder="리워드 설명"
                              rows={2}
                            />
                          </div>

                          <div className="flex items-center gap-4">
                            <label className="flex items-center gap-2">
                              <input
                                type="checkbox"
                                checked={tier.is_featured}
                                onChange={(e) => updateTier(tier.id, { is_featured: e.target.checked })}
                                className="rounded border-gray-300 text-primary-500 focus:ring-primary-500"
                              />
                              <span className="text-sm text-gray-600">추천 리워드</span>
                            </label>
                            <div className="flex items-center gap-2">
                              <span className="text-sm text-gray-600">수량 제한:</span>
                              <input
                                type="number"
                                value={tier.total_quantity || ''}
                                onChange={(e) => {
                                  const val = e.target.value ? parseInt(e.target.value) : null
                                  updateTier(tier.id, {
                                    total_quantity: val,
                                    remaining_quantity: val,
                                  })
                                }}
                                className="w-20 px-2 py-1 border border-gray-200 rounded focus:outline-none focus:ring-2 focus:ring-primary-500"
                                placeholder="무제한"
                                min={1}
                              />
                            </div>
                          </div>

                          {/* Advanced Options */}
                          <div className="pt-4 border-t border-gray-100">
                            <RewardAdvancedEditor
                              tier={tier as unknown as RewardTierEnhanced}
                              onChange={(updates) => updateTier(tier.id, updates as unknown as Partial<RewardTier>)}
                            />
                          </div>
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </Section>

        {/* 11. FAQ */}
        <Section title="자주 묻는 질문" defaultOpen={false}>
          <div className="space-y-4">
            <div className="flex justify-end">
              <Button variant="outline" size="sm" onClick={addFaq}>
                <Plus className="w-4 h-4 mr-1" />
                질문 추가
              </Button>
            </div>

            {faqs.length === 0 ? (
              <p className="text-gray-500 text-center py-8">
                FAQ가 없습니다. 질문을 추가해주세요.
              </p>
            ) : (
              <div className="space-y-4">
                {faqs.map((faq) => (
                  <div key={faq.id} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex items-start gap-3">
                      <GripVertical className="w-5 h-5 text-gray-400 mt-2 cursor-grab" />
                      <div className="flex-1 space-y-3">
                        <input
                          type="text"
                          value={faq.question}
                          onChange={(e) => updateFaq(faq.id, { question: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                          placeholder="질문"
                        />
                        <textarea
                          value={faq.answer}
                          onChange={(e) => updateFaq(faq.id, { answer: e.target.value })}
                          className="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
                          placeholder="답변"
                          rows={2}
                        />
                      </div>
                      <button
                        onClick={() => deleteFaq(faq.id)}
                        className="p-2 text-gray-400 hover:text-red-500 transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </Section>

        {/* 12. Notices */}
        <Section title="유의사항" defaultOpen={false}>
          <NoticesEditor notices={notices} onChange={setNotices} />
        </Section>
      </div>
    </div>
  )
}
