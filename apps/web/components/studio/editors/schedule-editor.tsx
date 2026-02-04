'use client'

import { ScheduleMilestone } from '@/lib/types/database'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Plus, Trash2, Calendar, Check, GripVertical } from 'lucide-react'
import { useState } from 'react'

interface ScheduleEditorProps {
  schedule: ScheduleMilestone[]
  onChange: (schedule: ScheduleMilestone[]) => void
}

export function ScheduleEditor({ schedule, onChange }: ScheduleEditorProps) {
  const [draggedIndex, setDraggedIndex] = useState<number | null>(null)

  const addMilestone = () => {
    const newMilestone: ScheduleMilestone = {
      date: '',
      milestone: '',
      description: '',
      is_completed: false
    }
    onChange([...schedule, newMilestone])
  }

  const updateMilestone = (index: number, field: keyof ScheduleMilestone, value: any) => {
    const updated = [...schedule]
    updated[index] = { ...updated[index], [field]: value }
    onChange(updated)
  }

  const removeMilestone = (index: number) => {
    onChange(schedule.filter((_, i) => i !== index))
  }

  const toggleCompleted = (index: number) => {
    const updated = [...schedule]
    updated[index] = { ...updated[index], is_completed: !updated[index].is_completed }
    onChange(updated)
  }

  const handleDragStart = (index: number) => {
    setDraggedIndex(index)
  }

  const handleDragOver = (e: React.DragEvent, index: number) => {
    e.preventDefault()
    if (draggedIndex === null || draggedIndex === index) return

    const updated = [...schedule]
    const [removed] = updated.splice(draggedIndex, 1)
    updated.splice(index, 0, removed)
    onChange(updated)
    setDraggedIndex(index)
  }

  const handleDragEnd = () => {
    setDraggedIndex(null)
  }

  const sortByDate = () => {
    const sorted = [...schedule].sort((a, b) => {
      if (!a.date) return 1
      if (!b.date) return -1
      return new Date(a.date).getTime() - new Date(b.date).getTime()
    })
    onChange(sorted)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Calendar className="h-5 w-5 text-pink-500" />
          <Label className="text-base font-semibold">일정 정보</Label>
        </div>
        <div className="flex gap-2">
          {schedule.length > 1 && (
            <Button type="button" variant="ghost" size="sm" onClick={sortByDate}>
              날짜순 정렬
            </Button>
          )}
          <Button type="button" variant="outline" size="sm" onClick={addMilestone}>
            <Plus className="h-4 w-4 mr-1" />
            일정 추가
          </Button>
        </div>
      </div>

      {schedule.length === 0 ? (
        <div className="border-2 border-dashed border-gray-200 rounded-lg p-8 text-center">
          <Calendar className="h-12 w-12 mx-auto text-gray-300 mb-3" />
          <p className="text-gray-500 text-sm">
            프로젝트 마일스톤 일정을 추가하세요
          </p>
          <p className="text-gray-400 text-xs mt-1">
            타임라인 형태로 캠페인 소개 탭에 표시됩니다
          </p>
        </div>
      ) : (
        <div className="relative">
          {/* Timeline line */}
          <div className="absolute left-[22px] top-8 bottom-8 w-0.5 bg-gray-200" />

          <div className="space-y-4">
            {schedule.map((item, index) => (
              <div
                key={index}
                draggable
                onDragStart={() => handleDragStart(index)}
                onDragOver={(e) => handleDragOver(e, index)}
                onDragEnd={handleDragEnd}
                className={`flex gap-3 relative ${
                  draggedIndex === index ? 'opacity-50' : ''
                }`}
              >
                {/* Timeline dot */}
                <button
                  type="button"
                  onClick={() => toggleCompleted(index)}
                  className={`w-11 h-11 rounded-full flex items-center justify-center flex-shrink-0 border-2 transition-colors z-10 ${
                    item.is_completed
                      ? 'bg-green-500 border-green-500 text-white'
                      : 'bg-white border-gray-300 text-gray-400 hover:border-pink-500'
                  }`}
                >
                  {item.is_completed ? (
                    <Check className="h-5 w-5" />
                  ) : (
                    <span className="text-sm font-medium">{index + 1}</span>
                  )}
                </button>

                {/* Content */}
                <div
                  className={`flex-1 p-4 border rounded-lg bg-white transition-all ${
                    item.is_completed ? 'border-green-200 bg-green-50' : 'border-gray-200'
                  }`}
                >
                  <div className="flex gap-3">
                    {/* Drag Handle */}
                    <div className="flex items-start pt-1 cursor-grab active:cursor-grabbing">
                      <GripVertical className="h-5 w-5 text-gray-400" />
                    </div>

                    <div className="flex-1 space-y-3">
                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <Label className="text-xs text-gray-500">날짜</Label>
                          <Input
                            type="date"
                            value={item.date}
                            onChange={(e) => updateMilestone(index, 'date', e.target.value)}
                            className="mt-1"
                          />
                        </div>
                        <div>
                          <Label className="text-xs text-gray-500">마일스톤 *</Label>
                          <Input
                            placeholder="예: 샘플 제작 완료"
                            value={item.milestone}
                            onChange={(e) => updateMilestone(index, 'milestone', e.target.value)}
                            className="mt-1"
                          />
                        </div>
                      </div>
                      <div>
                        <Label className="text-xs text-gray-500">설명</Label>
                        <Textarea
                          placeholder="상세 설명 (선택사항)"
                          value={item.description || ''}
                          onChange={(e) => updateMilestone(index, 'description', e.target.value)}
                          rows={2}
                          className="mt-1"
                        />
                      </div>
                    </div>

                    {/* Delete Button */}
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      className="text-gray-400 hover:text-red-500 self-start"
                      onClick={() => removeMilestone(index)}
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      <p className="text-xs text-gray-500">
        💡 원형 아이콘을 클릭하면 완료 상태로 표시됩니다
      </p>
    </div>
  )
}
