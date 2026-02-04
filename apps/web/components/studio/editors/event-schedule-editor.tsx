'use client'

import { EventSchedule } from '@/lib/types/database'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Plus, Trash2, Calendar } from 'lucide-react'

interface EventScheduleEditorProps {
  schedule: EventSchedule
  onChange: (schedule: EventSchedule) => void
}

export function EventScheduleEditor({ schedule, onChange }: EventScheduleEditorProps) {
  const updateField = (field: keyof EventSchedule, value: any) => {
    onChange({ ...schedule, [field]: value })
  }

  const updateSalePeriod = (field: 'start' | 'end', value: string) => {
    const current = schedule.sale_period || { start: '', end: '' }
    onChange({
      ...schedule,
      sale_period: { ...current, [field]: value }
    })
  }

  const addCustomEvent = () => {
    const current = schedule.custom_events || []
    onChange({
      ...schedule,
      custom_events: [...current, { label: '', date: '', description: '' }]
    })
  }

  const updateCustomEvent = (index: number, field: string, value: string) => {
    const current = [...(schedule.custom_events || [])]
    current[index] = { ...current[index], [field]: value }
    onChange({ ...schedule, custom_events: current })
  }

  const removeCustomEvent = (index: number) => {
    const current = (schedule.custom_events || []).filter((_, i) => i !== index)
    onChange({ ...schedule, custom_events: current })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 mb-4">
        <Calendar className="h-5 w-5 text-pink-500" />
        <Label className="text-base font-semibold">이벤트 일정</Label>
      </div>

      {/* Sale Period */}
      <div className="space-y-3 p-4 bg-gray-50 rounded-lg">
        <Label className="text-sm font-medium text-gray-700">🛒 판매 기간</Label>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <Label className="text-xs text-gray-500">시작일</Label>
            <Input
              type="date"
              value={schedule.sale_period?.start || ''}
              onChange={(e) => updateSalePeriod('start', e.target.value)}
            />
          </div>
          <div>
            <Label className="text-xs text-gray-500">종료일</Label>
            <Input
              type="date"
              value={schedule.sale_period?.end || ''}
              onChange={(e) => updateSalePeriod('end', e.target.value)}
            />
          </div>
        </div>
      </div>

      {/* Winner Announcement */}
      <div className="space-y-2">
        <Label className="text-sm font-medium text-gray-700">🎉 당첨자 발표</Label>
        <Input
          placeholder="예: 2026-02-06 14:00 (KST)"
          value={schedule.winner_announce || ''}
          onChange={(e) => updateField('winner_announce', e.target.value)}
        />
      </div>

      {/* Fansign Date */}
      <div className="space-y-2">
        <Label className="text-sm font-medium text-gray-700">🎤 팬사인회 일시</Label>
        <Input
          placeholder="예: 2026-02-10 19:30"
          value={schedule.fansign_date || ''}
          onChange={(e) => updateField('fansign_date', e.target.value)}
        />
      </div>

      {/* Videocall Date */}
      <div className="space-y-2">
        <Label className="text-sm font-medium text-gray-700">📱 영상통화 일시</Label>
        <Input
          placeholder="예: 2026-02-10 (1부 종료 후)"
          value={schedule.videocall_date || ''}
          onChange={(e) => updateField('videocall_date', e.target.value)}
        />
      </div>

      {/* Shipping Date */}
      <div className="space-y-2">
        <Label className="text-sm font-medium text-gray-700">📦 배송 예정일</Label>
        <Input
          placeholder="예: 2026년 2월 말 순차 배송"
          value={schedule.shipping_date || ''}
          onChange={(e) => updateField('shipping_date', e.target.value)}
        />
      </div>

      {/* Custom Events */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <Label className="text-sm font-medium text-gray-700">📌 추가 일정</Label>
          <Button type="button" variant="outline" size="sm" onClick={addCustomEvent}>
            <Plus className="h-4 w-4 mr-1" />
            일정 추가
          </Button>
        </div>

        {schedule.custom_events && schedule.custom_events.length > 0 && (
          <div className="space-y-3">
            {schedule.custom_events.map((event, index) => (
              <div key={index} className="flex gap-2 items-start p-3 border rounded-lg bg-white">
                <div className="flex-1 space-y-2">
                  <Input
                    placeholder="일정 이름 (예: 포토카드 추가 증정)"
                    value={event.label}
                    onChange={(e) => updateCustomEvent(index, 'label', e.target.value)}
                    className="text-sm"
                  />
                  <Input
                    placeholder="날짜/시간 (예: 2026-02-08 18:00)"
                    value={event.date}
                    onChange={(e) => updateCustomEvent(index, 'date', e.target.value)}
                    className="text-sm"
                  />
                  <Input
                    placeholder="설명 (선택사항)"
                    value={event.description || ''}
                    onChange={(e) => updateCustomEvent(index, 'description', e.target.value)}
                    className="text-sm"
                  />
                </div>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  className="text-gray-400 hover:text-red-500"
                  onClick={() => removeCustomEvent(index)}
                >
                  <Trash2 className="h-4 w-4" />
                </Button>
              </div>
            ))}
          </div>
        )}
      </div>

      <p className="text-xs text-gray-500">
        💡 Makestar 스타일의 이벤트 일정 박스가 캠페인 상세 페이지에 표시됩니다
      </p>
    </div>
  )
}
