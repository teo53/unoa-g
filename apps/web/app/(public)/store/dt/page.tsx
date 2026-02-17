import type { Metadata } from 'next'

import { DtStoreContent } from './dt-store-content'

export const metadata: Metadata = {
  title: 'DT 스토어 | UNO A',
  description: 'DT 패키지 구매 및 사용 안내',
}

export const dynamic = 'force-static'

export default function DtStorePage() {
  return <DtStoreContent />
}
