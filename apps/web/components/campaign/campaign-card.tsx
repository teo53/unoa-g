'use client'

import Link from 'next/link'
import Image from 'next/image'
import { formatFundingAmount, formatPercent, formatDaysLeft, formatBackerCount } from '@/lib/utils/format'
import { cn } from '@/lib/utils/cn'
import { ROUTES } from '@/lib/constants/routes'

// Flexible campaign type for both production and demo data
interface CampaignCardData {
  id: string
  slug: string
  title: string
  subtitle?: string | null
  cover_image_url?: string | null
  category?: string | null
  status: string
  goal_amount_dt: number
  current_amount_dt: number
  backer_count: number
  end_at?: string | null
  creator?: {
    id: string
    display_name: string
    avatar_url?: string | null
  } | null
}

interface CampaignCardProps {
  campaign: CampaignCardData
  className?: string
}

export function CampaignCard({ campaign, className }: CampaignCardProps) {
  const percent = formatPercent(campaign.current_amount_dt, campaign.goal_amount_dt)
  const daysLeft = campaign.end_at ? formatDaysLeft(campaign.end_at) : null

  return (
    <Link
      href={ROUTES.campaign(campaign.slug)}
      className={cn(
        'group block rounded-2xl overflow-hidden border border-neutral-100 bg-white transition-all duration-300',
        'hover:shadow-lg hover:border-neutral-200 hover:-translate-y-0.5',
        className
      )}
    >
      {/* Cover Image */}
      <div className="relative aspect-[16/9] overflow-hidden bg-neutral-50">
        {campaign.cover_image_url ? (
          <Image
            src={campaign.cover_image_url}
            alt={campaign.title}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-500"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-neutral-300">
            <svg className="w-12 h-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
        )}

        {/* Status Badge */}
        {campaign.status === 'completed' && (
          <div className="absolute top-3 left-3 px-2.5 py-1 bg-neutral-900/80 text-white text-xs font-medium rounded-md backdrop-blur-sm">
            마감
          </div>
        )}

        {/* Category */}
        {campaign.category && (
          <div className="absolute top-3 right-3 px-2.5 py-1 bg-white/90 text-neutral-600 text-xs font-medium rounded-md backdrop-blur-sm">
            {campaign.category}
          </div>
        )}

        {/* Days Left Overlay (if ending soon) */}
        {daysLeft && !daysLeft.includes('마감') && parseInt(daysLeft) <= 3 && (
          <div className="absolute bottom-3 right-3 px-2.5 py-1 bg-brand-500/90 text-white text-xs font-bold rounded-md backdrop-blur-sm">
            {daysLeft}
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Creator Info */}
        {campaign.creator && (
          <div className="flex items-center gap-2 mb-2">
            <div className="relative w-5 h-5 rounded-full overflow-hidden bg-neutral-100 flex-shrink-0">
              {campaign.creator.avatar_url ? (
                <Image
                  src={campaign.creator.avatar_url}
                  alt={campaign.creator.display_name}
                  fill
                  className="object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center text-neutral-400 text-[10px] font-bold">
                  {campaign.creator.display_name.charAt(0)}
                </div>
              )}
            </div>
            <span className="text-xs text-neutral-500 truncate">{campaign.creator.display_name}</span>
          </div>
        )}

        {/* Title */}
        <h3 className="font-semibold text-neutral-900 line-clamp-2 mb-1 group-hover:text-brand-500 transition-colors text-sm leading-snug">
          {campaign.title}
        </h3>

        {/* Subtitle */}
        {campaign.subtitle && (
          <p className="text-xs text-neutral-400 line-clamp-1 mb-3">
            {campaign.subtitle}
          </p>
        )}

        {/* Progress Bar */}
        <div className="mb-2">
          <div className="h-1.5 bg-neutral-100 rounded-full overflow-hidden">
            <div
              className={cn(
                'h-full rounded-full transition-all duration-500',
                percent >= 100 ? 'bg-semantic-success' : 'bg-brand-500'
              )}
              style={{ width: `${Math.min(percent, 100)}%` }}
            />
          </div>
        </div>

        {/* Funding Amount */}
        <div className="flex items-baseline gap-1 mb-1">
          <span className="text-sm font-bold text-neutral-900">
            {formatFundingAmount(campaign.current_amount_dt)}
          </span>
          <span className="text-xs text-neutral-400">
            / {formatFundingAmount(campaign.goal_amount_dt)} 목표
          </span>
        </div>

        {/* Stats */}
        <div className="flex items-center justify-between text-xs text-neutral-500">
          <div className="flex items-center gap-3">
            <span className={cn(
              'font-bold',
              percent >= 100 ? 'text-semantic-success' : 'text-brand-500'
            )}>
              {percent}% 달성
            </span>
            <span>{formatBackerCount(campaign.backer_count)} 후원</span>
          </div>
          {daysLeft && (
            <span className={cn(
              daysLeft.includes('마감') ? 'text-neutral-400' : 'text-neutral-600 font-medium'
            )}>
              {daysLeft}
            </span>
          )}
        </div>
      </div>
    </Link>
  )
}
