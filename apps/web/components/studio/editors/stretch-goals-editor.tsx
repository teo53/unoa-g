'use client'

import { StretchGoal } from '@/lib/types/database'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Plus, Trash2, Target, GripVertical, Check } from 'lucide-react'
import { useState } from 'react'

interface StretchGoalsEditorProps {
  goals: StretchGoal[]
  currentAmountDt: number
  onChange: (goals: StretchGoal[]) => void
}

export function StretchGoalsEditor({ goals, currentAmountDt, onChange }: StretchGoalsEditorProps) {
  const [draggedIndex, setDraggedIndex] = useState<number | null>(null)

  const addGoal = () => {
    const newGoal: StretchGoal = {
      amount_dt: 0,
      title: '',
      description: '',
      is_reached: false
    }
    onChange([...goals, newGoal])
  }

  const updateGoal = (index: number, field: keyof StretchGoal, value: any) => {
    const updated = [...goals]
    updated[index] = { ...updated[index], [field]: value }

    // Auto-update is_reached based on current amount
    if (field === 'amount_dt') {
      updated[index].is_reached = currentAmountDt >= value
    }

    onChange(updated)
  }

  const removeGoal = (index: number) => {
    onChange(goals.filter((_, i) => i !== index))
  }

  const handleDragStart = (index: number) => {
    setDraggedIndex(index)
  }

  const handleDragOver = (e: React.DragEvent, index: number) => {
    e.preventDefault()
    if (draggedIndex === null || draggedIndex === index) return

    const updated = [...goals]
    const [removed] = updated.splice(draggedIndex, 1)
    updated.splice(index, 0, removed)
    onChange(updated)
    setDraggedIndex(index)
  }

  const handleDragEnd = () => {
    setDraggedIndex(null)
  }

  const sortByAmount = () => {
    const sorted = [...goals].sort((a, b) => a.amount_dt - b.amount_dt)
    onChange(sorted)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Target className="h-5 w-5 text-pink-500" />
          <Label className="text-base font-semibold">스트레치 골</Label>
        </div>
        <div className="flex gap-2">
          {goals.length > 1 && (
            <Button type="button" variant="ghost" size="sm" onClick={sortByAmount}>
              금액순 정렬
            </Button>
          )}
          <Button type="button" variant="outline" size="sm" onClick={addGoal}>
            <Plus className="h-4 w-4 mr-1" />
            목표 추가
          </Button>
        </div>
      </div>

      <p className="text-sm text-gray-600">
        현재 모금액: <span className="font-bold text-pink-600">{currentAmountDt.toLocaleString()}원</span>
      </p>

      {goals.length === 0 ? (
        <div className="border-2 border-dashed border-gray-200 rounded-lg p-8 text-center">
          <Target className="h-12 w-12 mx-auto text-gray-300 mb-3" />
          <p className="text-gray-500 text-sm">
            목표 금액 달성 시 추가 보상을 설정하세요
          </p>
          <p className="text-gray-400 text-xs mt-1">
            Tumblbug 스타일의 스트레치 골이 표시됩니다
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {goals.map((goal, index) => {
            const progress = goal.amount_dt > 0
              ? Math.min((currentAmountDt / goal.amount_dt) * 100, 100)
              : 0
            const isReached = currentAmountDt >= goal.amount_dt && goal.amount_dt > 0

            return (
              <div
                key={index}
                draggable
                onDragStart={() => handleDragStart(index)}
                onDragOver={(e) => handleDragOver(e, index)}
                onDragEnd={handleDragEnd}
                className={`p-4 border rounded-lg bg-white transition-all ${
                  draggedIndex === index ? 'opacity-50 border-pink-300' : 'border-gray-200'
                } ${isReached ? 'bg-green-50 border-green-200' : ''}`}
              >
                <div className="flex gap-3">
                  {/* Drag Handle */}
                  <div className="flex items-start pt-2 cursor-grab active:cursor-grabbing">
                    <GripVertical className="h-5 w-5 text-gray-400" />
                  </div>

                  <div className="flex-1 space-y-3">
                    {/* Amount and Status */}
                    <div className="flex items-center gap-3">
                      <div className="flex-1">
                        <Label className="text-xs text-gray-500">목표 금액 (원)</Label>
                        <Input
                          type="number"
                          placeholder="300000"
                          value={goal.amount_dt || ''}
                          onChange={(e) => updateGoal(index, 'amount_dt', parseInt(e.target.value) || 0)}
                          className="mt-1"
                        />
                      </div>
                      {isReached && (
                        <div className="flex items-center gap-1 text-green-600 text-sm font-medium mt-5">
                          <Check className="h-4 w-4" />
                          달성!
                        </div>
                      )}
                    </div>

                    {/* Progress Bar */}
                    {goal.amount_dt > 0 && (
                      <div className="space-y-1">
                        <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                          <div
                            className={`h-full transition-all ${isReached ? 'bg-green-500' : 'bg-pink-500'}`}
                            style={{ width: `${progress}%` }}
                          />
                        </div>
                        <p className="text-xs text-gray-500 text-right">
                          {progress.toFixed(1)}% 달성
                        </p>
                      </div>
                    )}

                    {/* Title */}
                    <div>
                      <Label className="text-xs text-gray-500">보상 이름 *</Label>
                      <Input
                        placeholder="예: 포토카드 추가 2종"
                        value={goal.title}
                        onChange={(e) => updateGoal(index, 'title', e.target.value)}
                        className="mt-1"
                      />
                    </div>

                    {/* Description */}
                    <div>
                      <Label className="text-xs text-gray-500">설명</Label>
                      <Textarea
                        placeholder="예: 랜덤 포토카드 2종 추가 증정"
                        value={goal.description || ''}
                        onChange={(e) => updateGoal(index, 'description', e.target.value)}
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
                    onClick={() => removeGoal(index)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            )
          })}
        </div>
      )}

      <p className="text-xs text-gray-500">
        💡 목표 금액에 도달하면 자동으로 &quot;달성&quot; 표시가 됩니다
      </p>
    </div>
  )
}
