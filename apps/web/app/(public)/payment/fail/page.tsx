'use client'

import Link from 'next/link'
import { Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { routes } from '@/lib/constants/routes'

function PaymentFailContent() {
  const searchParams = useSearchParams()
  const code = searchParams.get('code') ?? searchParams.get('errorCode') ?? 'UNKNOWN'
  const message = searchParams.get('message') ?? searchParams.get('error') ?? '결제가 실패했습니다.'
  const orderId = searchParams.get('orderId') ?? '-'

  return (
    <main className="mx-auto max-w-2xl px-4 py-16">
      <div className="rounded-2xl border border-red-200 bg-red-50 p-6">
        <h1 className="text-2xl font-bold text-red-900">결제 실패</h1>
        <p className="mt-4 text-sm text-red-800">오류 코드: {code}</p>
        <p className="mt-2 text-sm text-red-800">메시지: {message}</p>
        <p className="mt-2 text-xs text-red-700">주문 ID: {orderId}</p>

        <div className="mt-8 flex gap-3">
          <Link
            href={routes.store.dt}
            className="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-700"
          >
            DT 스토어에서 다시 시도
          </Link>
          <Link
            href={routes.home}
            className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
          >
            홈으로 이동
          </Link>
        </div>
      </div>
    </main>
  )
}

export default function PaymentFailPage() {
  return (
    <Suspense fallback={<main className="mx-auto max-w-2xl px-4 py-16 text-sm text-gray-600">결제 결과를 불러오는 중...</main>}>
      <PaymentFailContent />
    </Suspense>
  )
}
