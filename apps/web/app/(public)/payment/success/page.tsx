'use client'

import Link from 'next/link'
import { Suspense, useEffect, useRef, useState } from 'react'
import { useSearchParams } from 'next/navigation'
import { routes } from '@/lib/constants/routes'
import { createClient } from '@/lib/supabase/client'

type ConfirmState = 'idle' | 'loading' | 'success' | 'already_processed' | 'failed'

function PaymentSuccessContent() {
  const searchParams = useSearchParams()
  const paymentKey = searchParams.get('paymentKey') ?? ''
  const orderId = searchParams.get('orderId') ?? ''
  const amountParam = searchParams.get('amount') ?? ''

  const [state, setState] = useState<ConfirmState>('idle')
  const [message, setMessage] = useState<string>('')
  const [creditedDt, setCreditedDt] = useState<number | null>(null)
  const requestStartedRef = useRef(false)

  useEffect(() => {
    if (requestStartedRef.current) return
    requestStartedRef.current = true

    const amount = Number(amountParam)
    if (!paymentKey || !orderId || !Number.isFinite(amount)) {
      setState('failed')
      setMessage('결제 확인 파라미터가 올바르지 않습니다.')
      return
    }

    const run = async () => {
      setState('loading')
      const supabase = createClient()
      const { data, error } = await supabase.functions.invoke('payment-confirm', {
        body: { paymentKey, orderId, amount },
      })

      if (error) {
        const code = (error as { context?: { json?: { errorCode?: string; error?: string } } })
          .context?.json?.errorCode
        const detail = (error as { context?: { json?: { detail?: string; error?: string } } })
          .context?.json
        if (code === 'PAYMENTS_DISABLED') {
          setMessage('현재 결제가 비활성화되어 있습니다.')
        } else if (code === 'PAYMENT_PROVIDER_NOT_READY') {
          setMessage('결제 서비스 준비 중입니다. 잠시 후 다시 시도해주세요.')
        } else {
          setMessage(detail?.detail ?? detail?.error ?? '결제 확인에 실패했습니다.')
        }
        setState('failed')
        return
      }

      const payload = (data ?? {}) as {
        success?: boolean
        already_processed?: boolean
        creditedDt?: number
        error?: string
      }

      if (payload.success && payload.already_processed) {
        setState('already_processed')
        setMessage('이미 처리된 결제입니다.')
        return
      }

      if (payload.success) {
        setState('success')
        setCreditedDt(typeof payload.creditedDt === 'number' ? payload.creditedDt : null)
        setMessage('결제가 확인되었습니다.')
        return
      }

      setState('failed')
      setMessage(payload.error ?? '결제 확인에 실패했습니다.')
    }

    void run()
  }, [amountParam, orderId, paymentKey])

  return (
    <main className="mx-auto max-w-2xl px-4 py-16">
      <div className="rounded-2xl border border-gray-200 bg-white p-6 shadow-sm">
        <h1 className="text-2xl font-bold text-gray-900">결제 결과</h1>
        <p className="mt-3 text-sm text-gray-600">주문 ID: {orderId || '-'}</p>

        {state === 'loading' && (
          <p className="mt-6 text-sm text-gray-600">결제를 확인하고 있습니다...</p>
        )}

        {state === 'success' && (
          <div className="mt-6 space-y-2">
            <p className="text-sm font-medium text-green-700">{message}</p>
            {creditedDt != null && (
              <p className="text-sm text-gray-700">충전된 DT: {creditedDt.toLocaleString()} DT</p>
            )}
          </div>
        )}

        {state === 'already_processed' && (
          <p className="mt-6 text-sm font-medium text-blue-700">{message}</p>
        )}

        {state === 'failed' && (
          <p className="mt-6 text-sm font-medium text-red-700">{message}</p>
        )}

        <div className="mt-8 flex gap-3">
          <Link
            href={routes.store.dt}
            className="rounded-lg border border-gray-200 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
          >
            DT 스토어로 이동
          </Link>
          <Link
            href={routes.home}
            className="rounded-lg bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-700"
          >
            홈으로 이동
          </Link>
        </div>
      </div>
    </main>
  )
}

export default function PaymentSuccessPage() {
  return (
    <Suspense fallback={<main className="mx-auto max-w-2xl px-4 py-16 text-sm text-gray-600">결제 결과를 불러오는 중...</main>}>
      <PaymentSuccessContent />
    </Suspense>
  )
}
