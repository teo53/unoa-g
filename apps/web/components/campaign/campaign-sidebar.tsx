'use client'

import { useState } from 'react'
import { CampaignEnhanced, RewardTierEnhanced } from '@/lib/types/database'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Heart, Share2, Bell, Check, ShoppingCart, Gift, Clock, Users } from 'lucide-react'
import { cn } from '@/lib/utils'
import { RewardCard } from './reward-card'

interface CampaignSidebarProps {
  campaign: CampaignEnhanced
  tiers: RewardTierEnhanced[]
  selectedTier: RewardTierEnhanced | null
  onSelectTier: (tier: RewardTierEnhanced) => void
  onPledge: () => void
  className?: string
}

export function CampaignSidebar({
  campaign,
  tiers,
  selectedTier,
  onSelectTier,
  onPledge,
  className
}: CampaignSidebarProps) {
  const [isLiked, setIsLiked] = useState(false)
  const [likeCount, setLikeCount] = useState(campaign.backer_count)

  const isActive = campaign.status === 'active'
  const isCompleted = campaign.status === 'completed'
  const endDate = campaign.end_at ? new Date(campaign.end_at) : null
  const isEnded = endDate ? new Date() > endDate : false

  const progress = campaign.goal_amount_dt > 0
    ? Math.min((campaign.current_amount_dt / campaign.goal_amount_dt) * 100, 100)
    : 0

  const handleLike = () => {
    setIsLiked(!isLiked)
    setLikeCount(prev => isLiked ? prev - 1 : prev + 1)
  }

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: campaign.title,
          text: campaign.subtitle || campaign.title,
          url: window.location.href,
        })
      } catch (error) {
        // User cancelled or error
      }
    } else {
      // Fallback: copy to clipboard
      navigator.clipboard.writeText(window.location.href)
      alert('링크가 복사되었습니다!')
    }
  }

  return (
    <div className={cn('space-y-4', className)}>
      {/* Sticky Purchase Box */}
      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
        {/* Progress Summary */}
        <div className="p-4 bg-gradient-to-r from-pink-50 to-orange-50">
          <div className="flex items-center justify-between mb-2">
            <span className="text-2xl font-bold text-pink-600">
              {Math.round(progress)}%
            </span>
            {progress >= 100 && (
              <Badge className="bg-green-500 text-white">목표 달성!</Badge>
            )}
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2 mb-3">
            <div
              className="bg-gradient-to-r from-pink-500 to-orange-500 h-2 rounded-full transition-all duration-500"
              style={{ width: `${Math.min(progress, 100)}%` }}
            />
          </div>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <p className="text-gray-500">모인 금액</p>
              <p className="font-bold text-gray-900">
                {campaign.current_amount_dt.toLocaleString()} DT
              </p>
            </div>
            <div>
              <p className="text-gray-500">참여자</p>
              <p className="font-bold text-gray-900">
                {campaign.backer_count.toLocaleString()}명
              </p>
            </div>
          </div>
        </div>

        {/* Selected Tier Summary */}
        {selectedTier && (
          <div className="p-4 border-t border-gray-100 bg-pink-50/30">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Check className="h-5 w-5 text-pink-500" />
                <span className="font-medium text-gray-900">{selectedTier.title}</span>
              </div>
              <span className="font-bold text-pink-600">
                {selectedTier.price_dt.toLocaleString()} DT
              </span>
            </div>
          </div>
        )}

        {/* CTA Buttons */}
        <div className="p-4 space-y-3">
          {isActive && !isEnded ? (
            <>
              <Button
                onClick={onPledge}
                disabled={!selectedTier}
                className="w-full h-12 bg-gradient-to-r from-pink-500 to-pink-600 hover:from-pink-600 hover:to-pink-700 text-white font-bold text-base rounded-xl"
              >
                <ShoppingCart className="h-5 w-5 mr-2" />
                {selectedTier ? '후원하기' : '리워드를 선택해주세요'}
              </Button>

              <Button
                variant="outline"
                className="w-full h-10 border-pink-200 text-pink-600 hover:bg-pink-50 rounded-xl"
              >
                <Gift className="h-4 w-4 mr-2" />
                선물하기
              </Button>
            </>
          ) : isCompleted || isEnded ? (
            <div className="text-center py-4">
              <Badge variant="secondary" className="text-base px-4 py-2">
                {isCompleted ? '펀딩 성공!' : '펀딩 종료'}
              </Badge>
              <p className="mt-2 text-sm text-gray-500">
                {isCompleted
                  ? '성공적으로 목표 금액을 달성했습니다.'
                  : '이 캠페인은 종료되었습니다.'}
              </p>
            </div>
          ) : (
            <div className="text-center py-4">
              <Badge variant="outline" className="text-base px-4 py-2">
                <Clock className="h-4 w-4 mr-2" />
                오픈 예정
              </Badge>
              <p className="mt-2 text-sm text-gray-500">
                {campaign.start_at
                  ? `${new Date(campaign.start_at).toLocaleDateString('ko-KR')} 오픈`
                  : '오픈 일정 확인 중'}
              </p>
              <Button
                variant="outline"
                className="w-full mt-3 h-10 border-pink-200 text-pink-600 hover:bg-pink-50 rounded-xl"
              >
                <Bell className="h-4 w-4 mr-2" />
                오픈 알림 받기
              </Button>
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="px-4 pb-4 flex gap-2">
          <Button
            variant="outline"
            onClick={handleLike}
            className={cn(
              'flex-1 h-10 rounded-xl',
              isLiked && 'border-pink-300 bg-pink-50 text-pink-600'
            )}
          >
            <Heart className={cn('h-4 w-4 mr-2', isLiked && 'fill-pink-500 text-pink-500')} />
            {likeCount.toLocaleString()}
          </Button>
          <Button
            variant="outline"
            onClick={handleShare}
            className="flex-1 h-10 rounded-xl"
          >
            <Share2 className="h-4 w-4 mr-2" />
            공유하기
          </Button>
        </div>
      </div>

      {/* Quick Tier Selection */}
      {tiers && tiers.length > 0 && (
      <div className="bg-white rounded-2xl border border-gray-200 shadow-sm p-4">
        <h3 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
          <Gift className="h-5 w-5 text-pink-500" />
          리워드 선택
        </h3>
        <div className="space-y-3 max-h-96 overflow-y-auto">
          {tiers.slice(0, 5).map((tier) => (
            <div
              key={tier.id}
              onClick={() => onSelectTier(tier)}
              className={cn(
                'p-3 rounded-xl border cursor-pointer transition-all',
                selectedTier?.id === tier.id
                  ? 'border-pink-500 bg-pink-50/50 ring-2 ring-pink-200'
                  : 'border-gray-200 hover:border-gray-300'
              )}
            >
              <div className="flex items-center justify-between mb-1">
                <span className="font-bold text-gray-900">
                  {tier.price_dt.toLocaleString()} DT
                </span>
                {tier.badge_type && (
                  <Badge variant="secondary" className="text-xs">
                    {tier.badge_label || tier.badge_type}
                  </Badge>
                )}
              </div>
              <p className="text-sm text-gray-600 line-clamp-1">{tier.title}</p>
              {tier.total_quantity !== null && (
                <p className="text-xs text-gray-400 mt-1">
                  {tier.remaining_quantity === 0 ? (
                    <span className="text-red-500">마감</span>
                  ) : (
                    <>
                      <span className="text-pink-600 font-medium">
                        {tier.remaining_quantity}개
                      </span>
                      {' '}남음
                    </>
                  )}
                </p>
              )}
            </div>
          ))}
        </div>
        {tiers.length > 5 && (
          <Button
            variant="ghost"
            className="w-full mt-3 text-gray-500"
          >
            전체 {tiers.length}개 리워드 보기
          </Button>
        )}
      </div>
      )}

      {/* Creator Info */}
      {campaign.creator && (
        <div className="bg-white rounded-2xl border border-gray-200 shadow-sm p-4">
          <h3 className="font-bold text-gray-900 mb-3 flex items-center gap-2">
            <Users className="h-5 w-5 text-pink-500" />
            크리에이터
          </h3>
          <div className="flex items-center gap-3">
            {campaign.creator.avatar_url ? (
              <img
                src={campaign.creator.avatar_url}
                alt={campaign.creator.display_name || '크리에이터'}
                className="w-12 h-12 rounded-full object-cover"
              />
            ) : (
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-pink-400 to-orange-400 flex items-center justify-center text-white font-bold">
                {(campaign.creator.display_name || 'C').charAt(0)}
              </div>
            )}
            <div className="flex-1">
              <p className="font-medium text-gray-900">
                {campaign.creator.display_name || '크리에이터'}
              </p>
              {campaign.creator.bio && (
                <p className="text-sm text-gray-500 line-clamp-2">
                  {campaign.creator.bio}
                </p>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
