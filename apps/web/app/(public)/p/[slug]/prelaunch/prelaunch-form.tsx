'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { DEMO_MODE, getCampaignBySlug } from '@/lib/mock/demo-data'

interface PrelaunchFormProps {
  slug: string
}

export default function PrelaunchForm({ slug }: PrelaunchFormProps) {
  const [email, setEmail] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [isSubmitted, setIsSubmitted] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSubmitting(true)
    setError(null)

    try {
      // Demo mode: just simulate success
      if (DEMO_MODE) {
        const campaign = getCampaignBySlug(slug)
        if (!campaign) {
          throw new Error('캠페인을 찾을 수 없습니다')
        }
        // Simulate network delay
        await new Promise(resolve => setTimeout(resolve, 500))
        setIsSubmitted(true)
        return
      }

      // Production mode: use Supabase
      const { createClient } = await import('@/lib/supabase/client')
      const supabase = createClient()

      // Get campaign ID from slug
      const { data: campaign } = await supabase
        .from('funding_campaigns')
        .select('id')
        .eq('slug', slug)
        .single()

      if (!campaign) {
        throw new Error('캠페인을 찾을 수 없습니다')
      }

      // Get current user if logged in
      const { data: { user } } = await supabase.auth.getUser()

      // Insert prelaunch signup
      const { error: insertError } = await supabase
        .from('funding_prelaunch_signups')
        .insert({
          campaign_id: (campaign as { id: string }).id,
          user_id: user?.id || null,
          email: user ? null : email,
          notify_on_launch: true,
        } as never)

      if (insertError) {
        if (insertError.code === '23505') {
          throw new Error('이미 알림 신청을 하셨습니다')
        }
        throw insertError
      }

      setIsSubmitted(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : '오류가 발생했습니다')
    } finally {
      setIsSubmitting(false)
    }
  }

  if (isSubmitted) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        {DEMO_MODE && (
          <div className="fixed top-0 left-0 right-0 bg-amber-50 border-b border-amber-200 px-4 py-2 text-center text-sm text-amber-800">
            Demo Mode - Mock data is displayed
          </div>
        )}
        <div className="max-w-md w-full bg-white rounded-2xl p-8 text-center">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-gray-900 mb-2">알림 신청 완료!</h1>
          <p className="text-gray-600 mb-6">
            펀딩이 시작되면 이메일로 알려드릴게요.
          </p>
          <Link href={`/p/${slug}`}>
            <Button variant="outline">캠페인으로 돌아가기</Button>
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      {DEMO_MODE && (
        <div className="fixed top-0 left-0 right-0 bg-amber-50 border-b border-amber-200 px-4 py-2 text-center text-sm text-amber-800">
          Demo Mode - Mock data is displayed
        </div>
      )}
      <div className="max-w-md w-full bg-white rounded-2xl p-8">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-primary-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-gray-900 mb-2">곧 시작됩니다!</h1>
          <p className="text-gray-600">
            펀딩 오픈 알림을 받아보세요.
            <br />
            누구보다 빨리 후원에 참여할 수 있어요.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
              이메일
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="example@email.com"
              required
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            />
          </div>

          {error && (
            <p className="text-sm text-red-500">{error}</p>
          )}

          <Button type="submit" size="lg" className="w-full" loading={isSubmitting}>
            알림 받기
          </Button>
        </form>

        <div className="mt-6 text-center">
          <Link href={`/p/${slug}`} className="text-sm text-gray-500 hover:text-gray-700">
            캠페인 상세 보기
          </Link>
        </div>
      </div>
    </div>
  )
}
