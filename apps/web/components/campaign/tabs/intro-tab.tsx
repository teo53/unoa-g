'use client'

import { useState } from 'react'
import { CampaignEnhanced } from '@/lib/types/database'
import { cn } from '@/lib/utils'
import { sanitizeHtml } from '@/lib/utils/sanitize'
import { FileText, Wallet, Calendar, Users, ChevronRight } from 'lucide-react'

interface IntroTabProps {
  campaign: CampaignEnhanced
}

type SubTab = 'intro' | 'budget' | 'schedule' | 'team'

export function IntroTab({ campaign }: IntroTabProps) {
  const [activeSubTab, setActiveSubTab] = useState<SubTab>('intro')

  const subTabs = [
    { id: 'intro', label: '소개', icon: FileText },
    { id: 'budget', label: '예산', icon: Wallet, disabled: !campaign.budget_info?.items?.length },
    { id: 'schedule', label: '일정', icon: Calendar, disabled: !campaign.schedule_info?.length },
    { id: 'team', label: '팀 소개', icon: Users, disabled: !campaign.team_info?.members?.length },
  ] as const

  return (
    <div className="space-y-6">
      {/* Sub-tab Navigation */}
      <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4">
        {subTabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => !tab.disabled && setActiveSubTab(tab.id)}
            disabled={tab.disabled}
            className={cn(
              'flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all',
              activeSubTab === tab.id
                ? 'bg-pink-500 text-white'
                : tab.disabled
                ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            )}
          >
            <tab.icon className="h-4 w-4" />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Sub-tab Content */}
      <div className="min-h-[400px]">
        {activeSubTab === 'intro' && (
          <IntroContent campaign={campaign} />
        )}
        {activeSubTab === 'budget' && (
          <BudgetContent campaign={campaign} />
        )}
        {activeSubTab === 'schedule' && (
          <ScheduleContent campaign={campaign} />
        )}
        {activeSubTab === 'team' && (
          <TeamContent campaign={campaign} />
        )}
      </div>
    </div>
  )
}

// Intro Content
function IntroContent({ campaign }: { campaign: CampaignEnhanced }) {
  return (
    <div className="space-y-6">
      {/* Main Description */}
      {campaign.description_html ? (
        <div
          className="prose prose-sm max-w-none prose-headings:font-bold prose-headings:text-gray-900 prose-p:text-gray-700 prose-a:text-pink-600"
          dangerouslySetInnerHTML={{ __html: sanitizeHtml(campaign.description_html) }}
        />
      ) : (
        <div className="text-center py-12 text-gray-500">
          캠페인 소개가 준비 중입니다.
        </div>
      )}

      {/* Stretch Goals */}
      {campaign.stretch_goals && campaign.stretch_goals.length > 0 && (
        <div className="bg-gradient-to-r from-purple-50 to-pink-50 rounded-2xl p-6 mt-8">
          <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
            🎯 스트레치 골
          </h3>
          <div className="space-y-4">
            {campaign.stretch_goals.map((goal, index) => {
              const progress = (campaign.current_amount_dt / goal.amount_dt) * 100
              const isReached = campaign.current_amount_dt >= goal.amount_dt || goal.is_reached

              return (
                <div
                  key={index}
                  className={cn(
                    'bg-white rounded-xl p-4 border',
                    isReached ? 'border-green-300' : 'border-gray-200'
                  )}
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-medium text-gray-900">{goal.title}</span>
                    <span className={cn(
                      'text-sm font-bold',
                      isReached ? 'text-green-600' : 'text-gray-500'
                    )}>
                      {goal.amount_dt.toLocaleString()} DT
                      {isReached && ' ✓'}
                    </span>
                  </div>
                  {goal.description && (
                    <p className="text-sm text-gray-600 mb-3">{goal.description}</p>
                  )}
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className={cn(
                        'h-2 rounded-full transition-all',
                        isReached
                          ? 'bg-green-500'
                          : 'bg-gradient-to-r from-purple-400 to-pink-400'
                      )}
                      style={{ width: `${Math.min(progress, 100)}%` }}
                    />
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* Notices */}
      {campaign.notices && campaign.notices.length > 0 && (
        <div className="bg-yellow-50 rounded-2xl p-6 mt-8">
          <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
            ⚠️ 유의사항
          </h3>
          <div className="space-y-4">
            {campaign.notices.map((notice, index) => (
              <div key={index} className="bg-white rounded-xl p-4">
                <h4 className="font-medium text-gray-900 mb-2">{notice.title}</h4>
                <div
                  className="text-sm text-gray-600 prose prose-sm max-w-none"
                  dangerouslySetInnerHTML={{ __html: sanitizeHtml(notice.content_html) }}
                />
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

// Budget Content (Tumblbug style)
function BudgetContent({ campaign }: { campaign: CampaignEnhanced }) {
  const budgetInfo = campaign.budget_info

  if (!budgetInfo?.items?.length) {
    return (
      <div className="text-center py-12 text-gray-500">
        예산 정보가 없습니다.
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="bg-gray-50 rounded-2xl p-6">
        <h3 className="font-bold text-gray-900 mb-4">예산 구성</h3>

        {/* Chart Visualization */}
        <div className="flex gap-1 h-8 rounded-lg overflow-hidden mb-6">
          {budgetInfo.items.map((item, index) => {
            const colors = [
              'bg-pink-500',
              'bg-purple-500',
              'bg-blue-500',
              'bg-green-500',
              'bg-orange-500',
              'bg-cyan-500',
            ]
            return (
              <div
                key={index}
                className={cn(colors[index % colors.length], 'transition-all')}
                style={{ width: `${item.percentage}%` }}
                title={`${item.name}: ${item.percentage}%`}
              />
            )
          })}
        </div>

        {/* Budget Items */}
        <div className="space-y-3">
          {budgetInfo.items.map((item, index) => {
            const colors = [
              'bg-pink-500',
              'bg-purple-500',
              'bg-blue-500',
              'bg-green-500',
              'bg-orange-500',
              'bg-cyan-500',
            ]
            return (
              <div key={index} className="flex items-center justify-between py-2 border-b border-gray-200 last:border-0">
                <div className="flex items-center gap-3">
                  <div className={cn('w-3 h-3 rounded-full', colors[index % colors.length])} />
                  <span className="text-gray-700">{item.name}</span>
                </div>
                <div className="text-right">
                  <span className="font-medium text-gray-900">
                    {item.amount.toLocaleString()} {budgetInfo.currency || 'DT'}
                  </span>
                  <span className="text-gray-500 text-sm ml-2">({item.percentage}%)</span>
                </div>
              </div>
            )
          })}
        </div>

        {/* Total */}
        <div className="mt-4 pt-4 border-t-2 border-gray-300 flex justify-between">
          <span className="font-bold text-gray-900">합계</span>
          <span className="font-bold text-pink-600">
            {budgetInfo.total.toLocaleString()} {budgetInfo.currency || 'DT'}
          </span>
        </div>
      </div>
    </div>
  )
}

// Schedule Content (Timeline)
function ScheduleContent({ campaign }: { campaign: CampaignEnhanced }) {
  const scheduleInfo = campaign.schedule_info

  if (!scheduleInfo?.length) {
    return (
      <div className="text-center py-12 text-gray-500">
        일정 정보가 없습니다.
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="bg-gray-50 rounded-2xl p-6">
        <h3 className="font-bold text-gray-900 mb-6">프로젝트 일정</h3>

        {/* Timeline */}
        <div className="relative">
          {/* Vertical Line */}
          <div className="absolute left-4 top-2 bottom-2 w-0.5 bg-gray-300" />

          <div className="space-y-6">
            {scheduleInfo.map((milestone, index) => (
              <div key={index} className="flex gap-4">
                {/* Dot */}
                <div className={cn(
                  'relative z-10 w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0',
                  milestone.is_completed
                    ? 'bg-green-500 text-white'
                    : 'bg-white border-2 border-gray-300'
                )}>
                  {milestone.is_completed ? (
                    <span className="text-sm">✓</span>
                  ) : (
                    <span className="text-xs text-gray-500">{index + 1}</span>
                  )}
                </div>

                {/* Content */}
                <div className="flex-1 pb-2">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm text-pink-600 font-medium">
                      {new Date(milestone.date).toLocaleDateString('ko-KR', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric'
                      })}
                    </span>
                  </div>
                  <h4 className="font-medium text-gray-900">{milestone.milestone}</h4>
                  {milestone.description && (
                    <p className="text-sm text-gray-600 mt-1">{milestone.description}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

// Team Content
function TeamContent({ campaign }: { campaign: CampaignEnhanced }) {
  const teamInfo = campaign.team_info

  if (!teamInfo?.members?.length) {
    return (
      <div className="text-center py-12 text-gray-500">
        팀 정보가 없습니다.
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Company Info */}
      {teamInfo.company_name && (
        <div className="bg-gradient-to-r from-pink-50 to-purple-50 rounded-2xl p-6">
          <h3 className="font-bold text-gray-900 mb-2">{teamInfo.company_name}</h3>
          {teamInfo.company_description && (
            <p className="text-gray-600">{teamInfo.company_description}</p>
          )}
        </div>
      )}

      {/* Team Members */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {teamInfo.members.map((member, index) => (
          <div
            key={index}
            className="bg-white border border-gray-200 rounded-xl p-4 flex gap-4"
          >
            {/* Avatar */}
            {member.avatar_url ? (
              <img
                src={member.avatar_url}
                alt={member.name}
                className="w-16 h-16 rounded-full object-cover flex-shrink-0"
              />
            ) : (
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-pink-400 to-purple-400 flex items-center justify-center text-white font-bold text-xl flex-shrink-0">
                {member.name.charAt(0)}
              </div>
            )}

            {/* Info */}
            <div className="flex-1 min-w-0">
              <h4 className="font-bold text-gray-900">{member.name}</h4>
              <p className="text-sm text-pink-600 mb-1">{member.role}</p>
              {member.bio && (
                <p className="text-sm text-gray-600 line-clamp-2">{member.bio}</p>
              )}
              {member.links && member.links.length > 0 && (
                <div className="flex gap-2 mt-2">
                  {member.links.map((link, linkIndex) => (
                    <a
                      key={linkIndex}
                      href={link.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-gray-500 hover:text-pink-500 flex items-center gap-1"
                    >
                      {link.type}
                      <ChevronRight className="h-3 w-3" />
                    </a>
                  ))}
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
