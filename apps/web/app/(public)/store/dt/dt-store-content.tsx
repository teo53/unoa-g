'use client'

import Link from 'next/link'
import { useState } from 'react'

import { Button } from '@/components/ui/button'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import {
  businessConfig,
  getDtPackagePrice,
  getSavingsPercent,
  type PurchasePlatform,
} from '@/lib/config/business-config'
import { formatKRW } from '@/lib/utils/format'
import { createDtCheckout } from '@/lib/services/checkout-service'
import { routes } from '@/lib/constants/routes'

const platformLabels: Record<PurchasePlatform, string> = {
  web: '웹',
  android: '앱(Android)',
  ios: '앱(iOS)',
}

function getBadge(id: string): string | null {
  if (id === 'dt_500') return '인기'
  if (id === 'dt_1000') return 'BEST'
  if (id === 'dt_5000') return 'VIP'
  return null
}

export function DtStoreContent() {
  const [processingId, setProcessingId] = useState<string | null>(null)

  async function handleBuy(packageId: string) {
    if (processingId) return

    if (DEMO_MODE) {
      alert('데모 모드: 결제는 진행되지 않습니다. (UI 확인용)')
      return
    }

    try {
      setProcessingId(packageId)
      const { checkoutUrl } = await createDtCheckout(packageId)
      window.open(checkoutUrl, '_blank', 'noopener,noreferrer')
    } catch (e: any) {
      console.error(e)
      alert(e?.message ? `결제 생성 실패: ${e.message}` : '결제 생성에 실패했습니다.')
    } finally {
      setProcessingId(null)
    }
  }

  return (
    <div className="min-h-screen bg-white">
      <header className="border-b">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <Link href="/" className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-black rounded-lg flex items-center justify-center">
              <span className="text-white font-bold">U</span>
            </div>
            <span className="text-xl font-bold">UNO A</span>
          </Link>

          <nav className="hidden md:flex items-center space-x-6 text-sm">
            <Link href="/funding" className="text-gray-600 hover:text-gray-900">
              펀딩
            </Link>
            <Link href={routes.pricing} className="text-gray-600 hover:text-gray-900">
              요금제
            </Link>
            <Link href={routes.store.dt} className="text-gray-900 font-medium">
              DT 스토어
            </Link>
            <Link href="/studio" className="text-gray-600 hover:text-gray-900">
              스튜디오
            </Link>
          </nav>

          <div className="flex items-center space-x-3">
            <Link
              href="/studio"
              className="inline-flex items-center justify-center font-medium transition-colors rounded-lg border-2 border-gray-200 text-gray-700 hover:border-primary-500 hover:text-primary-500 text-base px-4 py-2"
            >
              대시보드
            </Link>
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-4 py-12">
        {/* Hero */}
        <section className="py-10">
          <h1 className="text-4xl md:text-5xl font-bold mb-4">DT로 아티스트를 응원하세요</h1>
          <p className="text-xl text-gray-600 mb-6">
            DT는 UNO A 디지털 서비스 이용권입니다. 필요한 만큼 구매해 기능을 이용하고,
            아티스트를 후원할 수 있어요.
          </p>

          <div className="flex flex-wrap items-center gap-3">
            <div className="inline-flex items-center px-4 py-2 rounded-full bg-gray-50 border text-sm text-gray-700">
              웹 구매는 최저가 · VAT 포함
            </div>
            <div className="text-sm text-gray-500">
              자세한 사용 안내: <span className="underline">/legal/dt-usage</span>
            </div>
          </div>
        </section>

        {/* Packages */}
        <section className="py-8">
          <h2 className="text-2xl font-bold mb-4">DT 패키지</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {businessConfig.dtPackagesByPlatform.map((p) => {
              const webPrice = getDtPackagePrice(p.id, 'web')
              const iosPrice = getDtPackagePrice(p.id, 'ios')
              const androidPrice = getDtPackagePrice(p.id, 'android')
              const savings = getSavingsPercent(iosPrice, webPrice)
              const badge = getBadge(p.id)

              return (
                <div key={p.id} className="border rounded-2xl p-6 bg-white shadow-sm relative">
                  {badge && (
                    <div className="absolute top-4 right-4 text-xs font-bold px-3 py-1 rounded-full bg-black text-white">
                      {badge}
                    </div>
                  )}

                  <div className="mb-2">
                    <div className="text-xl font-bold">
                      {p.dt.toLocaleString()} DT
                      {p.bonus > 0 && <span className="text-sm text-gray-500"> + {p.bonus.toLocaleString()} 보너스</span>}
                    </div>
                    <div className="text-sm text-gray-600 mt-1">총 { (p.dt + p.bonus).toLocaleString() } DT</div>
                  </div>

                  <div className="mb-4">
                    <div className="text-3xl font-bold">{formatKRW(webPrice)}</div>
                    <div className="text-sm text-gray-500 mt-1">
                      {platformLabels.ios}: {formatKRW(iosPrice)} · {platformLabels.android}: {formatKRW(androidPrice)}
                    </div>
                    <div className="text-sm text-gray-600 mt-1">웹에서 약 {savings}% 절약 (iOS 기준)</div>
                  </div>

                  <Button
                    className="w-full"
                    disabled={processingId === p.id}
                    onClick={() => handleBuy(p.id)}
                  >
                    {processingId === p.id ? '처리 중...' : 'DT 구매하기'}
                  </Button>
                </div>
              )
            })}
          </div>
        </section>

        {/* How to use */}
        <section className="py-10">
          <h2 className="text-2xl font-bold mb-3">DT 활용 방법</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="border rounded-2xl p-6 bg-gray-50">
              <div className="font-bold mb-2">1) 구매</div>
              <p className="text-sm text-gray-600">웹에서 DT 패키지를 구매합니다.</p>
            </div>
            <div className="border rounded-2xl p-6 bg-gray-50">
              <div className="font-bold mb-2">2) 사용</div>
              <p className="text-sm text-gray-600">후원/기능 사용 등에 DT를 사용합니다.</p>
            </div>
            <div className="border rounded-2xl p-6 bg-gray-50">
              <div className="font-bold mb-2">3) 정산</div>
              <p className="text-sm text-gray-600">크리에이터 수익으로 정산됩니다.</p>
            </div>
          </div>
        </section>

        {/* Legal */}
        <section className="py-10">
          <h2 className="text-2xl font-bold mb-3">안내</h2>
          <div className="text-sm text-gray-600 space-y-2">
            <p>• 표시된 금액은 VAT(부가가치세)가 포함된 금액입니다.</p>
            <p>• 결제 완료 후 DT가 반영되기까지 수 분 정도 지연될 수 있습니다.</p>
            <p>• 환불은 결제 완료 후 일정 기간 내, 사용하지 않은 DT에 한해 처리될 수 있습니다.</p>
          </div>
        </section>
      </main>
    </div>
  )
}
