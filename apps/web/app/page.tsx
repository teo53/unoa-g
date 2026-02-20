'use client'

import Link from 'next/link'
import { PhoneMockup } from '@/components/landing/phone-mockup'
import { AnimatedCounter } from '@/components/landing/animated-counter'
import { FeatureCard } from '@/components/landing/feature-card'
import { ScrollReveal } from '@/components/landing/scroll-reveal'
import {
  MessageCircle,
  Heart,
  CreditCard,
  Vote,
  Cake,
  Sparkles,
  ChevronDown,
  Download,
  ArrowRight,
} from 'lucide-react'

export default function HomePage() {
  return (
    <div className="min-h-screen bg-white overflow-hidden">
      {/* ============================================
          HEADER - Sticky transparent nav
          ============================================ */}
      <header className="fixed top-0 left-0 right-0 z-50 bg-white/80 backdrop-blur-md border-b border-gray-100/50">
        <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
          <Link href="/" className="text-2xl font-bold text-primary-500 tracking-tight">
            UNO A
          </Link>
          <nav className="flex items-center gap-3">
            <Link
              href="/funding"
              className="hidden sm:inline-flex text-gray-600 hover:text-gray-900 transition-colors text-sm font-medium"
            >
              펀딩
            </Link>
            <Link
              href="/studio"
              className="px-5 py-2 bg-primary-500 text-white rounded-full text-sm font-semibold hover:bg-primary-600 transition-all hover:shadow-lg hover:shadow-primary-500/25"
            >
              시작하기
            </Link>
          </nav>
        </div>
      </header>

      {/* ============================================
          SECTION 1: HERO - Full viewport
          ============================================ */}
      <section className="relative min-h-screen flex items-center justify-center pt-16 overflow-hidden">
        {/* Animated gradient background */}
        <div className="absolute inset-0 bg-gradient-to-br from-red-50 via-pink-50 to-purple-50 animate-gradient" />

        {/* Floating decorative elements */}
        <div className="absolute top-32 left-[10%] w-72 h-72 bg-primary-500/5 rounded-full blur-3xl animate-float" />
        <div className="absolute bottom-32 right-[10%] w-96 h-96 bg-purple-500/5 rounded-full blur-3xl animate-float-slow" />
        <div className="absolute top-1/2 left-1/4 w-4 h-4 bg-primary-500/20 rounded-full animate-float" />
        <div className="absolute top-1/3 right-1/3 w-3 h-3 bg-pink-400/30 rounded-full animate-float-slow" />

        <div className="relative z-10 max-w-6xl mx-auto px-4 py-20 flex flex-col lg:flex-row items-center gap-12 lg:gap-20">
          {/* Left: Text content */}
          <div className="flex-1 text-center lg:text-left">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/80 backdrop-blur rounded-full border border-primary-100 text-primary-600 text-sm font-medium mb-6">
              <span className="w-2 h-2 bg-primary-500 rounded-full animate-pulse" />
              K-POP 아티스트 메시지 플랫폼
            </div>
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold text-gray-900 leading-tight mb-6">
              아티스트와 팬,
              <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-500 to-pink-500">
                가장 가까운 거리
              </span>
            </h1>
            <p className="text-lg sm:text-xl text-gray-500 leading-relaxed mb-8 max-w-lg mx-auto lg:mx-0">
              프라이빗 메시지로 아티스트와 1:1 소통하고,
              <br className="hidden sm:block" />
              펀딩으로 특별한 프로젝트를 함께 만들어요.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
              <Link
                href="/funding"
                className="group inline-flex items-center justify-center gap-2 px-8 py-4 bg-primary-500 text-white rounded-full text-lg font-semibold hover:bg-primary-600 transition-all hover:shadow-xl hover:shadow-primary-500/30 hover:-translate-y-0.5"
              >
                앱 다운로드
                <Download className="w-5 h-5 group-hover:translate-y-0.5 transition-transform" />
              </Link>
              <Link
                href="/funding"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-white/80 backdrop-blur text-gray-700 rounded-full text-lg font-semibold border-2 border-gray-200 hover:border-primary-300 hover:text-primary-600 transition-all"
              >
                펀딩 둘러보기
              </Link>
            </div>
          </div>

          {/* Right: Phone mockup */}
          <div className="flex-shrink-0 animate-float-slow">
            <div className="animate-glow-pulse rounded-[48px]">
              <PhoneMockup variant="fan" />
            </div>
          </div>
        </div>

        {/* Scroll indicator */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-gray-400">
          <span className="text-xs font-medium tracking-widest uppercase">Scroll</span>
          <ChevronDown className="w-5 h-5 animate-bounce-subtle" />
        </div>
      </section>

      {/* ============================================
          SECTION 2: MESSAGING SHOWCASE
          ============================================ */}
      <section className="py-24 sm:py-32 px-4 bg-white">
        <div className="max-w-6xl mx-auto flex flex-col lg:flex-row items-center gap-16 lg:gap-24">
          {/* Left: Text */}
          <ScrollReveal direction="left" className="flex-1">
            <div className="max-w-lg">
              <span className="inline-block px-3 py-1 bg-primary-50 text-primary-600 text-xs font-bold tracking-wide uppercase rounded-full mb-4">
                Messaging
              </span>
              <h2 className="text-3xl sm:text-4xl font-extrabold text-gray-900 mb-6 leading-tight">
                1:1 프라이빗 메시지
                <br />
                <span className="text-primary-500">나만의 대화</span>
              </h2>
              <div className="space-y-4">
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-primary-50 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <MessageCircle className="w-4 h-4 text-primary-500" />
                  </div>
                  <div>
                    <h4 className="font-semibold text-gray-900 mb-1">아티스트의 진심 담긴 메시지</h4>
                    <p className="text-sm text-gray-500">아티스트가 보내는 일상, 셀카, 비하인드를 가장 먼저 받아보세요</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-pink-50 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <Heart className="w-4 h-4 text-pink-500" />
                  </div>
                  <div>
                    <h4 className="font-semibold text-gray-900 mb-1">답장 토큰으로 직접 소통</h4>
                    <p className="text-sm text-gray-500">구독 티어에 따른 답장 토큰으로 아티스트에게 마음을 전하세요</p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-purple-50 flex items-center justify-center flex-shrink-0 mt-0.5">
                    <Sparkles className="w-4 h-4 text-purple-500" />
                  </div>
                  <div>
                    <h4 className="font-semibold text-gray-900 mb-1">이모지 리액션 & 프리미엄</h4>
                    <p className="text-sm text-gray-500">VIP 전용 이모지, 구독 기간별 글자 수 확장 등 특별한 혜택</p>
                  </div>
                </div>
              </div>
            </div>
          </ScrollReveal>

          {/* Right: Phone */}
          <ScrollReveal direction="right" className="flex-shrink-0">
            <PhoneMockup variant="fan" />
          </ScrollReveal>
        </div>
      </section>

      {/* ============================================
          SECTION 3: FUNDING SHOWCASE
          ============================================ */}
      <section className="py-24 sm:py-32 px-4 bg-gradient-to-b from-gray-50 to-white">
        <div className="max-w-6xl mx-auto flex flex-col-reverse lg:flex-row items-center gap-16 lg:gap-24">
          {/* Left: Campaign cards */}
          <ScrollReveal direction="left" className="flex-shrink-0">
            <div className="grid grid-cols-2 gap-4 max-w-sm">
              {[
                { title: '1st 앨범 프로젝트', progress: 87, amount: '4,350만', daysLeft: 12 },
                { title: '팬미팅 in 서울', progress: 62, amount: '1,860만', daysLeft: 24 },
                { title: '포토북 제작', progress: 95, amount: '2,850만', daysLeft: 3 },
                { title: '일본 콘서트 투어', progress: 41, amount: '8,200만', daysLeft: 45 },
              ].map((campaign, i) => (
                <div
                  key={i}
                  className="group p-4 bg-white rounded-2xl border border-gray-100 hover:border-primary-200 hover:shadow-lg transition-all duration-300 hover:-translate-y-1"
                >
                  <div className="w-full h-24 bg-gradient-to-br from-primary-50 to-pink-50 rounded-xl mb-3 flex items-center justify-center">
                    <span className="text-2xl">{['🎵', '🎤', '📸', '✈️'][i]}</span>
                  </div>
                  <h4 className="text-sm font-bold text-gray-900 mb-2 truncate">{campaign.title}</h4>
                  <div className="w-full h-2 bg-gray-100 rounded-full overflow-hidden mb-2">
                    <div
                      className="h-full bg-gradient-to-r from-primary-500 to-pink-500 rounded-full transition-all duration-1000"
                      style={{ width: `${campaign.progress}%` }}
                    />
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-xs font-bold text-primary-500">{campaign.progress}%</span>
                    <span className="text-xs text-gray-400">D-{campaign.daysLeft}</span>
                  </div>
                  <p className="text-xs text-gray-500 mt-1">₩{campaign.amount}</p>
                </div>
              ))}
            </div>
          </ScrollReveal>

          {/* Right: Text */}
          <ScrollReveal direction="right" className="flex-1">
            <div className="max-w-lg">
              <span className="inline-block px-3 py-1 bg-pink-50 text-pink-600 text-xs font-bold tracking-wide uppercase rounded-full mb-4">
                Funding
              </span>
              <h2 className="text-3xl sm:text-4xl font-extrabold text-gray-900 mb-6 leading-tight">
                함께 만드는
                <br />
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-pink-500 to-purple-500">
                  특별한 프로젝트
                </span>
              </h2>
              <p className="text-gray-500 leading-relaxed mb-6">
                좋아하는 아티스트의 앨범, 콘서트, 포토북 등
                다양한 프로젝트에 참여하고 세상에 하나뿐인
                리워드를 받아보세요.
              </p>
              <div className="space-y-3">
                {[
                  '실시간 펀딩 현황과 목표 달성률 확인',
                  '티어별 특별 리워드 (사인 앨범, 영상 통화 등)',
                  '안전한 결제와 투명한 프로젝트 운영',
                ].map((item, i) => (
                  <div key={i} className="flex items-center gap-3">
                    <div className="w-5 h-5 rounded-full bg-gradient-to-r from-pink-500 to-purple-500 flex items-center justify-center flex-shrink-0">
                      <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                      </svg>
                    </div>
                    <span className="text-sm text-gray-600">{item}</span>
                  </div>
                ))}
              </div>
            </div>
          </ScrollReveal>
        </div>
      </section>

      {/* ============================================
          SECTION 4: FEATURE HIGHLIGHTS
          ============================================ */}
      <section className="py-24 sm:py-32 px-4 bg-white">
        <div className="max-w-6xl mx-auto">
          <ScrollReveal className="text-center mb-16">
            <span className="inline-block px-3 py-1 bg-gray-100 text-gray-600 text-xs font-bold tracking-wide uppercase rounded-full mb-4">
              Features
            </span>
            <h2 className="text-3xl sm:text-4xl font-extrabold text-gray-900 mb-4">
              UNO A가 특별한 이유
            </h2>
            <p className="text-gray-500 max-w-xl mx-auto">
              아티스트와 팬 모두를 위한 올인원 플랫폼
            </p>
          </ScrollReveal>

          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                icon: <MessageCircle className="w-7 h-7 text-white" />,
                title: '프라이빗 메시지',
                description: '아티스트와 1:1 대화하듯 소통하는 특별한 메시지 경험',
                gradient: 'bg-gradient-to-br from-primary-500 to-rose-500',
              },
              {
                icon: <CreditCard className="w-7 h-7 text-white" />,
                title: '펀딩 캠페인',
                description: '아티스트의 프로젝트를 후원하고 독점 리워드를 받으세요',
                gradient: 'bg-gradient-to-br from-pink-500 to-purple-500',
              },
              {
                icon: <Heart className="w-7 h-7 text-white" />,
                title: '프라이빗 카드',
                description: '특별한 순간을 담은 아티스트 전용 포토카드 컬렉션',
                gradient: 'bg-gradient-to-br from-purple-500 to-indigo-500',
              },
              {
                icon: <Vote className="w-7 h-7 text-white" />,
                title: '투표 & VS',
                description: '팬들의 의견을 모아 아티스트와 함께 결정하는 인터랙티브 투표',
                gradient: 'bg-gradient-to-br from-blue-500 to-cyan-500',
              },
              {
                icon: <Cake className="w-7 h-7 text-white" />,
                title: '기념일 축하',
                description: '생일, 데뷔일 등 특별한 날을 팬들과 함께 축하해요',
                gradient: 'bg-gradient-to-br from-amber-500 to-orange-500',
              },
              {
                icon: <Sparkles className="w-7 h-7 text-white" />,
                title: 'AI 답글 추천',
                description: '크리에이터를 위한 AI 기반 스마트 답글 제안 기능',
                gradient: 'bg-gradient-to-br from-emerald-500 to-teal-500',
              },
            ].map((feature, i) => (
              <ScrollReveal key={i} delay={i * 100}>
                <FeatureCard {...feature} />
              </ScrollReveal>
            ))}
          </div>
        </div>
      </section>


      {/* ============================================
          SECTION 5: STATS COUNTER
          ============================================ */}
      <section className="py-24 sm:py-32 px-4 relative overflow-hidden">
        {/* Gradient background */}
        <div className="absolute inset-0 bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(255,59,48,0.15),transparent_60%)]" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_left,rgba(168,85,247,0.1),transparent_60%)]" />

        <div className="relative z-10 max-w-5xl mx-auto">
          <ScrollReveal className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">
              함께 성장하는 커뮤니티
            </h2>
            <p className="text-gray-400 max-w-lg mx-auto">
              UNO A에서 아티스트와 팬이 만들어가는 새로운 이야기
            </p>
          </ScrollReveal>

          <div className="grid grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              { value: 1200, suffix: '+', label: '크리에이터', prefix: '' },
              { value: 58000, suffix: '+', label: '팬 커뮤니티', prefix: '' },
              { value: 3, suffix: '억+', label: '누적 후원금', prefix: '₩' },
              { value: 120, suffix: '만+', label: '메시지 교환', prefix: '' },
            ].map((stat, i) => (
              <ScrollReveal key={i} delay={i * 150}>
                <div className="text-center p-6 rounded-2xl bg-white/5 backdrop-blur border border-white/10 hover:bg-white/10 transition-all">
                  <div className="text-3xl sm:text-4xl font-extrabold text-white mb-2">
                    <span className="text-primary-400">{stat.prefix}</span>
                    <AnimatedCounter value={stat.value} />
                    <span className="text-primary-400">{stat.suffix}</span>
                  </div>
                  <p className="text-sm text-gray-400 font-medium">{stat.label}</p>
                </div>
              </ScrollReveal>
            ))}
          </div>
        </div>
      </section>

      {/* ============================================
          SECTION 6: CTA - Download
          ============================================ */}
      <section className="py-24 sm:py-32 px-4 bg-white relative overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(255,59,48,0.05),transparent_70%)]" />

        <ScrollReveal className="relative z-10 max-w-3xl mx-auto text-center">
          <h2 className="text-3xl sm:text-4xl font-extrabold text-gray-900 mb-4">
            지금 시작하세요
          </h2>
          <p className="text-gray-500 mb-10 text-lg max-w-md mx-auto">
            좋아하는 아티스트와 더 가까워지는
            <br />
            가장 특별한 방법
          </p>

          {/* App Store buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-10">
            <a
              href="#"
              className="group inline-flex items-center gap-3 px-6 py-3.5 bg-gray-900 text-white rounded-xl hover:bg-gray-800 transition-all hover:shadow-xl hover:-translate-y-0.5"
            >
              <svg className="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              <div className="text-left">
                <div className="text-[10px] text-gray-300 leading-none">Download on the</div>
                <div className="text-lg font-semibold leading-tight">App Store</div>
              </div>
            </a>
            <a
              href="#"
              className="group inline-flex items-center gap-3 px-6 py-3.5 bg-gray-900 text-white rounded-xl hover:bg-gray-800 transition-all hover:shadow-xl hover:-translate-y-0.5"
            >
              <svg className="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
                <path d="M3.18 23.67c-.37.2-.81-.1-.81-.55V.88c0-.45.44-.76.81-.55l17.04 10.22c.37.21.37.76 0 .97L3.18 23.67z" opacity="0.35"/>
                <path d="M3.18.33l9.93 11.5L3.18 23.67c-.37.2-.81-.1-.81-.55V.88c0-.45.44-.76.81-.55z"/>
                <path d="M3.18.33L13.11 11.83l5.36-6.2L3.18.33z" opacity="0.12"/>
                <path d="M3.18 23.67L13.11 11.83l5.36 6.2L3.18 23.67z" opacity="0.12"/>
              </svg>
              <div className="text-left">
                <div className="text-[10px] text-gray-300 leading-none">GET IT ON</div>
                <div className="text-lg font-semibold leading-tight">Google Play</div>
              </div>
            </a>
          </div>

          <p className="text-xs text-gray-400">
            출시 예정 - 사전 등록하고 가장 먼저 만나보세요
          </p>
        </ScrollReveal>
      </section>

      {/* ============================================
          SECTION 7: FOOTER
          ============================================ */}
      <footer className="py-12 px-4 bg-gray-900 text-white">
        <div className="max-w-6xl mx-auto">
          {/* Top row */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-12">
            {/* Brand */}
            <div className="col-span-2 md:col-span-1">
              <div className="text-2xl font-bold mb-3 text-primary-400">UNO A</div>
              <p className="text-sm text-gray-400 leading-relaxed">
                아티스트와 팬을 잇는
                <br />프리미엄 메시지 & 펀딩 플랫폼
              </p>
            </div>

            {/* Product */}
            <div>
              <h4 className="text-sm font-semibold text-gray-300 mb-3 uppercase tracking-wide">Product</h4>
              <ul className="space-y-2">
                <li><Link href="/funding" className="text-sm text-gray-400 hover:text-white transition-colors">펀딩</Link></li>
                <li><Link href="/studio" className="text-sm text-gray-400 hover:text-white transition-colors">크리에이터 스튜디오</Link></li>
              </ul>
            </div>

            {/* Legal */}
            <div>
              <h4 className="text-sm font-semibold text-gray-300 mb-3 uppercase tracking-wide">Legal</h4>
              <ul className="space-y-2">
                <li><Link href="/settings/terms" className="text-sm text-gray-400 hover:text-white transition-colors">이용약관</Link></li>
                <li><Link href="/settings/privacy" className="text-sm text-gray-400 hover:text-white transition-colors">개인정보처리방침</Link></li>
              </ul>
            </div>

            {/* Social */}
            <div>
              <h4 className="text-sm font-semibold text-gray-300 mb-3 uppercase tracking-wide">Social</h4>
              <div className="flex gap-3">
                {/* Instagram */}
                <a href="#" className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors" aria-label="Instagram">
                  <svg className="w-4 h-4 text-gray-300" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/>
                  </svg>
                </a>
                {/* Twitter/X */}
                <a href="#" className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors" aria-label="Twitter">
                  <svg className="w-4 h-4 text-gray-300" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
                  </svg>
                </a>
                {/* YouTube */}
                <a href="#" className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors" aria-label="YouTube">
                  <svg className="w-4 h-4 text-gray-300" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M23.498 6.186a3.016 3.016 0 00-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 00.502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 002.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 002.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                  </svg>
                </a>
              </div>
            </div>
          </div>

          {/* Bottom row */}
          <div className="pt-8 border-t border-gray-800 flex flex-col sm:flex-row justify-between items-center gap-4">
            <p className="text-sm text-gray-500">
              &copy; {new Date().getFullYear()} UNO A. All rights reserved.
            </p>
            <p className="text-xs text-gray-600">
              Built with love for K-POP artists and fans
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}
