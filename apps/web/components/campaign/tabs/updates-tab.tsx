'use client'

import { CampaignUpdate } from '@/lib/types/database'
import { Badge } from '@/components/ui/badge'
import { Eye, Lock, Calendar, Bell } from 'lucide-react'
import { cn } from '@/lib/utils'

interface UpdatesTabProps {
  updates: CampaignUpdate[]
  isBackerOnly?: boolean
}

export function UpdatesTab({ updates, isBackerOnly = false }: UpdatesTabProps) {
  if (updates.length === 0) {
    return (
      <div className="text-center py-12">
        <Bell className="h-12 w-12 text-gray-300 mx-auto mb-4" />
        <p className="text-gray-500">아직 새소식이 없습니다.</p>
        <p className="text-sm text-gray-400 mt-1">
          새로운 소식이 올라오면 알려드릴게요!
        </p>
      </div>
    )
  }

  const sortedUpdates = [...updates].sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  )

  const getUpdateTypeBadge = (type: CampaignUpdate['update_type']) => {
    const configs: Record<string, { label: string; className: string }> = {
      general: { label: '일반', className: 'bg-gray-100 text-gray-700' },
      milestone: { label: '마일스톤', className: 'bg-purple-100 text-purple-700' },
      shipping: { label: '배송', className: 'bg-blue-100 text-blue-700' },
      schedule_change: { label: '일정변경', className: 'bg-orange-100 text-orange-700' },
      goal_reached: { label: '목표달성', className: 'bg-green-100 text-green-700' },
    }
    return configs[type] || configs.general
  }

  return (
    <div className="space-y-4">
      {sortedUpdates.map((update, index) => {
        const typeBadge = getUpdateTypeBadge(update.update_type)
        const isLocked = update.visibility !== 'public' && !isBackerOnly

        return (
          <article
            key={update.id}
            className={cn(
              'bg-white border border-gray-200 rounded-xl overflow-hidden',
              isLocked && 'opacity-75'
            )}
          >
            {/* Header */}
            <div className="p-4 border-b border-gray-100">
              <div className="flex items-start justify-between mb-2">
                <div className="flex items-center gap-2 flex-wrap">
                  <Badge className={cn('text-xs', typeBadge.className)}>
                    {typeBadge.label}
                  </Badge>
                  {update.visibility === 'backers_only' && (
                    <Badge variant="outline" className="text-xs border-pink-300 text-pink-600">
                      <Lock className="h-3 w-3 mr-1" />
                      후원자 전용
                    </Badge>
                  )}
                </div>
                <div className="flex items-center gap-1 text-xs text-gray-400">
                  <Calendar className="h-3 w-3" />
                  {new Date(update.created_at).toLocaleDateString('ko-KR', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  })}
                </div>
              </div>
              <h3 className="font-bold text-gray-900">{update.title}</h3>
            </div>

            {/* Content */}
            {isLocked ? (
              <div className="p-6 text-center bg-gray-50">
                <Lock className="h-8 w-8 text-gray-300 mx-auto mb-2" />
                <p className="text-gray-500 text-sm">
                  후원자만 볼 수 있는 콘텐츠입니다.
                </p>
              </div>
            ) : (
              <div className="p-4">
                <div
                  className="prose prose-sm max-w-none prose-headings:font-bold prose-headings:text-gray-900 prose-p:text-gray-700"
                  dangerouslySetInnerHTML={{ __html: update.content_html }}
                />
              </div>
            )}

            {/* Footer */}
            <div className="px-4 py-2 bg-gray-50 flex items-center justify-between text-sm text-gray-500">
              <div className="flex items-center gap-1">
                <Eye className="h-4 w-4" />
                <span>{update.view_count.toLocaleString()} 조회</span>
              </div>
              {index === 0 && (
                <Badge variant="secondary" className="text-xs">
                  최신
                </Badge>
              )}
            </div>
          </article>
        )
      })}
    </div>
  )
}
