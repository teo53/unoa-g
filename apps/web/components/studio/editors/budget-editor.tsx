'use client'

import { BudgetInfo, BudgetItem } from '@/lib/types/database'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Button } from '@/components/ui/button'
import { Plus, Trash2, PieChart } from 'lucide-react'

interface BudgetEditorProps {
  budget: BudgetInfo
  onChange: (budget: BudgetInfo) => void
}

const DEFAULT_ITEMS: BudgetItem[] = [
  { name: '제작비', amount: 0, percentage: 0 },
  { name: '배송비', amount: 0, percentage: 0 },
  { name: '수수료', amount: 0, percentage: 0 },
]

export function BudgetEditor({ budget, onChange }: BudgetEditorProps) {
  const items = budget.items && budget.items.length > 0 ? budget.items : DEFAULT_ITEMS

  const addItem = () => {
    const newItems = [...items, { name: '', amount: 0, percentage: 0 }]
    recalculatePercentages(newItems)
  }

  const updateItem = (index: number, field: keyof BudgetItem, value: string | number) => {
    const updated = [...items]
    updated[index] = { ...updated[index], [field]: value }

    if (field === 'amount') {
      recalculatePercentages(updated)
    } else {
      onChange({
        ...budget,
        items: updated
      })
    }
  }

  const removeItem = (index: number) => {
    const updated = items.filter((_, i) => i !== index)
    recalculatePercentages(updated)
  }

  const recalculatePercentages = (newItems: BudgetItem[]) => {
    const total = newItems.reduce((sum, item) => sum + (item.amount || 0), 0)
    const updatedItems = newItems.map(item => ({
      ...item,
      percentage: total > 0 ? Math.round((item.amount / total) * 100) : 0
    }))

    onChange({
      items: updatedItems,
      total,
      currency: 'KRW'
    })
  }

  const total = items.reduce((sum, item) => sum + (item.amount || 0), 0)

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <PieChart className="h-5 w-5 text-pink-500" />
          <Label className="text-base font-semibold">예산 정보</Label>
        </div>
        <Button type="button" variant="outline" size="sm" onClick={addItem}>
          <Plus className="h-4 w-4 mr-1" />
          항목 추가
        </Button>
      </div>

      <div className="space-y-3">
        {items.map((item, index) => (
          <div key={index} className="flex gap-3 items-center p-3 border rounded-lg bg-white">
            <div className="flex-1 min-w-0">
              <Label className="text-xs text-gray-500">항목명</Label>
              <Input
                placeholder="예: 제작비"
                value={item.name}
                onChange={(e) => updateItem(index, 'name', e.target.value)}
                className="mt-1"
              />
            </div>
            <div className="w-32">
              <Label className="text-xs text-gray-500">금액 (원)</Label>
              <Input
                type="number"
                placeholder="0"
                value={item.amount || ''}
                onChange={(e) => updateItem(index, 'amount', parseInt(e.target.value) || 0)}
                className="mt-1"
              />
            </div>
            <div className="w-20">
              <Label className="text-xs text-gray-500">비율</Label>
              <div className="mt-1 h-10 flex items-center justify-center bg-gray-50 rounded-md text-sm font-medium text-gray-600">
                {item.percentage}%
              </div>
            </div>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              className="text-gray-400 hover:text-red-500 self-end mb-1"
              onClick={() => removeItem(index)}
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        ))}
      </div>

      {/* Progress Bars */}
      {items.some(item => item.amount > 0) && (
        <div className="space-y-2 p-4 bg-gray-50 rounded-lg">
          <Label className="text-sm font-medium text-gray-700">예산 분배</Label>
          <div className="h-4 bg-gray-200 rounded-full overflow-hidden flex">
            {items.map((item, index) => (
              item.percentage > 0 && (
                <div
                  key={index}
                  className={`h-full transition-all ${
                    ['bg-pink-500', 'bg-purple-500', 'bg-blue-500', 'bg-green-500', 'bg-orange-500', 'bg-yellow-500'][index % 6]
                  }`}
                  style={{ width: `${item.percentage}%` }}
                  title={`${item.name}: ${item.percentage}%`}
                />
              )
            ))}
          </div>
          <div className="flex flex-wrap gap-3 mt-2">
            {items.map((item, index) => (
              item.amount > 0 && (
                <div key={index} className="flex items-center gap-1.5 text-xs">
                  <div
                    className={`w-3 h-3 rounded-full ${
                      ['bg-pink-500', 'bg-purple-500', 'bg-blue-500', 'bg-green-500', 'bg-orange-500', 'bg-yellow-500'][index % 6]
                    }`}
                  />
                  <span className="text-gray-600">{item.name}</span>
                  <span className="font-medium">{item.percentage}%</span>
                </div>
              )
            ))}
          </div>
        </div>
      )}

      {/* Total */}
      <div className="flex items-center justify-between p-4 bg-pink-50 rounded-lg">
        <span className="font-medium text-gray-700">총 예산</span>
        <span className="text-xl font-bold text-pink-600">
          {total.toLocaleString()}원
        </span>
      </div>

      <p className="text-xs text-gray-500">
        💡 Tumblbug 스타일의 예산 breakdown이 캠페인 소개 탭에 표시됩니다
      </p>
    </div>
  )
}
