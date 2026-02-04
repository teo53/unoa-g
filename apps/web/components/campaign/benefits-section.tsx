'use client'

import { useState } from 'react'
import Image from 'next/image'
import { Benefit } from '@/lib/types/database'
import { Gift, ChevronDown, ChevronUp } from 'lucide-react'
import { Badge } from '@/components/ui/badge'

interface BenefitsSectionProps {
  benefits: Benefit[]
  className?: string
}

export function BenefitsSection({ benefits, className = '' }: BenefitsSectionProps) {
  const [expandedIndex, setExpandedIndex] = useState<number | null>(0)

  if (benefits.length === 0) return null

  const forTypeLabels: Record<string, { label: string; color: string }> = {
    all: { label: '전원', color: 'bg-blue-100 text-blue-700' },
    winner: { label: '당첨자', color: 'bg-yellow-100 text-yellow-700' },
    fansign: { label: '팬사인회', color: 'bg-pink-100 text-pink-700' },
    videocall: { label: '영상통화', color: 'bg-purple-100 text-purple-700' },
  }

  return (
    <div className={`bg-white rounded-xl border border-gray-200 overflow-hidden ${className}`}>
      <div className="px-4 py-3 bg-gradient-to-r from-pink-50 to-purple-50 border-b border-gray-100">
        <h3 className="font-bold text-gray-900 flex items-center gap-2">
          <Gift className="h-4 w-4 text-pink-500" />
          특전 안내
        </h3>
      </div>

      <div className="divide-y divide-gray-100">
        {benefits.map((benefit, index) => {
          const isExpanded = expandedIndex === index
          const typeInfo = forTypeLabels[benefit.for_type] || forTypeLabels.all

          return (
            <div key={index} className="overflow-hidden">
              {/* Header - Clickable */}
              <button
                onClick={() => setExpandedIndex(isExpanded ? null : index)}
                className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <Badge className={`${typeInfo.color} text-xs font-medium`}>
                    {typeInfo.label}
                  </Badge>
                  <span className="font-medium text-gray-900 text-left">
                    {benefit.title}
                  </span>
                </div>
                {isExpanded ? (
                  <ChevronUp className="h-4 w-4 text-gray-400" />
                ) : (
                  <ChevronDown className="h-4 w-4 text-gray-400" />
                )}
              </button>

              {/* Content - Expandable */}
              {isExpanded && (
                <div className="px-4 pb-4 space-y-3">
                  {/* Description */}
                  <p className="text-sm text-gray-600 whitespace-pre-line pl-2 border-l-2 border-pink-200">
                    {benefit.description}
                  </p>

                  {/* Images */}
                  {benefit.images && benefit.images.length > 0 && (
                    <div className="flex gap-2 overflow-x-auto pb-2">
                      {benefit.images.map((imageUrl, imgIndex) => (
                        <div
                          key={imgIndex}
                          className="relative flex-shrink-0 w-24 h-24 rounded-lg overflow-hidden"
                        >
                          <Image
                            src={imageUrl}
                            alt={`${benefit.title} 이미지 ${imgIndex + 1}`}
                            fill
                            className="object-cover"
                          />
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}
