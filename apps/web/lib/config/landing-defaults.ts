/**
 * Default landing page content.
 * Used as fallback when Supabase is unavailable (demo mode, offline, etc.)
 * Also used as seed data for the landing_content table.
 */

export interface LandingFeature {
  icon: string
  title: string
  description: string
}

export interface LandingStat {
  value: number
  suffix: string
  label: string
  prefix: string
}

export interface LandingFooterLink {
  label: string
  href: string
}

export interface LandingContent {
  hero_headline: string
  hero_subheadline: string
  hero_cta_primary: string
  hero_cta_secondary: string
  features: LandingFeature[]
  stats: LandingStat[]
  footer_links: LandingFooterLink[]
  images: Record<string, string>
  updated_at?: string
}

export const LANDING_DEFAULTS: LandingContent = {
  hero_headline: '아티스트와 팬, 가장 가까운 거리',
  hero_subheadline:
    '프라이빗 메시지로 아티스트와 1:1 소통하고, 펀딩으로 특별한 프로젝트를 함께 만들어요.',
  hero_cta_primary: '앱 다운로드',
  hero_cta_secondary: '펀딩 둘러보기',
  features: [
    {
      icon: 'MessageCircle',
      title: '프라이빗 메시지',
      description: '아티스트와 1:1 대화하듯 소통하는 특별한 메시지 경험',
    },
    {
      icon: 'CreditCard',
      title: '펀딩 캠페인',
      description: '아티스트의 프로젝트를 후원하고 독점 리워드를 받으세요',
    },
    {
      icon: 'Heart',
      title: '프라이빗 카드',
      description: '특별한 순간을 담은 아티스트 전용 포토카드 컬렉션',
    },
    {
      icon: 'Vote',
      title: '투표 & VS',
      description:
        '팬들의 의견을 모아 아티스트와 함께 결정하는 인터랙티브 투표',
    },
    {
      icon: 'Cake',
      title: '기념일 축하',
      description: '생일, 데뷔일 등 특별한 날을 팬들과 함께 축하해요',
    },
    {
      icon: 'Sparkles',
      title: 'AI 답글 추천',
      description: '크리에이터를 위한 AI 기반 스마트 답글 제안 기능',
    },
  ],
  stats: [
    { value: 1200, suffix: '+', label: '크리에이터', prefix: '' },
    { value: 58000, suffix: '+', label: '팬 커뮤니티', prefix: '' },
    { value: 3, suffix: '억+', label: '누적 후원금', prefix: '₩' },
    { value: 120, suffix: '만+', label: '메시지 교환', prefix: '' },
  ],
  footer_links: [
    { label: '펀딩', href: '/funding' },
    { label: '크리에이터 스튜디오', href: '/studio' },
    { label: '이용약관', href: '/settings/terms' },
    { label: '개인정보처리방침', href: '/settings/privacy' },
  ],
  images: {},
}
