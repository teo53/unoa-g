'use client'

import { RewardTierEnhanced } from '@/lib/types/database'
import { RewardCard } from '../reward-card'
import { cn } from '@/lib/utils'

interface RewardsTabProps {
  tiers: RewardTierEnhanced[]
  selectedTier: RewardTierEnhanced | null
  onSelectTier: (tier: RewardTierEnhanced) => void
}

export function RewardsTab({ tiers, selectedTier, onSelectTier }: RewardsTabProps) {
  // Sort tiers by display_order
  const sortedTiers = [...tiers].sort((a, b) => a.display_order - b.display_order)

  // Group by availability
  const availableTiers = sortedTiers.filter(t =>
    t.total_quantity === null || (t.remaining_quantity !== null && t.remaining_quantity > 0)
  )
  const soldOutTiers = sortedTiers.filter(t =>
    t.total_quantity !== null && t.remaining_quantity === 0
  )

  if (tiers.length === 0) {
    return (
      <div className="text-center py-12 text-gray-500">
        리워드 정보가 없습니다.
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Quick Summary */}
      <div className="bg-pink-50 rounded-xl p-4">
        <div className="flex items-center justify-between">
          <span className="text-gray-700">
            총 <span className="font-bold text-pink-600">{tiers.length}개</span> 리워드
          </span>
          <div className="flex gap-4 text-sm">
            <span className="text-green-600">
              구매가능 {availableTiers.length}개
            </span>
            {soldOutTiers.length > 0 && (
              <span className="text-gray-400">
                마감 {soldOutTiers.length}개
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Available Tiers */}
      {availableTiers.length > 0 && (
        <div className="space-y-4">
          <h3 className="font-bold text-gray-900 flex items-center gap-2">
            🎁 선택 가능한 리워드
          </h3>
          <div className="grid grid-cols-1 gap-4">
            {availableTiers.map((tier) => (
              <RewardCard
                key={tier.id}
                tier={tier}
                isSelected={selectedTier?.id === tier.id}
                onSelect={onSelectTier}
              />
            ))}
          </div>
        </div>
      )}

      {/* Sold Out Tiers */}
      {soldOutTiers.length > 0 && (
        <div className="space-y-4">
          <h3 className="font-medium text-gray-500 flex items-center gap-2">
            마감된 리워드
          </h3>
          <div className="grid grid-cols-1 gap-4 opacity-60">
            {soldOutTiers.map((tier) => (
              <RewardCard
                key={tier.id}
                tier={tier}
                isSelected={false}
                disabled
              />
            ))}
          </div>
        </div>
      )}

      {/* Member Selection Info */}
      {tiers.some(t => t.has_member_selection) && (
        <div className="bg-blue-50 rounded-xl p-4 text-sm">
          <p className="text-blue-700">
            <span className="font-medium">💡 멤버 선택 안내:</span> 일부 리워드는 특정 멤버를 선택할 수 있습니다.
            리워드 선택 후 결제 단계에서 원하는 멤버를 선택해주세요.
          </p>
        </div>
      )}
    </div>
  )
}
