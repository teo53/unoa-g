'use client'

import { useState } from 'react'
import { Benefit } from '@/lib/types/database'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { ImageUploader } from '@/components/ui/image-uploader'
import { Plus, Trash2, Gift, ChevronDown, ChevronUp } from 'lucide-react'

interface BenefitsEditorProps {
  benefits: Benefit[]
  onChange: (benefits: Benefit[]) => void
}

const FOR_TYPES = [
  { value: 'all', label: '전원', color: 'bg-blue-100 text-blue-700' },
  { value: 'winner', label: '당첨자', color: 'bg-yellow-100 text-yellow-700' },
  { value: 'fansign', label: '팬사인회', color: 'bg-pink-100 text-pink-700' },
  { value: 'videocall', label: '영상통화', color: 'bg-purple-100 text-purple-700' },
] as const

export function BenefitsEditor({ benefits, onChange }: BenefitsEditorProps) {
  const [expandedIndex, setExpandedIndex] = useState<number | null>(0)

  const addBenefit = () => {
    const newBenefit: Benefit = {
      title: '',
      description: '',
      images: [],
      for_type: 'all'
    }
    onChange([...benefits, newBenefit])
    setExpandedIndex(benefits.length)
  }

  const updateBenefit = (index: number, field: keyof Benefit, value: any) => {
    const updated = [...benefits]
    updated[index] = { ...updated[index], [field]: value }
    onChange(updated)
  }

  const removeBenefit = (index: number) => {
    onChange(benefits.filter((_, i) => i !== index))
    if (expandedIndex === index) {
      setExpandedIndex(null)
    }
  }

  const addBenefitImage = (index: number) => {
    const current = benefits[index].images || []
    updateBenefit(index, 'images', [...current, ''])
  }

  const updateBenefitImage = (benefitIndex: number, imageIndex: number, url: string) => {
    const current = [...(benefits[benefitIndex].images || [])]
    current[imageIndex] = url
    updateBenefit(benefitIndex, 'images', current)
  }

  const removeBenefitImage = (benefitIndex: number, imageIndex: number) => {
    const current = (benefits[benefitIndex].images || []).filter((_, i) => i !== imageIndex)
    updateBenefit(benefitIndex, 'images', current)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Gift className="h-5 w-5 text-pink-500" />
          <Label className="text-base font-semibold">특전 안내</Label>
        </div>
        <Button type="button" variant="outline" size="sm" onClick={addBenefit}>
          <Plus className="h-4 w-4 mr-1" />
          특전 추가
        </Button>
      </div>

      {benefits.length === 0 ? (
        <div className="border-2 border-dashed border-gray-200 rounded-lg p-8 text-center">
          <Gift className="h-12 w-12 mx-auto text-gray-300 mb-3" />
          <p className="text-gray-500 text-sm">
            펀딩 참여자에게 제공할 특전을 추가하세요
          </p>
          <p className="text-gray-400 text-xs mt-1">
            전원/당첨자/팬사인회/영상통화별로 다른 특전 설정 가능
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {benefits.map((benefit, index) => {
            const isExpanded = expandedIndex === index
            const typeInfo = FOR_TYPES.find(t => t.value === benefit.for_type) || FOR_TYPES[0]

            return (
              <div key={index} className="border rounded-lg bg-white overflow-hidden">
                {/* Header */}
                <button
                  type="button"
                  className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-50"
                  onClick={() => setExpandedIndex(isExpanded ? null : index)}
                >
                  <div className="flex items-center gap-3">
                    <span className={`px-2 py-0.5 rounded text-xs font-medium ${typeInfo.color}`}>
                      {typeInfo.label}
                    </span>
                    <span className="font-medium text-gray-900 text-left">
                      {benefit.title || '(제목 없음)'}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      className="text-gray-400 hover:text-red-500"
                      onClick={(e) => {
                        e.stopPropagation()
                        removeBenefit(index)
                      }}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                    {isExpanded ? (
                      <ChevronUp className="h-4 w-4 text-gray-400" />
                    ) : (
                      <ChevronDown className="h-4 w-4 text-gray-400" />
                    )}
                  </div>
                </button>

                {/* Content */}
                {isExpanded && (
                  <div className="px-4 pb-4 space-y-4 border-t border-gray-100">
                    {/* For Type */}
                    <div className="pt-4 space-y-2">
                      <Label className="text-sm text-gray-600">대상</Label>
                      <div className="flex gap-2 flex-wrap">
                        {FOR_TYPES.map((type) => (
                          <button
                            key={type.value}
                            type="button"
                            className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                              benefit.for_type === type.value
                                ? type.color
                                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                            }`}
                            onClick={() => updateBenefit(index, 'for_type', type.value)}
                          >
                            {type.label}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Title */}
                    <div className="space-y-2">
                      <Label className="text-sm text-gray-600">특전 이름 *</Label>
                      <Input
                        placeholder="예: 미공개 셀카 포토카드 1매"
                        value={benefit.title}
                        onChange={(e) => updateBenefit(index, 'title', e.target.value)}
                      />
                    </div>

                    {/* Description */}
                    <div className="space-y-2">
                      <Label className="text-sm text-gray-600">설명</Label>
                      <Textarea
                        placeholder="예: 앨범 1장당 1장 랜덤, 6종 중 랜덤 1종"
                        value={benefit.description}
                        onChange={(e) => updateBenefit(index, 'description', e.target.value)}
                        rows={3}
                      />
                    </div>

                    {/* Images */}
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <Label className="text-sm text-gray-600">이미지</Label>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => addBenefitImage(index)}
                        >
                          <Plus className="h-4 w-4 mr-1" />
                          이미지 추가
                        </Button>
                      </div>

                      {benefit.images && benefit.images.length > 0 && (
                        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                          {benefit.images.map((url, imgIndex) => (
                            <div key={imgIndex} className="relative">
                              <ImageUploader
                                bucket="benefit-images"
                                folder={`benefit-${index}`}
                                value={url}
                                onChange={(newUrl) => updateBenefitImage(index, imgIndex, newUrl)}
                                onRemove={() => removeBenefitImage(index, imgIndex)}
                                aspectRatio={1}
                                placeholder="특전 이미지"
                                showUrlInput={false}
                              />
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}

      <p className="text-xs text-gray-500">
        💡 Makestar 스타일의 특전 안내 섹션이 캠페인 상세 페이지에 표시됩니다
      </p>
    </div>
  )
}
