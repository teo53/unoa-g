'use client'

import Image from 'next/image'
import Link from 'next/link'
import { CampaignEnhanced } from '@/lib/types/database'
import { Badge } from '@/components/ui/badge'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { formatDistanceToNow } from 'date-fns'
import { ko } from 'date-fns/locale'

interface CampaignHeaderProps {
  campaign: CampaignEnhanced
}

export function CampaignHeader({ campaign }: CampaignHeaderProps) {
  const categoryLabels: Record<string, string> = {
    'K-POP': 'K-POP',
    'concert': '콘서트',
    'goods': '굿즈',
    'music': '음악',
    'event': '이벤트',
  }

  return (
    <div className="space-y-4">
      {/* Category Badge */}
      {campaign.category && (
        <div className="flex items-center gap-2">
          <Badge variant="secondary" className="bg-pink-100 text-pink-700 hover:bg-pink-100">
            {categoryLabels[campaign.category] || campaign.category}
          </Badge>
          {campaign.status === 'active' && (
            <Badge variant="default" className="bg-green-500 hover:bg-green-500">
              진행중
            </Badge>
          )}
          {campaign.status === 'completed' && (
            <Badge variant="secondary" className="bg-gray-500 text-white hover:bg-gray-500">
              종료
            </Badge>
          )}
        </div>
      )}

      {/* Title */}
      <h1 className="text-2xl md:text-3xl font-bold text-gray-900 leading-tight">
        {campaign.title}
      </h1>

      {/* Subtitle */}
      {campaign.subtitle && (
        <p className="text-gray-600 text-lg">
          {campaign.subtitle}
        </p>
      )}

      {/* Creator Info */}
      {campaign.creator && (
        <div className="flex items-center gap-3 pt-2">
          <Avatar className="h-10 w-10">
            <AvatarImage src={campaign.creator.avatar_url || undefined} alt={campaign.creator.display_name || ''} />
            <AvatarFallback className="bg-pink-100 text-pink-600">
              {campaign.creator.display_name?.charAt(0) || '?'}
            </AvatarFallback>
          </Avatar>
          <div>
            <p className="font-medium text-gray-900">
              {campaign.creator.display_name}
            </p>
            <p className="text-sm text-gray-500">
              크리에이터
            </p>
          </div>
        </div>
      )}
    </div>
  )
}
