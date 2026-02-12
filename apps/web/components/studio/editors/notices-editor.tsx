'use client'

import { useState } from 'react'
import { Notice } from '@/lib/types/database'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Plus, Trash2, AlertTriangle, GripVertical, ChevronDown, ChevronUp } from 'lucide-react'

interface NoticesEditorProps {
  notices: Notice[]
  onChange: (notices: Notice[]) => void
}

export function NoticesEditor({ notices, onChange }: NoticesEditorProps) {
  const [expandedIndex, setExpandedIndex] = useState<number | null>(0)
  const [draggedIndex, setDraggedIndex] = useState<number | null>(null)

  const addNotice = () => {
    const newNotice: Notice = {
      title: '',
      content_html: '',
      display_order: notices.length
    }
    onChange([...notices, newNotice])
    setExpandedIndex(notices.length)
  }

  const updateNotice = (index: number, field: keyof Notice, value: any) => {
    const updated = [...notices]
    updated[index] = { ...updated[index], [field]: value }
    onChange(updated)
  }

  const removeNotice = (index: number) => {
    const updated = notices.filter((_, i) => i !== index)
    // Re-order
    updated.forEach((notice, i) => {
      notice.display_order = i
    })
    onChange(updated)
    if (expandedIndex === index) {
      setExpandedIndex(null)
    }
  }

  const handleDragStart = (index: number) => {
    setDraggedIndex(index)
  }

  const handleDragOver = (e: React.DragEvent, index: number) => {
    e.preventDefault()
    if (draggedIndex === null || draggedIndex === index) return

    const updated = [...notices]
    const [removed] = updated.splice(draggedIndex, 1)
    updated.splice(index, 0, removed)

    // Update display_order
    updated.forEach((notice, i) => {
      notice.display_order = i
    })

    onChange(updated)
    setDraggedIndex(index)
  }

  const handleDragEnd = () => {
    setDraggedIndex(null)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <AlertTriangle className="h-5 w-5 text-yellow-500" />
          <Label className="text-base font-semibold">유의사항</Label>
        </div>
        <Button type="button" variant="outline" size="sm" onClick={addNotice}>
          <Plus className="h-4 w-4 mr-1" />
          유의사항 추가
        </Button>
      </div>

      {notices.length === 0 ? (
        <div className="border-2 border-dashed border-gray-200 rounded-lg p-8 text-center">
          <AlertTriangle className="h-12 w-12 mx-auto text-gray-300 mb-3" />
          <p className="text-gray-500 text-sm">
            펀딩 참여자가 알아야 할 유의사항을 추가하세요
          </p>
          <p className="text-gray-400 text-xs mt-1">
            배송, 교환/환불, 이벤트 참여 조건 등
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {notices.map((notice, index) => {
            const isExpanded = expandedIndex === index

            return (
              <div
                key={index}
                draggable
                onDragStart={() => handleDragStart(index)}
                onDragOver={(e) => handleDragOver(e, index)}
                onDragEnd={handleDragEnd}
                className={`border rounded-lg bg-white overflow-hidden transition-all ${
                  draggedIndex === index ? 'opacity-50 border-yellow-300' : 'border-gray-200'
                }`}
              >
                {/* Header */}
                <button
                  type="button"
                  className="w-full px-4 py-3 flex items-center gap-3 hover:bg-gray-50"
                  onClick={() => setExpandedIndex(isExpanded ? null : index)}
                >
                  {/* Drag Handle */}
                  <div
                    className="cursor-grab active:cursor-grabbing"
                    onClick={(e) => e.stopPropagation()}
                  >
                    <GripVertical className="h-5 w-5 text-gray-400" />
                  </div>

                  <div className="flex-1 flex items-center justify-between">
                    <span className="font-medium text-gray-900 text-left">
                      {notice.title || `유의사항 ${index + 1}`}
                    </span>
                    <div className="flex items-center gap-2">
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        className="text-gray-400 hover:text-red-500"
                        onClick={(e) => {
                          e.stopPropagation()
                          removeNotice(index)
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
                  </div>
                </button>

                {/* Content */}
                {isExpanded && (
                  <div className="px-4 pb-4 space-y-4 border-t border-gray-100">
                    <div className="pt-4">
                      <Label className="text-xs text-gray-500">제목 *</Label>
                      <Input
                        placeholder="예: 이벤트 응모자 정보 입력 유의사항"
                        value={notice.title}
                        onChange={(e) => updateNotice(index, 'title', e.target.value)}
                        className="mt-1"
                      />
                    </div>

                    <div>
                      <Label className="text-xs text-gray-500">내용 *</Label>
                      <Textarea
                        placeholder="유의사항 내용을 입력하세요. (HTML은 안전한 태그만 허용됩니다)"
                        value={notice.content_html}
                        onChange={(e) => updateNotice(index, 'content_html', e.target.value)}
                        rows={5}
                        className="mt-1 font-mono text-sm"
                      />
                      <p className="text-xs text-gray-400 mt-1">
                        줄바꿈은 자동으로 적용됩니다
                      </p>
                    </div>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}

      {/* Preview */}
      {notices.length > 0 && notices.some(n => n.title && n.content_html) && (
        <div className="p-4 bg-yellow-50 rounded-lg space-y-2">
          <p className="text-sm font-medium text-yellow-800 flex items-center gap-1">
            <AlertTriangle className="h-4 w-4" />
            미리보기
          </p>
          <div className="space-y-3">
            {notices.map((notice, index) => (
              notice.title && notice.content_html && (
                <div key={index} className="bg-white p-3 rounded border border-yellow-200">
                  <p className="font-medium text-gray-900 text-sm mb-1">{notice.title}</p>
                  <p className="text-xs text-gray-600 whitespace-pre-line">
                    {notice.content_html.replace(/<[^>]*>/g, '')}
                  </p>
                </div>
              )
            ))}
          </div>
        </div>
      )}

      <p className="text-xs text-gray-500">
        💡 유의사항은 캠페인 상세 페이지 하단에 표시됩니다
      </p>
    </div>
  )
}
