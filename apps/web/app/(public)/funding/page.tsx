import type { Metadata } from 'next'
import FundingContent from './funding-content'

export const metadata: Metadata = {
  title: '펀딩 둘러보기',
  description: '다양한 크리에이터들의 펀딩 프로젝트를 만나보세요.',
  openGraph: {
    title: '펀딩 둘러보기 | UNO A',
    description: '다양한 크리에이터들의 펀딩 프로젝트를 만나보세요.',
  },
}

// Required for static export
export const dynamic = 'force-static'

export default function FundingPage() {
  return <FundingContent />
}
