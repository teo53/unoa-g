'use client'

import { useState } from 'react'
import Image from 'next/image'
import { RewardTierEnhanced } from '@/lib/types/database'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Badge } from '@/components/ui/badge'
import {
  Plus, Trash2, Users, Package, ImageIcon, Award, Truck, ChevronDown, ChevronUp
} from 'lucide-react'

interface RewardAdvancedEditorProps {
  tier: Partial<RewardTierEnhanced>
  onChange: (tier: Partial<RewardTierEnhanced>) => void
}

const BADGE_TYPES = [
  { value: '', label: '없음', color: 'bg-gray-100 text-gray-600' },
  { value: 'recommended', label: '추천', color: 'bg-pink-500 text-white' },
  { value: 'limited', label: '한정', color: 'bg-orange-500 text-white' },
  { value: 'early_bird', label: '얼리버드', color: 'bg-blue-500 text-white' },
  { value: 'best', label: 'BEST', color: 'bg-purple-500 text-white' },
  { value: 'new', label: 'NEW', color: 'bg-green-500 text-white' },
] as const

export function RewardAdvancedEditor({ tier, onChange }: RewardAdvancedEditorProps) {
  const [activeSection, setActiveSection] = useState<string | null>('badge')

  const updateField = (field: keyof RewardTierEnhanced, value: any) => {
    onChange({ ...tier, [field]: value })
  }

  // Member Options
  const memberOptions = tier.member_options || []

  const addMemberOption = () => {
    updateField('member_options', [
      ...memberOptions,
      { member_name: '', member_id: '', avatar_url: '', additional_info: '' }
    ])
    updateField('has_member_selection', true)
  }

  const updateMemberOption = (index: number, field: string, value: string) => {
    const updated = [...memberOptions]
    updated[index] = { ...updated[index], [field]: value }
    updateField('member_options', updated)
  }

  const removeMemberOption = (index: number) => {
    const updated = memberOptions.filter((_, i) => i !== index)
    updateField('member_options', updated)
    if (updated.length === 0) {
      updateField('has_member_selection', false)
    }
  }

  // Included Items
  const includedItems = tier.included_items || []

  const addIncludedItem = () => {
    updateField('included_items', [
      ...includedItems,
      { name: '', quantity: 1, description: '', image_url: '' }
    ])
  }

  const updateIncludedItem = (index: number, field: string, value: any) => {
    const updated = [...includedItems]
    updated[index] = { ...updated[index], [field]: value }
    updateField('included_items', updated)
  }

  const removeIncludedItem = (index: number) => {
    const updated = includedItems.filter((_, i) => i !== index)
    updateField('included_items', updated)
  }

  const Section = ({
    id,
    title,
    icon,
    children
  }: {
    id: string
    title: string
    icon: React.ReactNode
    children: React.ReactNode
  }) => {
    const isActive = activeSection === id
    return (
      <div className="border rounded-lg bg-white overflow-hidden">
        <button
          type="button"
          className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-50"
          onClick={() => setActiveSection(isActive ? null : id)}
        >
          <div className="flex items-center gap-2">
            {icon}
            <span className="font-medium text-gray-900">{title}</span>
          </div>
          {isActive ? (
            <ChevronUp className="h-4 w-4 text-gray-400" />
          ) : (
            <ChevronDown className="h-4 w-4 text-gray-400" />
          )}
        </button>
        {isActive && (
          <div className="px-4 pb-4 border-t border-gray-100 pt-4">
            {children}
          </div>
        )}
      </div>
    )
  }

  return (
    <div className="space-y-3">
      <Label className="text-sm font-medium text-gray-700">고급 옵션</Label>

      {/* Badge Section */}
      <Section
        id="badge"
        title="뱃지"
        icon={<Award className="h-4 w-4 text-pink-500" />}
      >
        <div className="space-y-3">
          <div className="flex gap-2 flex-wrap">
            {BADGE_TYPES.map((badgeType) => (
              <button
                key={badgeType.value}
                type="button"
                className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                  tier.badge_type === badgeType.value
                    ? badgeType.color
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
                onClick={() => updateField('badge_type', badgeType.value || undefined)}
              >
                {badgeType.label}
              </button>
            ))}
          </div>
          {tier.badge_type && (
            <div>
              <Label className="text-xs text-gray-500">커스텀 라벨 (선택)</Label>
              <Input
                placeholder="기본값 사용"
                value={tier.badge_label || ''}
                onChange={(e) => updateField('badge_label', e.target.value)}
                className="mt-1"
              />
            </div>
          )}
        </div>
      </Section>

      {/* Member Options Section */}
      <Section
        id="members"
        title={`멤버 선택 옵션 ${memberOptions.length > 0 ? `(${memberOptions.length}명)` : ''}`}
        icon={<Users className="h-4 w-4 text-purple-500" />}
      >
        <div className="space-y-3">
          <p className="text-sm text-gray-600">
            구매자가 선택할 수 있는 멤버 옵션을 설정합니다 (Makestar 스타일)
          </p>

          {memberOptions.length > 0 && (
            <div className="space-y-2">
              {memberOptions.map((member, index) => (
                <div key={index} className="flex gap-2 items-start p-3 bg-gray-50 rounded-lg">
                  <div className="relative w-10 h-10 rounded-full overflow-hidden bg-gray-200 flex-shrink-0">
                    {member.avatar_url ? (
                      <Image
                        src={member.avatar_url}
                        alt={member.member_name}
                        fill
                        className="object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-gray-400">
                        {member.member_name?.charAt(0) || '?'}
                      </div>
                    )}
                  </div>
                  <div className="flex-1 grid grid-cols-2 gap-2">
                    <Input
                      placeholder="멤버 이름"
                      value={member.member_name}
                      onChange={(e) => updateMemberOption(index, 'member_name', e.target.value)}
                      className="text-sm"
                    />
                    <Input
                      placeholder="멤버 ID (선택)"
                      value={member.member_id}
                      onChange={(e) => updateMemberOption(index, 'member_id', e.target.value)}
                      className="text-sm"
                    />
                    <Input
                      placeholder="프로필 이미지 URL"
                      value={member.avatar_url || ''}
                      onChange={(e) => updateMemberOption(index, 'avatar_url', e.target.value)}
                      className="text-sm col-span-2"
                    />
                  </div>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="text-gray-400 hover:text-red-500"
                    onClick={() => removeMemberOption(index)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              ))}
            </div>
          )}

          <Button type="button" variant="outline" size="sm" onClick={addMemberOption}>
            <Plus className="h-4 w-4 mr-1" />
            멤버 추가
          </Button>
        </div>
      </Section>

      {/* Included Items Section */}
      <Section
        id="items"
        title={`포함 구성 ${includedItems.length > 0 ? `(${includedItems.length}개)` : ''}`}
        icon={<Package className="h-4 w-4 text-green-500" />}
      >
        <div className="space-y-3">
          <p className="text-sm text-gray-600">
            이 리워드에 포함된 아이템 목록
          </p>

          {includedItems.length > 0 && (
            <div className="space-y-2">
              {includedItems.map((item, index) => (
                <div key={index} className="flex gap-2 items-start p-3 bg-gray-50 rounded-lg">
                  <div className="relative w-12 h-12 rounded overflow-hidden bg-gray-200 flex-shrink-0">
                    {item.image_url ? (
                      <Image
                        src={item.image_url}
                        alt={item.name}
                        fill
                        className="object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <ImageIcon className="h-5 w-5 text-gray-300" />
                      </div>
                    )}
                  </div>
                  <div className="flex-1 space-y-2">
                    <div className="flex gap-2">
                      <Input
                        placeholder="아이템 이름"
                        value={item.name}
                        onChange={(e) => updateIncludedItem(index, 'name', e.target.value)}
                        className="text-sm flex-1"
                      />
                      <Input
                        type="number"
                        placeholder="수량"
                        value={item.quantity || ''}
                        onChange={(e) => updateIncludedItem(index, 'quantity', parseInt(e.target.value) || 1)}
                        className="text-sm w-20"
                      />
                    </div>
                    <Input
                      placeholder="설명 (선택)"
                      value={item.description || ''}
                      onChange={(e) => updateIncludedItem(index, 'description', e.target.value)}
                      className="text-sm"
                    />
                    <Input
                      placeholder="이미지 URL (선택)"
                      value={item.image_url || ''}
                      onChange={(e) => updateIncludedItem(index, 'image_url', e.target.value)}
                      className="text-sm"
                    />
                  </div>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    className="text-gray-400 hover:text-red-500"
                    onClick={() => removeIncludedItem(index)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              ))}
            </div>
          )}

          <Button type="button" variant="outline" size="sm" onClick={addIncludedItem}>
            <Plus className="h-4 w-4 mr-1" />
            아이템 추가
          </Button>
        </div>
      </Section>

      {/* Shipping Info Section */}
      <Section
        id="shipping"
        title="배송 정보"
        icon={<Truck className="h-4 w-4 text-blue-500" />}
      >
        <div className="space-y-3">
          <div>
            <Label className="text-xs text-gray-500">예상 배송일</Label>
            <Input
              type="date"
              value={tier.estimated_delivery_at?.split('T')[0] || ''}
              onChange={(e) => updateField('estimated_delivery_at', e.target.value ? `${e.target.value}T00:00:00Z` : undefined)}
              className="mt-1"
            />
          </div>
          <div>
            <Label className="text-xs text-gray-500">배송 안내</Label>
            <Textarea
              placeholder="예: 펀딩 종료 후 약 2주 내 순차 발송"
              value={tier.shipping_info || ''}
              onChange={(e) => updateField('shipping_info', e.target.value)}
              rows={2}
              className="mt-1"
            />
          </div>
        </div>
      </Section>
    </div>
  )
}
