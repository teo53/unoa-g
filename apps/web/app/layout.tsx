import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: {
    default: 'UNO A - 아티스트와 팬, 가장 가까운 거리',
    template: '%s | UNO A',
  },
  description:
    'K-POP 아티스트와 프라이빗 메시지로 1:1 소통하고, 펀딩으로 특별한 프로젝트를 함께 만들어요. 프리미엄 아티스트-팬 메시지 & 펀딩 플랫폼.',
  keywords: [
    'UNO A',
    'K-POP',
    '아티스트',
    '팬',
    '메시지',
    '펀딩',
    '크리에이터',
    '구독',
    'Bubble',
    'Fromm',
    'fan platform',
  ],
  metadataBase: new URL(
    process.env.NEXT_PUBLIC_APP_URL || 'https://unoa-app-demo.web.app'
  ),
  openGraph: {
    type: 'website',
    locale: 'ko_KR',
    siteName: 'UNO A',
    title: 'UNO A - 아티스트와 팬, 가장 가까운 거리',
    description:
      'K-POP 아티스트와 프라이빗 메시지로 1:1 소통하고, 펀딩으로 특별한 프로젝트를 함께 만들어요.',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'UNO A - 아티스트와 팬, 가장 가까운 거리',
    description:
      'K-POP 아티스트와 프라이빗 메시지로 1:1 소통하고, 펀딩으로 특별한 프로젝트를 함께 만들어요.',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
    },
  },
  icons: {
    icon: '/favicon.ico',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ko">
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  )
}
