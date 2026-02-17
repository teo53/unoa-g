import type { Metadata } from 'next'

import { PricingContent } from './pricing-content'

export const metadata: Metadata = {
  title: '요금제 | UNO A',
  description: 'UNO A 요금제 안내 및 혜택 비교',
}

export const dynamic = 'force-static'

export default function PricingPage() {
  return <PricingContent />
}
