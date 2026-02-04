'use client'

import Link from 'next/link'
import Image from 'next/image'
import { formatDT, formatPercent, formatDaysLeft, formatBackerCount } from '@/lib/utils/format'
import { cn } from '@/lib/utils/cn'

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
      href={`/p/${campaign.slug}`}
      className={cn(
        'group block bg-white rounded-2xl overflow-hidden shadow-sm hover:shadow-lg transition-all duration-300',
        className
      )}
    >
      {/* Cover Image */}
      <div className="relative aspect-[16/9] overflow-hidden bg-gray-100">
        {campaign.cover_image_url ? (
          <Image
            src={campaign.cover_image_url}
            alt={campaign.title}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-gray-400">
            <svg className="w-12 h-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
        )}

        {/* Status Badge */}
        {campaign.status === 'completed' && (
          <div className="absolute top-3 left-3 px-2 py-1 bg-gray-900/80 text-white text-xs font-medium rounded">
            마감
          </div>
        )}

        {/* Category */}
        {campaign.category && (
          <div className="absolute top-3 right-3 px-2 py-1 bg-white/90 text-gray-700 text-xs font-medium rounded">
            {campaign.category}
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Title */}
        <h3 className="font-semibold text-gray-900 line-clamp-2 mb-1 group-hover:text-primary-500 transition-colors">
          {campaign.title}
        </h3>

        {/* Subtitle */}
        {campaign.subtitle && (
          <p className="text-sm text-gray-500 line-clamp-1 mb-3">
            {campaign.subtitle}
          </p>
        )}

        {/* Progress Bar */}
        <div className="mb-3">
          <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-primary-500 rounded-full transition-all duration-500"
              style={{ width: `${Math.min(percent, 100)}%` }}
            />
          </div>
        </div>

        {/* Stats */}
        <div className="flex items-center justify-between text-sm">
          <div>
            <span className="font-bold text-primary-500">{percent}%</span>
            <span className="text-gray-500 ml-1">달성</span>
          </div>
          <div className="text-gray-500">
            {formatDT(campaign.current_amount_dt)}
          </div>
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between mt-3 pt-3 border-t border-gray-100 text-sm text-gray-500">
          <span>{formatBackerCount(campaign.backer_count)} 후원</span>
          {daysLeft && (
            <span className={cn(
              daysLeft.includes('마감') ? 'text-gray-400' : 'text-primary-500 font-medium'
            )}>
              {daysLeft}
            </span>
          )}
        </div>
      </div>
    </Link>
  )
}
