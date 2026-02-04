'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'

export default function NewCampaignPage() {
  const router = useRouter()
  const [title, setTitle] = useState('')
  const [isCreating, setIsCreating] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!title.trim()) {
      setError('캠페인 제목을 입력해주세요')
      return
    }

    setIsCreating(true)
    setError(null)

    try {
      const supabase = createClient()

      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        throw new Error('로그인이 필요합니다')
      }

      const { data: campaign, error: createError } = await supabase
        .from('funding_campaigns')
        .insert({
          creator_id: user.id,
          title: title.trim(),
          status: 'draft',
        })
        .select()
        .single()

      if (createError) throw createError

      // Redirect to edit page
      router.push(`/studio/campaigns/${campaign.id}/edit`)
    } catch (err) {
      setError(err instanceof Error ? err.message : '캠페인 생성에 실패했습니다')
      setIsCreating(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">새 캠페인 만들기</h1>
        <p className="text-gray-500 mt-1">캠페인의 이름을 정해주세요</p>
      </div>

      <div className="bg-white rounded-xl p-6 border border-gray-100">
        <form onSubmit={handleCreate} className="space-y-6">
          <div>
            <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-2">
              캠페인 제목 *
            </label>
            <input
              type="text"
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="예: 첫 번째 정규 앨범 발매 프로젝트"
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              maxLength={100}
              autoFocus
            />
            <p className="mt-2 text-sm text-gray-500">
              {title.length}/100자 - 후에 언제든지 변경할 수 있어요
            </p>
          </div>

          {error && (
            <div className="p-3 bg-red-50 border border-red-100 rounded-lg text-sm text-red-600">
              {error}
            </div>
          )}

          <div className="flex justify-end gap-3">
            <Button
              type="button"
              variant="outline"
              onClick={() => router.back()}
            >
              취소
            </Button>
            <Button type="submit" loading={isCreating}>
              캠페인 만들기
            </Button>
          </div>
        </form>
      </div>
    </div>
  )
}
