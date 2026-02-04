'use client'

import { CampaignEnhanced } from '@/lib/types/database'
import { Progress } from '@/components/ui/progress'
import { differenceInDays, differenceInHours, isPast, parseISO } from 'date-fns'

interface CampaignMetricsProps {
  campaign: CampaignEnhanced
}

export function CampaignMetrics({ campaign }: CampaignMetricsProps) {
  const percentage = Math.min(
    Math.round((campaign.current_amount_dt / campaign.goal_amount_dt) * 100),
    100
  )

  const getTimeRemaining = () => {
    if (!campaign.end_at) return null

    const endDate = parseISO(campaign.end_at)
    if (isPast(endDate)) return '종료됨'

    const daysLeft = differenceInDays(endDate, new Date())
    if (daysLeft > 0) return `${daysLeft}일 남음`

    const hoursLeft = differenceInHours(endDate, new Date())
    if (hoursLeft > 0) return `${hoursLeft}시간 남음`

    return '곧 종료'
  }

  const timeRemaining = getTimeRemaining()

  const formatAmount = (amount: number) => {
    if (amount >= 10000) {
      return `${(amount / 10000).toFixed(0)}만`
    }
    return amount.toLocaleString()
  }

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-6 space-y-4">
      {/* Progress Bar */}
      <div className="space-y-2">
        <Progress value={percentage} className="h-3" />
        <div className="flex justify-between text-sm">
          <span className="text-pink-600 font-bold text-xl">
            {percentage}%
          </span>
          {percentage >= 100 && (
            <span className="text-green-600 font-medium">
              목표 달성! 🎉
            </span>
          )}
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-3 gap-4 pt-2">
        {/* Amount Raised */}
        <div className="text-center p-3 bg-gray-50 rounded-lg">
          <p className="text-2xl font-bold text-gray-900">
            {formatAmount(campaign.current_amount_dt)}
          </p>
          <p className="text-xs text-gray-500 mt-1">모인 금액 (DT)</p>
        </div>

        {/* Backers */}
        <div className="text-center p-3 bg-gray-50 rounded-lg">
          <p className="text-2xl font-bold text-gray-900">
            {campaign.backer_count.toLocaleString()}
          </p>
          <p className="text-xs text-gray-500 mt-1">서포터</p>
        </div>

        {/* Time Remaining */}
        <div className="text-center p-3 bg-gray-50 rounded-lg">
          <p className="text-2xl font-bold text-gray-900">
            {timeRemaining || '-'}
          </p>
          <p className="text-xs text-gray-500 mt-1">
            {campaign.status === 'completed' ? '펀딩 종료' : '남은 시간'}
          </p>
        </div>
      </div>

      {/* Goal Amount */}
      <div className="pt-2 border-t border-gray-100">
        <div className="flex justify-between text-sm">
          <span className="text-gray-500">목표 금액</span>
          <span className="font-medium text-gray-900">
            {campaign.goal_amount_dt.toLocaleString()} DT
          </span>
        </div>
      </div>
    </div>
  )
}
