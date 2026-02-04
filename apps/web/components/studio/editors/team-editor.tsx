'use client'

import { useState } from 'react'
import Image from 'next/image'
import { TeamInfo, TeamMember } from '@/lib/types/database'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { ImageUploader } from '@/components/ui/image-uploader'
import { Plus, Trash2, Users, ChevronDown, ChevronUp } from 'lucide-react'

interface TeamEditorProps {
  team: TeamInfo
  onChange: (team: TeamInfo) => void
}

export function TeamEditor({ team, onChange }: TeamEditorProps) {
  const [expandedIndex, setExpandedIndex] = useState<number | null>(0)

  const members = team.members || []

  const updateField = (field: keyof TeamInfo, value: any) => {
    onChange({ ...team, [field]: value })
  }

  const addMember = () => {
    const newMember: TeamMember = {
      name: '',
      role: '',
      avatar_url: '',
      bio: '',
      links: []
    }
    onChange({
      ...team,
      members: [...members, newMember]
    })
    setExpandedIndex(members.length)
  }

  const updateMember = (index: number, field: keyof TeamMember, value: any) => {
    const updated = [...members]
    updated[index] = { ...updated[index], [field]: value }
    onChange({ ...team, members: updated })
  }

  const removeMember = (index: number) => {
    const updated = members.filter((_, i) => i !== index)
    onChange({ ...team, members: updated })
    if (expandedIndex === index) {
      setExpandedIndex(null)
    }
  }

  const addMemberLink = (memberIndex: number) => {
    const current = members[memberIndex].links || []
    updateMember(memberIndex, 'links', [...current, { type: '', url: '' }])
  }

  const updateMemberLink = (memberIndex: number, linkIndex: number, field: string, value: string) => {
    const currentLinks = [...(members[memberIndex].links || [])]
    currentLinks[linkIndex] = { ...currentLinks[linkIndex], [field]: value }
    updateMember(memberIndex, 'links', currentLinks)
  }

  const removeMemberLink = (memberIndex: number, linkIndex: number) => {
    const currentLinks = (members[memberIndex].links || []).filter((_, i) => i !== linkIndex)
    updateMember(memberIndex, 'links', currentLinks)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Users className="h-5 w-5 text-pink-500" />
          <Label className="text-base font-semibold">팀 소개</Label>
        </div>
        <Button type="button" variant="outline" size="sm" onClick={addMember}>
          <Plus className="h-4 w-4 mr-1" />
          팀원 추가
        </Button>
      </div>

      {/* Company Info */}
      <div className="space-y-3 p-4 bg-gray-50 rounded-lg">
        <div>
          <Label className="text-sm text-gray-600">회사/팀명</Label>
          <Input
            placeholder="예: UNO A Entertainment"
            value={team.company_name || ''}
            onChange={(e) => updateField('company_name', e.target.value)}
            className="mt-1"
          />
        </div>
        <div>
          <Label className="text-sm text-gray-600">회사/팀 소개</Label>
          <Textarea
            placeholder="회사 또는 팀에 대한 간략한 소개"
            value={team.company_description || ''}
            onChange={(e) => updateField('company_description', e.target.value)}
            rows={3}
            className="mt-1"
          />
        </div>
      </div>

      {/* Team Members */}
      {members.length === 0 ? (
        <div className="border-2 border-dashed border-gray-200 rounded-lg p-8 text-center">
          <Users className="h-12 w-12 mx-auto text-gray-300 mb-3" />
          <p className="text-gray-500 text-sm">
            프로젝트 팀원을 소개하세요
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {members.map((member, index) => {
            const isExpanded = expandedIndex === index

            return (
              <div key={index} className="border rounded-lg bg-white overflow-hidden">
                {/* Header */}
                <button
                  type="button"
                  className="w-full px-4 py-3 flex items-center justify-between hover:bg-gray-50"
                  onClick={() => setExpandedIndex(isExpanded ? null : index)}
                >
                  <div className="flex items-center gap-3">
                    <div className="relative w-10 h-10 rounded-full overflow-hidden bg-gray-100 flex-shrink-0">
                      {member.avatar_url ? (
                        <Image
                          src={member.avatar_url}
                          alt={member.name || '팀원'}
                          fill
                          className="object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center">
                          <Users className="h-5 w-5 text-gray-300" />
                        </div>
                      )}
                    </div>
                    <div className="text-left">
                      <p className="font-medium text-gray-900">
                        {member.name || '(이름 없음)'}
                      </p>
                      <p className="text-sm text-gray-500">
                        {member.role || '역할 미정'}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      className="text-gray-400 hover:text-red-500"
                      onClick={(e) => {
                        e.stopPropagation()
                        removeMember(index)
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
                    <div className="pt-4 grid grid-cols-2 gap-3">
                      <div>
                        <Label className="text-xs text-gray-500">이름 *</Label>
                        <Input
                          placeholder="홍길동"
                          value={member.name}
                          onChange={(e) => updateMember(index, 'name', e.target.value)}
                          className="mt-1"
                        />
                      </div>
                      <div>
                        <Label className="text-xs text-gray-500">역할 *</Label>
                        <Input
                          placeholder="대표, 디자이너, 개발자 등"
                          value={member.role}
                          onChange={(e) => updateMember(index, 'role', e.target.value)}
                          className="mt-1"
                        />
                      </div>
                    </div>

                    <div>
                      <Label className="text-xs text-gray-500">프로필 이미지</Label>
                      <div className="mt-1 w-24">
                        <ImageUploader
                          bucket="team-avatars"
                          folder={`member-${index}`}
                          value={member.avatar_url || ''}
                          onChange={(url) => updateMember(index, 'avatar_url', url)}
                          aspectRatio={1}
                          placeholder="프로필 사진"
                          showUrlInput={false}
                          className="[&>div:first-child]:rounded-full"
                        />
                      </div>
                    </div>

                    <div>
                      <Label className="text-xs text-gray-500">소개</Label>
                      <Textarea
                        placeholder="팀원에 대한 간략한 소개"
                        value={member.bio || ''}
                        onChange={(e) => updateMember(index, 'bio', e.target.value)}
                        rows={3}
                        className="mt-1"
                      />
                    </div>

                    {/* Links */}
                    <div className="space-y-2">
                      <div className="flex items-center justify-between">
                        <Label className="text-xs text-gray-500">링크</Label>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => addMemberLink(index)}
                        >
                          <Plus className="h-4 w-4 mr-1" />
                          링크 추가
                        </Button>
                      </div>

                      {member.links && member.links.length > 0 && (
                        <div className="space-y-2">
                          {member.links.map((link, linkIndex) => (
                            <div key={linkIndex} className="flex gap-2 items-center">
                              <Input
                                placeholder="유형 (예: Instagram)"
                                value={link.type}
                                onChange={(e) => updateMemberLink(index, linkIndex, 'type', e.target.value)}
                                className="w-32 text-sm"
                              />
                              <Input
                                placeholder="https://..."
                                value={link.url}
                                onChange={(e) => updateMemberLink(index, linkIndex, 'url', e.target.value)}
                                className="flex-1 text-sm"
                              />
                              <Button
                                type="button"
                                variant="ghost"
                                size="sm"
                                className="text-gray-400 hover:text-red-500"
                                onClick={() => removeMemberLink(index, linkIndex)}
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
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
        💡 팀 소개는 캠페인 소개 탭의 &quot;팀 소개&quot; 서브탭에 표시됩니다
      </p>
    </div>
  )
}
