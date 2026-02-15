'use client'

import { useState, useEffect, useCallback } from 'react'
import Image from 'next/image'
import { RewardTierEnhanced } from '@/lib/types/database'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Check, Users, Package, Truck, AlertCircle, Bell, BellOff, Loader2 } from 'lucide-react'
import { cn } from '@/lib/utils'
import { createClient } from '@/lib/supabase/client'

interface RewardCardProps {
  tier: RewardTierEnhanced
  onSelect?: (tier: RewardTierEnhanced) => void
  isSelected?: boolean
  disabled?: boolean
}

export function RewardCard({ tier, onSelect, isSelected, disabled }: RewardCardProps) {
  const isSoldOut = tier.total_quantity !== null && tier.remaining_quantity === 0
  const isLimited = tier.total_quantity !== null && tier.remaining_quantity !== null
  const isClickable = !isSoldOut && !disabled && onSelect

  // Waitlist state
  const [isOnWaitlist, setIsOnWaitlist] = useState(false)
  const [waitlistLoading, setWaitlistLoading] = useState(false)

  // Check if user is already on waitlist
  useEffect(() => {
    if (!isSoldOut) return

    const checkWaitlist = async () => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return

      const { data } = await supabase
        .from('funding_tier_waitlist')
        .select('id')
        .eq('tier_id', tier.id)
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle()

      setIsOnWaitlist(!!data)
    }

    checkWaitlist()
  }, [isSoldOut, tier.id])

  const handleWaitlistToggle = useCallback(async (e: React.MouseEvent) => {
    e.stopPropagation()
    setWaitlistLoading(true)

    try {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()

      if (!user) {
        alert('로그인이 필요합니다.')
        return
      }

      if (isOnWaitlist) {
        // Cancel waitlist
        await supabase
          .from('funding_tier_waitlist')
          .update({ is_active: false })
          .eq('tier_id', tier.id)
          .eq('user_id', user.id)
          .eq('is_active', true)

        setIsOnWaitlist(false)
      } else {
        // Join waitlist
        await supabase
          .from('funding_tier_waitlist')
          .insert({
            tier_id: tier.id,
            campaign_id: tier.campaign_id,
            user_id: user.id,
          })

        setIsOnWaitlist(true)
      }
    } catch {
      alert('처리 중 오류가 발생했습니다. 다시 시도해주세요.')
    } finally {
      setWaitlistLoading(false)
    }
  }, [isOnWaitlist, tier.id, tier.campaign_id])

  const getBadgeConfig = () => {
    if (!tier.badge_type) return null

    const configs: Record<string, { label: string; className: string }> = {
      recommended: { label: tier.badge_label || '추천', className: 'bg-pink-500 text-white' },
      limited: { label: tier.badge_label || '한정', className: 'bg-orange-500 text-white' },
      early_bird: { label: tier.badge_label || '얼리버드', className: 'bg-blue-500 text-white' },
      best: { label: tier.badge_label || 'BEST', className: 'bg-purple-500 text-white' },
      new: { label: tier.badge_label || 'NEW', className: 'bg-green-500 text-white' },
    }

    return configs[tier.badge_type] || null
  }

  const badgeConfig = getBadgeConfig()

  return (
    <div
      className={cn(
        'relative border rounded-xl overflow-hidden transition-all',
        isSelected
          ? 'border-pink-500 ring-2 ring-pink-200 bg-pink-50/50'
          : 'border-gray-200 bg-white hover:border-gray-300',
        isSoldOut && 'opacity-60',
        isClickable && 'cursor-pointer'
      )}
      onClick={() => isClickable && onSelect(tier)}
    >
      {/* Badge */}
      {badgeConfig && (
        <div className="absolute top-0 left-0 z-10">
          <Badge className={cn('rounded-none rounded-br-lg', badgeConfig.className)}>
            {badgeConfig.label}
          </Badge>
        </div>
      )}

      {/* Sold Out Overlay */}
      {isSoldOut && (
        <div className="absolute inset-0 bg-white/60 z-5 flex items-center justify-center">
          <Badge variant="secondary" className="bg-gray-800 text-white text-sm px-4 py-1">
            마감
          </Badge>
        </div>
      )}

      <div className="p-4 space-y-3">
        {/* Price */}
        <div className="flex items-baseline justify-between">
          <span className="text-2xl font-bold text-gray-900">
            {tier.price_dt.toLocaleString()}
            <span className="text-sm font-normal text-gray-500 ml-1">DT</span>
          </span>
          {isSelected && (
            <div className="h-6 w-6 rounded-full bg-pink-500 flex items-center justify-center">
              <Check className="h-4 w-4 text-white" />
            </div>
          )}
        </div>

        {/* Title */}
        <h4 className="font-bold text-gray-900">{tier.title}</h4>

        {/* Description */}
        {tier.description && (
          <p className="text-sm text-gray-600">{tier.description}</p>
        )}

        {/* Included Items */}
        {tier.included_items && tier.included_items.length > 0 && (
          <div className="space-y-1.5 pt-2 border-t border-gray-100">
            <p className="text-xs font-medium text-gray-500 flex items-center gap-1">
              <Package className="h-3 w-3" />
              포함 구성
            </p>
            <ul className="space-y-1">
              {tier.included_items.map((item, index) => (
                <li key={index} className="text-sm text-gray-700 flex items-start gap-2">
                  <Check className="h-4 w-4 text-green-500 flex-shrink-0 mt-0.5" />
                  <span>
                    {item.name}
                    {item.quantity > 1 && (
                      <span className="text-gray-500"> x{item.quantity}</span>
                    )}
                    {item.description && (
                      <span className="text-gray-400 text-xs block">{item.description}</span>
                    )}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Member Selection Indicator */}
        {tier.has_member_selection && tier.member_options && tier.member_options.length > 0 && (
          <div className="pt-2 border-t border-gray-100">
            <p className="text-xs font-medium text-gray-500 flex items-center gap-1 mb-2">
              <Users className="h-3 w-3" />
              멤버 선택 가능
            </p>
            <div className="flex gap-1 flex-wrap">
              {tier.member_options.slice(0, 6).map((member) => (
                <div
                  key={member.member_id}
                  className="relative w-8 h-8 rounded-full overflow-hidden bg-gray-100"
                  title={member.member_name}
                >
                  {member.avatar_url ? (
                    <Image
                      src={member.avatar_url}
                      alt={member.member_name}
                      fill
                      className="object-cover"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-xs text-gray-500">
                      {member.member_name.charAt(0)}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Quantity Info */}
        <div className="pt-2 flex items-center justify-between text-sm">
          {isLimited ? (
            <div className="flex items-center gap-1 text-gray-500">
              <AlertCircle className="h-3.5 w-3.5" />
              <span>
                {isSoldOut ? (
                  '마감'
                ) : (
                  <>
                    <span className="text-pink-600 font-medium">
                      {tier.remaining_quantity}개
                    </span>{' '}
                    남음
                  </>
                )}
              </span>
            </div>
          ) : (
            <span className="text-gray-400 text-xs">수량 제한 없음</span>
          )}

          <div className="text-gray-400 text-xs flex items-center gap-1">
            <Users className="h-3 w-3" />
            {tier.pledge_count}명 참여
          </div>
        </div>

        {/* Shipping Info */}
        {tier.shipping_info && (
          <div className="text-xs text-gray-500 flex items-center gap-1 pt-1">
            <Truck className="h-3 w-3" />
            {tier.shipping_info}
          </div>
        )}

        {/* Waitlist Button for Sold Out */}
        {isSoldOut && (
          <Button
            variant={isOnWaitlist ? 'default' : 'outline'}
            size="sm"
            className={cn(
              'w-full mt-2',
              isOnWaitlist && 'bg-pink-500 hover:bg-pink-600 text-white'
            )}
            disabled={waitlistLoading}
            onClick={handleWaitlistToggle}
          >
            {waitlistLoading ? (
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            ) : isOnWaitlist ? (
              <BellOff className="h-4 w-4 mr-2" />
            ) : (
              <Bell className="h-4 w-4 mr-2" />
            )}
            {isOnWaitlist ? '알림 취소' : '빈자리 알림 받기'}
          </Button>
        )}
      </div>
    </div>
  )
}
