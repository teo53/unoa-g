'use client'

import Link from 'next/link'
import { useMemo } from 'react'

import { Button } from '@/components/ui/button'
import { DEMO_MODE } from '@/lib/mock/demo-data'
import {
  businessConfig,
  tiers,
  getSavingsPercent,
  type Tier,
} from '@/lib/config/business-config'
import { formatKRW } from '@/lib/utils/format'
import { routes } from '@/lib/constants/routes'

function getTokensForTier(tier: Tier): number {
  const bonus = businessConfig.tokenRules.bonusTokensByTier[tier] ?? 0
  return businessConfig.tokenRules.baseTokensPerBroadcast + bonus
}

export function PricingContent() {
  const timeline = useMemo(() => {
    const entries = Object.entries(businessConfig.characterLimitsByDays)
      .map(([day, limit]) => ({ day: Number(day), limit }))
      .sort((a, b) => a.day - b.day)

    // remove duplicates (e.g., Day 0 and Day 50 both 50)
    const unique: { day: number; limit: number }[] = []
    for (const e of entries) {
      if (unique.length === 0 || unique[unique.length - 1].limit !== e.limit) {
        unique.push(e)
      }
    }
    return unique
  }, [])

  const maxSavings = useMemo(() => {
    // compute max savings vs iOS (largest gap)
    return Math.max(
      ...tiers.map((t) =>
        getSavingsPercent(
          businessConfig.tierPricesByPlatform.ios[t],
          businessConfig.tierPricesByPlatform.web[t],
        ),
      ),
    )
  }, [])

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
            <Link href={routes.pricing} className="text-gray-900 font-medium">
              요금제
            </Link>
            <Link href={routes.store.dt} className="text-gray-600 hover:text-gray-900">
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
        <section className="text-center py-10">
          <h1 className="text-4xl md:text-5xl font-bold mb-4">좋아하는 아티스트와 더 가까이</h1>
          <p className="text-xl text-gray-600 mb-6">
            구독 등급에 따라 더 많은 답글 토큰과 프라이빗 기능을 이용할 수 있어요.
          </p>

          <div className="inline-flex items-center px-4 py-2 rounded-full bg-gray-50 border text-sm text-gray-700">
            웹에서 최대 약 {maxSavings}% 절약 · VAT 포함
          </div>
        </section>

        {/* Tier comparison */}
        <section className="py-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {tiers.map((tier) => {
              const webPrice = businessConfig.tierPricesByPlatform.web[tier]
              const androidPrice = businessConfig.tierPricesByPlatform.android[tier]
              const iosPrice = businessConfig.tierPricesByPlatform.ios[tier]
              const savings = getSavingsPercent(iosPrice, webPrice)
              const tokens = getTokensForTier(tier)
              const benefits = businessConfig.tierBenefits[tier]

              return (
                <div key={tier} className="border rounded-2xl p-6 bg-white shadow-sm">
                  <div className="flex items-baseline justify-between mb-2">
                    <h3 className="text-xl font-bold">{tier}</h3>
                    <span className="text-xs text-gray-500">월 구독</span>
                  </div>

                  <div className="mb-3">
                    <div className="text-3xl font-bold">{formatKRW(webPrice)}</div>
                    <div className="text-sm text-gray-500 mt-1">
                      앱(iOS): {formatKRW(iosPrice)} · 앱(Android): {formatKRW(androidPrice)}
                    </div>
                    <div className="text-sm text-gray-600 mt-1">웹에서 약 {savings}% 절약 (iOS 기준)</div>
                  </div>

                  <div className="mb-4">
                    <div className="text-sm font-medium">답글 토큰</div>
                    <div className="text-sm text-gray-600">브로드캐스트당 {tokens}개</div>
                  </div>

                  <ul className="space-y-2 text-sm text-gray-700 mb-6">
                    {benefits.map((b) => (
                      <li key={b} className="flex items-start gap-2">
                        <span className="mt-0.5">✓</span>
                        <span>{b}</span>
                      </li>
                    ))}
                  </ul>

                  <Button
                    className="w-full"
                    onClick={() => {
                      if (DEMO_MODE) {
                        alert(`데모 모드: ${tier} 구독 결제는 진행되지 않습니다.`)
                        return
                      }
                      alert('웹 구독 결제는 현재 준비 중입니다. (DT 구매는 가능)')
                    }}
                  >
                    {tier} 시작하기
                  </Button>
                </div>
              )
            })}
          </div>
        </section>

        {/* Character limit timeline */}
        <section className="py-10">
          <h2 className="text-2xl font-bold mb-3">글자수 한도는 어떻게 늘어나나요?</h2>
          <p className="text-gray-600 mb-6">
            구독 등급과 별개로, 구독을 오래 유지할수록 메시지 글자수 한도가 단계적으로 증가합니다.
          </p>

          <div className="grid grid-cols-2 md:grid-cols-6 gap-3">
            {timeline.map((t) => (
              <div key={t.day} className="border rounded-xl p-4 bg-gray-50">
                <div className="text-xs text-gray-500">Day {t.day}</div>
                <div className="text-lg font-bold">{t.limit}자</div>
              </div>
            ))}
          </div>
        </section>

        {/* Why web cheaper */}
        <section className="py-10">
          <h2 className="text-2xl font-bold mb-3">웹이 왜 더 저렴한가요?</h2>
          <div className="border rounded-2xl p-6 bg-white">
            <ul className="space-y-2 text-sm text-gray-700">
              <li>• 앱 내 결제는 스토어 정책에 따라 인앱결제 수수료가 포함될 수 있습니다.</li>
              <li>• 웹 결제는 상대적으로 낮은 결제 수수료 구조를 적용할 수 있어, 동일 상품을 더 낮은 가격에 제공할 수 있습니다.</li>
              <li>• 모든 표시는 VAT 포함 가격입니다.</li>
            </ul>
          </div>
        </section>

        {/* Legal */}
        <section className="py-10">
          <h2 className="text-2xl font-bold mb-3">안내</h2>
          <div className="text-sm text-gray-600 space-y-2">
            <p>• 표시된 금액은 VAT(부가가치세)가 포함된 금액입니다.</p>
            <p>• 구독 결제/해지는 결제한 플랫폼의 정책 및 설정 경로에 따릅니다.</p>
          </div>
        </section>
      </main>
    </div>
  )
}
