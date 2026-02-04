'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { ArrowLeft, CheckCircle, XCircle, Send } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { formatDT } from '@/lib/utils/format'
import { DEMO_MODE, getCampaignById, getTiersByCampaignId } from '@/lib/mock/demo-data'

interface SubmitFormProps {
  id: string
}

interface Campaign {
  id: string
  title: string
  cover_image_url?: string | null
  description_md?: string | null
  goal_amount_dt: number
  end_at?: string | null
  status: string
}

interface RewardTier {
  id: string
  title: string
  price_dt: number
  is_active: boolean
}

interface ValidationItem {
  label: string
  isValid: boolean
  message?: string
}

export default function SubmitForm({ id }: SubmitFormProps) {
  const router = useRouter()

  const [campaign, setCampaign] = useState<Campaign | null>(null)
  const [tiers, setTiers] = useState<RewardTier[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function loadCampaign() {
      // Demo mode
      if (DEMO_MODE) {
        const campaignData = getCampaignById(id)
        if (campaignData) {
          setCampaign(campaignData as Campaign)
          setTiers(getTiersByCampaignId(id) as RewardTier[])
        }
        setIsLoading(false)
        return
      }

      // Production mode
      const { createClient } = await import('@/lib/supabase/client')
      const supabase = createClient()

      const { data: campaignData } = await supabase
        .from('funding_campaigns')
        .select('*')
        .eq('id', id)
        .single()

      if (campaignData) {
        setCampaign(campaignData as Campaign)
      }

      const { data: tiersData } = await supabase
        .from('funding_reward_tiers')
        .select('*')
        .eq('campaign_id', id)
        .eq('is_active', true)

      setTiers((tiersData || []) as RewardTier[])
      setIsLoading(false)
    }

    loadCampaign()
  }, [id])

  const validations: ValidationItem[] = campaign ? [
    {
      label: '캠페인 제목',
      isValid: !!campaign.title && campaign.title.length >= 5,
      message: campaign.title && campaign.title.length >= 5 ? campaign.title : '최소 5자 이상',
    },
    {
      label: '커버 이미지',
      isValid: !!campaign.cover_image_url,
      message: campaign.cover_image_url ? '설정됨' : '필수 항목',
    },
    {
      label: '프로젝트 소개',
      isValid: !!campaign.description_md && campaign.description_md.length >= 100,
      message: campaign.description_md && campaign.description_md.length >= 100
        ? `${campaign.description_md.length}자`
        : '최소 100자 이상',
    },
    {
      label: '목표 금액',
      isValid: campaign.goal_amount_dt >= 100,
      message: formatDT(campaign.goal_amount_dt),
    },
    {
      label: '종료일',
      isValid: !!campaign.end_at && new Date(campaign.end_at) > new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      message: campaign.end_at
        ? new Date(campaign.end_at).toLocaleDateString()
        : '최소 7일 후',
    },
    {
      label: '리워드 티어',
      isValid: tiers.length > 0,
      message: tiers.length > 0 ? `${tiers.length}개 등록됨` : '최소 1개 필요',
    },
  ] : []

  const allValid = validations.every((v) => v.isValid)

  const handleSubmit = async () => {
    if (!allValid) return

    setIsSubmitting(true)
    setError(null)

    try {
      // Demo mode: just simulate success
      if (DEMO_MODE) {
        await new Promise(resolve => setTimeout(resolve, 1000))
        router.push('/studio')
        return
      }

      const { createClient } = await import('@/lib/supabase/client')
      const supabase = createClient()

      const { data: { session } } = await supabase.auth.getSession()
      if (!session) throw new Error('로그인이 필요합니다')

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/funding-studio-submit`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ campaignId: id }),
        }
      )

      const result = await response.json()

      if (!result.success) {
        throw new Error(result.error || '제출에 실패했습니다')
      }

      router.push('/studio')
    } catch (err) {
      setError(err instanceof Error ? err.message : '제출에 실패했습니다')
    } finally {
      setIsSubmitting(false)
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-primary-500 border-t-transparent" />
      </div>
    )
  }

  if (!campaign) {
    return (
      <div className="max-w-2xl mx-auto text-center py-12">
        <p className="text-red-500 mb-4">캠페인을 찾을 수 없습니다</p>
        <Link href="/studio">
          <Button variant="outline">대시보드로 돌아가기</Button>
        </Link>
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto">
      {/* Demo Banner */}
      {DEMO_MODE && (
        <div className="mb-4 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 text-sm text-amber-800">
          Demo Mode - Mock data is displayed
        </div>
      )}

      {/* Header */}
      <div className="flex items-center gap-4 mb-8">
        <Link href={`/studio/campaigns/${id}/edit`} className="text-gray-500 hover:text-gray-700">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">캠페인 제출</h1>
          <p className="text-gray-500 mt-1">심사를 위해 캠페인을 제출합니다</p>
        </div>
      </div>

      {/* Validation Checklist */}
      <div className="bg-white rounded-xl p-6 border border-gray-100 mb-6">
        <h2 className="text-lg font-semibold mb-4">제출 전 확인</h2>
        <div className="space-y-3">
          {validations.map((item) => (
            <div key={item.label} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
              <div className="flex items-center gap-3">
                {item.isValid ? (
                  <CheckCircle className="w-5 h-5 text-green-500" />
                ) : (
                  <XCircle className="w-5 h-5 text-red-500" />
                )}
                <span className="text-gray-700">{item.label}</span>
              </div>
              <span className={item.isValid ? 'text-gray-500' : 'text-red-500'}>
                {item.message}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Notice */}
      <div className="bg-yellow-50 rounded-xl p-4 mb-6">
        <h3 className="font-medium text-yellow-800 mb-2">제출 전 안내</h3>
        <ul className="text-sm text-yellow-700 space-y-1">
          <li>• 제출 후에는 목표 금액을 변경할 수 없습니다</li>
          <li>• 심사는 영업일 기준 1-3일 소요됩니다</li>
          <li>• 반려 시 수정 후 재제출이 가능합니다</li>
        </ul>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-100 rounded-xl p-4 mb-6 text-red-600">
          {error}
        </div>
      )}

      {/* Actions */}
      <div className="flex justify-end gap-3">
        <Link href={`/studio/campaigns/${id}/edit`}>
          <Button variant="outline">수정하기</Button>
        </Link>
        <Button onClick={handleSubmit} disabled={!allValid} loading={isSubmitting}>
          <Send className="w-4 h-4 mr-2" />
          심사 요청
        </Button>
      </div>
    </div>
  )
}
