import Link from 'next/link'
import { PageLayout } from '@/components/shared/page-layout'
import { StatsCounter } from '@/components/shared/stats-counter'
import { ROUTES } from '@/lib/constants/routes'
import { mockCampaigns, mockCreators } from '@/lib/mock/demo-data'
import { formatFundingAmount, formatPercent, formatDaysLeft } from '@/lib/utils/format'

export default function HomePage() {
  const featured = mockCampaigns
    .filter((c) => c.status === 'active')
    .sort((a, b) => (b.current_amount_dt / b.goal_amount_dt) - (a.current_amount_dt / a.goal_amount_dt))
    .slice(0, 3)

  const totalFunding = mockCampaigns.reduce((sum, c) => sum + c.current_amount_dt, 0)
  const totalBackers = mockCampaigns.reduce((sum, c) => sum + c.backer_count, 0)
  const activeCampaignCount = mockCampaigns.filter((c) => c.status === 'active').length

  return (
    <PageLayout variant="public" maxWidth="full" contentClassName="!px-0 !py-0">

      {/* ══════════════════════════════════════════════════════ */}
      {/* 1. HERO — 가치 제안을 5초 안에 전달                   */}
      {/* ══════════════════════════════════════════════════════ */}
      <section
        className="relative overflow-hidden flex items-center min-h-[92vh] px-4 py-24 sm:py-32"
        style={{ background: 'linear-gradient(160deg, #0A0A0F 0%, #0D080E 45%, #0A0A0F 100%)' }}
      >
        {/* Background glow orbs */}
        <div
          className="hero-orb absolute pointer-events-none"
          style={{
            width: 800,
            height: 800,
            top: '-10%',
            left: '40%',
            background: 'radial-gradient(ellipse, rgba(255,59,48,0.11) 0%, transparent 65%)',
          }}
        />
        <div
          className="hero-orb absolute pointer-events-none"
          style={{
            width: 350,
            height: 350,
            bottom: '10%',
            left: '15%',
            background: 'radial-gradient(ellipse, rgba(255,59,48,0.05) 0%, transparent 70%)',
          }}
        />

        <div className="relative mx-auto max-w-content w-full">
          <div className="grid lg:grid-cols-2 gap-16 items-center">

            {/* Left: Core value proposition */}
            <div className="hero-text-enter">
              {/* Platform category badge */}
              <div
                className="inline-flex items-center gap-2 rounded-full px-4 py-1.5 mb-8 text-sm font-medium"
                style={{
                  background: 'rgba(255, 59, 48, 0.08)',
                  border: '1px solid rgba(255, 59, 48, 0.2)',
                  color: '#FF3B30',
                }}
              >
                <span className="relative flex h-2 w-2">
                  <span
                    className="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75"
                    style={{ background: '#FF3B30' }}
                  />
                  <span
                    className="relative inline-flex rounded-full h-2 w-2"
                    style={{ background: '#FF3B30' }}
                  />
                </span>
                아티스트 구독 메시지 & 크라우드펀딩
              </div>

              {/* Headline — clear what UNO A is, no 1:1 illusion */}
              <h1
                className="text-5xl sm:text-6xl xl:text-[4rem] font-bold leading-[1.07] tracking-tight"
                style={{ color: '#FFFFFF' }}
              >
                아티스트의
                <br />
                <span style={{ color: '#FF3B30' }}>프라이빗 메시지</span>를
                <br />
                구독자만 받으세요
              </h1>

              {/* Value sub-copy — accurate: broadcast to subscribers, not 1:1 */}
              <p
                className="mt-7 text-lg leading-relaxed max-w-[440px]"
                style={{ color: '#8B8B9B' }}
              >
                아티스트가 구독자에게 직접 보내는 소식을
                나만의 피드에서 받아보세요. 크라우드펀딩으로
                아티스트의 새 프로젝트를 함께 만들어가세요.
              </p>

              {/* Primary CTAs */}
              <div className="mt-10 flex flex-wrap gap-4">
                <Link
                  href={ROUTES.pricing}
                  className="inline-flex items-center gap-2 rounded-xl px-7 py-3.5 text-base font-semibold text-white transition-all hover:scale-[1.02] active:scale-[0.98]"
                  style={{
                    background: '#FF3B30',
                    boxShadow: '0 0 28px rgba(255, 59, 48, 0.38)',
                  }}
                >
                  구독 시작하기
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                  </svg>
                </Link>
                <Link
                  href={ROUTES.funding}
                  className="inline-flex items-center gap-2 rounded-xl px-7 py-3.5 text-base font-semibold transition-all hover:scale-[1.02] active:scale-[0.98]"
                  style={{
                    background: 'rgba(255, 255, 255, 0.06)',
                    border: '1px solid rgba(255, 255, 255, 0.14)',
                    color: '#FFFFFF',
                  }}
                >
                  펀딩 둘러보기
                </Link>
              </div>

              {/* Social proof strip */}
              <div className="mt-8 flex items-center gap-6">
                <div className="flex flex-col">
                  <span className="text-xl font-bold" style={{ color: '#FFFFFF' }}>
                    {activeCampaignCount}+
                  </span>
                  <span className="text-xs" style={{ color: '#6B6B7B' }}>진행 중 캠페인</span>
                </div>
                <div className="w-px h-8" style={{ background: 'rgba(255,255,255,0.1)' }} />
                <div className="flex flex-col">
                  <span className="text-xl font-bold" style={{ color: '#FFFFFF' }}>
                    {totalBackers.toLocaleString('ko-KR')}명
                  </span>
                  <span className="text-xs" style={{ color: '#6B6B7B' }}>누적 참여자</span>
                </div>
                <div className="w-px h-8" style={{ background: 'rgba(255,255,255,0.1)' }} />
                <div className="flex flex-col">
                  <span className="text-xl font-bold" style={{ color: '#FFFFFF' }}>3개
                  </span>
                  <span className="text-xs" style={{ color: '#6B6B7B' }}>구독 티어</span>
                </div>
              </div>
            </div>

            {/* Right: App experience preview */}
            <div className="hero-visual-enter hidden lg:flex flex-col gap-4 relative">

              {/* Simulated chat conversation UI */}
              <div
                className="floating-card rounded-2xl overflow-hidden"
                style={{
                  background: '#141418',
                  border: '1px solid rgba(255,255,255,0.08)',
                  boxShadow: '0 28px 70px rgba(0,0,0,0.55)',
                }}
              >
                {/* Feed header */}
                <div
                  className="flex items-center gap-3 px-4 py-3"
                  style={{ borderBottom: '1px solid rgba(255,255,255,0.06)' }}
                >
                  <div
                    className="h-8 w-8 rounded-full flex items-center justify-center text-sm font-bold"
                    style={{ background: 'rgba(255,59,48,0.18)', color: '#FF3B30' }}
                  >
                    A
                  </div>
                  <div>
                    <p className="text-sm font-semibold" style={{ color: '#F0F0F0' }}>하늘달</p>
                    <p className="text-xs" style={{ color: '#6B6B7B' }}>구독자 전용 메시지 피드</p>
                  </div>
                  <div className="ml-auto flex items-center gap-1.5">
                    <span
                      className="text-xs px-2 py-0.5 rounded-full font-medium"
                      style={{ background: 'rgba(139,92,246,0.15)', color: '#8B5CF6' }}
                    >
                      VIP
                    </span>
                  </div>
                </div>

                {/* Feed messages */}
                <div className="px-4 py-4 space-y-3">
                  {/* Artist broadcast message */}
                  <div className="flex gap-2.5">
                    <div
                      className="h-7 w-7 flex-shrink-0 rounded-full flex items-center justify-center text-xs font-bold mt-0.5"
                      style={{ background: 'rgba(255,59,48,0.15)', color: '#FF3B30' }}
                    >
                      A
                    </div>
                    <div
                      className="rounded-2xl rounded-tl-sm px-3.5 py-2.5 max-w-[75%]"
                      style={{ background: '#1E1E28' }}
                    >
                      <p className="text-sm" style={{ color: '#E5E5E5' }}>
                        오늘 녹음 끝났어요 여러분 🎵
                        들려드리고 싶은 곡이 생겼는데...
                      </p>
                      <p className="text-xs mt-1" style={{ color: '#4B4B5B' }}>오전 11:32 · 구독자 전체</p>
                    </div>
                  </div>

                  {/* Fan reply (token-based, to artist's message) */}
                  <div className="flex gap-2.5 justify-end">
                    <div
                      className="rounded-2xl rounded-tr-sm px-3.5 py-2.5 max-w-[70%]"
                      style={{ background: 'rgba(255,59,48,0.16)' }}
                    >
                      <p className="text-sm" style={{ color: '#F0F0F0' }}>
                        빨리 듣고 싶어요!! 💕
                      </p>
                      <p className="text-xs mt-1 text-right" style={{ color: '#8B3B30' }}>내 답장 · 토큰 사용</p>
                    </div>
                  </div>

                  {/* Token indicator */}
                  <div className="flex justify-center">
                    <span
                      className="text-xs px-3 py-1 rounded-full"
                      style={{
                        background: 'rgba(255,255,255,0.04)',
                        border: '1px solid rgba(255,255,255,0.08)',
                        color: '#6B6B7B',
                      }}
                    >
                      이번 달 답장 2회 남음
                    </span>
                  </div>
                </div>
              </div>

              {/* Funding campaign mini-card */}
              {featured[0] && (() => {
                const pct = formatPercent(featured[0].current_amount_dt, featured[0].goal_amount_dt)
                return (
                  <div
                    className="floating-card-delay rounded-2xl p-4 ml-8"
                    style={{
                      background: '#141418',
                      border: '1px solid rgba(255,255,255,0.07)',
                      boxShadow: '0 16px 48px rgba(0,0,0,0.4)',
                    }}
                  >
                    <div className="flex items-start gap-3">
                      <div
                        className="h-12 w-12 rounded-xl overflow-hidden flex-shrink-0"
                        style={{ background: '#1E1E28' }}
                      >
                        {featured[0].cover_image_url && (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            src={featured[0].cover_image_url}
                            alt={featured[0].title}
                            className="h-full w-full object-cover"
                          />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-medium mb-1" style={{ color: '#6B6B7B' }}>
                          🎯 펀딩 진행 중
                        </p>
                        <p className="text-sm font-semibold line-clamp-1" style={{ color: '#E5E5E5' }}>
                          {featured[0].title}
                        </p>
                        <div className="mt-2">
                          <div className="h-1 rounded-full overflow-hidden" style={{ background: 'rgba(255,255,255,0.08)' }}>
                            <div
                              className="h-full rounded-full"
                              style={{
                                width: `${Math.min(pct, 100)}%`,
                                background: 'linear-gradient(90deg, #FF3B30, #FF6030)',
                              }}
                            />
                          </div>
                          <p className="text-xs mt-1" style={{ color: '#FF3B30' }}>
                            {pct}% 달성 · {featured[0].backer_count}명 참여
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                )
              })()}
            </div>
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════ */}
      {/* 2. PLATFORM FEATURES — UNO A가 뭔지 명확히 설명      */}
      {/* ══════════════════════════════════════════════════════ */}
      <section
        className="px-4 py-24"
        style={{
          background: '#0F0F14',
          borderTop: '1px solid rgba(255,255,255,0.06)',
        }}
      >
        <div className="mx-auto max-w-content">
          <div className="text-center mb-16">
            <span className="text-xs font-bold uppercase tracking-widest" style={{ color: '#FF3B30' }}>
              Platform
            </span>
            <h2 className="text-3xl font-bold mt-2" style={{ color: '#FFFFFF' }}>
              UNO A에서 할 수 있는 것들
            </h2>
            <p className="mt-3 text-base max-w-xl mx-auto leading-relaxed" style={{ color: '#6B6B7B' }}>
              단순한 SNS가 아닙니다. 구독자만 받는 아티스트의 메시지와
              크라우드펀딩을 하나의 플랫폼에서 경험하세요.
            </p>
          </div>

          <div className="grid gap-5 sm:grid-cols-3">
            {/* Feature 1: Chat */}
            <div
              className="rounded-2xl p-8 group"
              style={{
                background: 'rgba(255,255,255,0.025)',
                border: '1px solid rgba(255,255,255,0.07)',
              }}
            >
              <div
                className="h-12 w-12 rounded-2xl flex items-center justify-center mb-6"
                style={{ background: 'rgba(255,59,48,0.12)', color: '#FF3B30' }}
              >
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z" />
                </svg>
              </div>
              <h3 className="text-lg font-bold mb-2" style={{ color: '#FFFFFF' }}>
                구독자 전용 메시지
              </h3>
              <p className="text-sm leading-relaxed mb-4" style={{ color: '#6B6B7B' }}>
                아티스트가 구독자에게 직접 보내는 프라이빗 메시지.
                나만의 피드에서 일상·비하인드를 독점 수신하세요.
              </p>
              <ul className="space-y-2">
                {['구독자만 받는 아티스트 소식', '아티스트에게 직접 답장', 'VIP 전용 콘텐츠'].map((item) => (
                  <li key={item} className="flex items-center gap-2 text-xs" style={{ color: '#8B8B9B' }}>
                    <svg className="h-3.5 w-3.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5} style={{ color: '#FF3B30' }}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    {item}
                  </li>
                ))}
              </ul>
            </div>

            {/* Feature 2: Funding */}
            <div
              className="rounded-2xl p-8"
              style={{
                background: 'rgba(255,255,255,0.025)',
                border: '1px solid rgba(255,255,255,0.07)',
              }}
            >
              <div
                className="h-12 w-12 rounded-2xl flex items-center justify-center mb-6"
                style={{ background: 'rgba(139,92,246,0.12)', color: '#8B5CF6' }}
              >
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v12m-3-2.818l.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-lg font-bold mb-2" style={{ color: '#FFFFFF' }}>
                크라우드펀딩
              </h3>
              <p className="text-sm leading-relaxed mb-4" style={{ color: '#6B6B7B' }}>
                아티스트의 새 앨범, 굿즈, 콘서트 프로젝트를 직접 후원하고
                후원자만의 독점 리워드를 받으세요.
              </p>
              <ul className="space-y-2">
                {['독점 리워드 수령', '목표 달성 시 정산', '7일 환불 보장'].map((item) => (
                  <li key={item} className="flex items-center gap-2 text-xs" style={{ color: '#8B8B9B' }}>
                    <svg className="h-3.5 w-3.5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5} style={{ color: '#8B5CF6' }}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    {item}
                  </li>
                ))}
              </ul>
            </div>

            {/* Feature 3: Membership */}
            <div
              className="rounded-2xl p-8"
              style={{
                background: 'rgba(255,255,255,0.025)',
                border: '1px solid rgba(255,255,255,0.07)',
              }}
            >
              <div
                className="h-12 w-12 rounded-2xl flex items-center justify-center mb-6"
                style={{ background: 'rgba(37,99,235,0.12)', color: '#2563EB' }}
              >
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                </svg>
              </div>
              <h3 className="text-lg font-bold mb-2" style={{ color: '#FFFFFF' }}>
                멤버십 구독
              </h3>
              <p className="text-sm leading-relaxed mb-4" style={{ color: '#6B6B7B' }}>
                BASIC부터 VIP까지 — 구독 티어에 따라 더 많은
                답장 토큰과 특별한 혜택을 누리세요.
              </p>
              <div className="flex gap-2">
                {[
                  { label: 'BASIC', color: '#6B7280', bg: 'rgba(107,114,128,0.12)' },
                  { label: 'STD', color: '#3B82F6', bg: 'rgba(59,130,246,0.12)' },
                  { label: 'VIP', color: '#8B5CF6', bg: 'rgba(139,92,246,0.15)' },
                ].map((tier) => (
                  <span
                    key={tier.label}
                    className="text-xs font-bold px-2.5 py-1 rounded-full"
                    style={{ background: tier.bg, color: tier.color }}
                  >
                    {tier.label}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════ */}
      {/* 3. STATS                                             */}
      {/* ══════════════════════════════════════════════════════ */}
      <section
        className="px-4 py-14"
        style={{
          background: '#0A0A0F',
          borderTop: '1px solid rgba(255,255,255,0.06)',
        }}
      >
        <div className="mx-auto max-w-content">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-px" style={{ background: 'rgba(255,255,255,0.06)' }}>
            <div className="py-10 px-10 text-center" style={{ background: '#0A0A0F' }}>
              <StatsCounter value={totalFunding} suffix="원" label="누적 펀딩 금액" className="dark-stats" />
            </div>
            <div className="py-10 px-10 text-center" style={{ background: '#0A0A0F' }}>
              <StatsCounter value={totalBackers} suffix="명" label="팬 참여자 수" className="dark-stats" />
            </div>
            <div className="py-10 px-10 text-center" style={{ background: '#0A0A0F' }}>
              <StatsCounter value={activeCampaignCount} suffix="개" label="진행 중 캠페인" className="dark-stats" />
            </div>
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════ */}
      {/* 4. FEATURED CAMPAIGNS                                */}
      {/* ══════════════════════════════════════════════════════ */}
      <section
        className="px-4 py-20"
        style={{
          background: '#0F0F14',
          borderTop: '1px solid rgba(255,255,255,0.06)',
        }}
      >
        <div className="mx-auto max-w-content">
          <div className="mb-12 flex items-end justify-between">
            <div>
              <span className="text-xs font-bold uppercase tracking-widest" style={{ color: '#FF3B30' }}>
                Live Now
              </span>
              <h2 className="text-3xl font-bold mt-1.5" style={{ color: '#FFFFFF' }}>
                지금 진행 중인 캠페인
              </h2>
              <p className="mt-1 text-sm" style={{ color: '#6B6B7B' }}>
                아티스트의 새 프로젝트를 가장 먼저 후원하세요
              </p>
            </div>
            <Link
              href={ROUTES.funding}
              className="text-sm font-medium transition-opacity hover:opacity-70"
              style={{ color: '#FF3B30' }}
            >
              전체 보기 →
            </Link>
          </div>

          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {featured.map((campaign) => {
              const creator = mockCreators[campaign.creator_id]
              const percent = formatPercent(campaign.current_amount_dt, campaign.goal_amount_dt)

              return (
                <Link
                  key={campaign.id}
                  href={ROUTES.campaign(campaign.slug)}
                  className="campaign-card group rounded-2xl overflow-hidden transition-all duration-300 hover:-translate-y-1"
                  style={{
                    background: '#141418',
                    border: '1px solid rgba(255,255,255,0.07)',
                  }}
                >
                  {/* Cover Image */}
                  <div className="relative aspect-[16/9] overflow-hidden" style={{ background: '#1A1A22' }}>
                    {campaign.cover_image_url && (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={campaign.cover_image_url}
                        alt={campaign.title}
                        className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-[1.04]"
                        style={{ opacity: 0.82 }}
                      />
                    )}
                    <div
                      className="absolute inset-0"
                      style={{ background: 'linear-gradient(to bottom, transparent 40%, rgba(20,20,24,0.65))' }}
                    />
                    <span
                      className="absolute left-3 top-3 rounded-full px-2.5 py-1 text-xs font-medium backdrop-blur-sm"
                      style={{
                        background: 'rgba(0,0,0,0.52)',
                        border: '1px solid rgba(255,255,255,0.12)',
                        color: '#D4D4D4',
                      }}
                    >
                      {campaign.category}
                    </span>
                  </div>

                  {/* Content */}
                  <div className="p-5">
                    {creator && (
                      <div className="mb-2.5 flex items-center gap-2">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          src={creator.avatar_url || ''}
                          alt={creator.display_name || ''}
                          className="h-5 w-5 rounded-full object-cover"
                        />
                        <span className="text-xs font-medium" style={{ color: '#6B6B7B' }}>
                          {creator.display_name}
                        </span>
                      </div>
                    )}

                    <h3
                      className="line-clamp-2 text-sm font-semibold leading-snug transition-colors group-hover:text-primary-400"
                      style={{ color: '#E5E5E5' }}
                    >
                      {campaign.title}
                    </h3>

                    {/* Progress */}
                    <div className="mt-4">
                      <div className="h-1 overflow-hidden rounded-full" style={{ background: 'rgba(255,255,255,0.07)' }}>
                        <div
                          className="h-full rounded-full"
                          style={{
                            width: `${Math.min(percent, 100)}%`,
                            background: 'linear-gradient(90deg, #FF3B30, #FF6030)',
                          }}
                        />
                      </div>
                      <div className="mt-2.5 flex items-baseline justify-between">
                        <span className="text-base font-bold" style={{ color: '#FF3B30' }}>
                          {percent}%
                        </span>
                        <span className="text-xs" style={{ color: '#5B5B6B' }}>
                          {formatFundingAmount(campaign.current_amount_dt)} / {formatFundingAmount(campaign.goal_amount_dt)}
                        </span>
                      </div>
                      <div className="mt-1 flex justify-between text-xs" style={{ color: '#4B4B5B' }}>
                        <span>{campaign.backer_count}명 참여</span>
                        <span>{campaign.end_at ? formatDaysLeft(campaign.end_at) : ''}</span>
                      </div>
                    </div>
                  </div>
                </Link>
              )
            })}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════ */}
      {/* 5. HOW IT WORKS                                      */}
      {/* ══════════════════════════════════════════════════════ */}
      <section
        className="px-4 py-20"
        style={{
          background: '#0A0A0F',
          borderTop: '1px solid rgba(255,255,255,0.06)',
        }}
      >
        <div className="mx-auto max-w-content">
          <div className="text-center mb-16">
            <span className="text-xs font-bold uppercase tracking-widest" style={{ color: '#FF3B30' }}>
              Process
            </span>
            <h2 className="text-3xl font-bold mt-2" style={{ color: '#FFFFFF' }}>
              시작하는 방법
            </h2>
            <p className="mt-2 text-sm" style={{ color: '#6B6B7B' }}>
              3단계로 아티스트와 연결되세요
            </p>
          </div>

          <div className="grid gap-5 sm:grid-cols-3">
            {[
              {
                step: '01',
                title: '아티스트 구독',
                desc: '좋아하는 아티스트를 구독하고 멤버십 티어를 선택하세요. 구독 즉시 채팅방에 입장됩니다.',
                icon: (
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M17.982 18.725A7.488 7.488 0 0012 15.75a7.488 7.488 0 00-5.982 2.975m11.963 0a9 9 0 10-11.963 0m11.963 0A8.966 8.966 0 0112 21a8.966 8.966 0 01-5.982-2.275M15 9.75a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                ),
              },
              {
                step: '02',
                title: '메시지 수신 & 답장',
                desc: '아티스트가 구독자에게 보낸 메시지를 나만의 피드에서 확인하고, 아티스트에게 직접 답장하세요.',
                icon: (
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 01.865-.501 48.172 48.172 0 003.423-.379c1.584-.233 2.707-1.628 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0012 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018z" />
                  </svg>
                ),
              },
              {
                step: '03',
                title: '펀딩으로 함께 만들기',
                desc: '아티스트의 새 프로젝트를 후원하고, 완성된 리워드를 가장 먼저 받아보세요.',
                icon: (
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M21 11.25v8.25a1.5 1.5 0 01-1.5 1.5H5.25a1.5 1.5 0 01-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 109.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1114.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
                  </svg>
                ),
              },
            ].map((item) => (
              <div
                key={item.step}
                className="rounded-2xl p-8"
                style={{
                  background: 'rgba(255,255,255,0.025)',
                  border: '1px solid rgba(255,255,255,0.07)',
                }}
              >
                <div className="flex gap-5 items-start">
                  <span
                    className="text-6xl font-bold leading-none select-none flex-shrink-0 -mt-1"
                    style={{ color: 'rgba(255, 59, 48, 0.09)' }}
                  >
                    {item.step}
                  </span>
                  <div>
                    <div
                      className="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-xl"
                      style={{ background: 'rgba(255, 59, 48, 0.12)', color: '#FF3B30' }}
                    >
                      {item.icon}
                    </div>
                    <h3 className="text-base font-semibold" style={{ color: '#E5E5E5' }}>
                      {item.title}
                    </h3>
                    <p className="mt-2 text-sm leading-relaxed" style={{ color: '#6B6B7B' }}>
                      {item.desc}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════ */}
      {/* 6. CREATOR CTA                                       */}
      {/* ══════════════════════════════════════════════════════ */}
      <section
        className="px-4 py-20"
        style={{
          background: '#0F0F14',
          borderTop: '1px solid rgba(255,255,255,0.06)',
        }}
      >
        <div className="mx-auto max-w-content">
          <div
            className="relative rounded-3xl overflow-hidden px-8 py-16 sm:px-16 text-center"
            style={{
              background: 'linear-gradient(160deg, #160A0A 0%, #100A0A 100%)',
              border: '1px solid rgba(255, 59, 48, 0.2)',
            }}
          >
            <div
              className="absolute inset-0 pointer-events-none"
              style={{
                background: 'radial-gradient(ellipse 70% 65% at 50% 50%, rgba(255,59,48,0.07) 0%, transparent 70%)',
              }}
            />
            <div className="relative">
              <span className="text-xs font-bold uppercase tracking-widest" style={{ color: '#FF3B30' }}>
                For Creators
              </span>
              <h2 className="mt-3 text-3xl font-bold sm:text-4xl" style={{ color: '#FFFFFF' }}>
                크리에이터로 시작하세요
              </h2>
              <p
                className="mx-auto mt-4 max-w-lg text-base leading-relaxed"
                style={{ color: '#8B8B9B' }}
              >
                팬들에게 직접 메시지를 보내고, 크라우드펀딩으로
                프로젝트를 실현하세요. 캠페인 생성부터 정산까지
                UNO A가 모든 것을 지원합니다.
              </p>
              <div className="mt-8 flex flex-wrap justify-center gap-4">
                <Link
                  href={ROUTES.studio.dashboard}
                  className="inline-flex items-center gap-2 rounded-xl px-7 py-3.5 text-base font-semibold text-white transition-all hover:scale-[1.02] active:scale-[0.98]"
                  style={{
                    background: '#FF3B30',
                    boxShadow: '0 0 36px rgba(255, 59, 48, 0.32)',
                  }}
                >
                  스튜디오 시작하기
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                  </svg>
                </Link>
              </div>
              <div className="mt-8 flex flex-wrap justify-center gap-2">
                {['팬 메시지 발송', '구독자 관리', '캠페인 생성', '리워드 설정', '수익 정산', '분석 대시보드'].map((feature) => (
                  <span
                    key={feature}
                    className="rounded-full px-3 py-1 text-xs font-medium"
                    style={{
                      background: 'rgba(255, 255, 255, 0.05)',
                      border: '1px solid rgba(255, 255, 255, 0.09)',
                      color: '#7B7B8B',
                    }}
                  >
                    {feature}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════════════════ */}
      {/* 7. TRUST INDICATORS                                  */}
      {/* ══════════════════════════════════════════════════════ */}
      <section
        className="px-4 py-12"
        style={{
          background: '#0A0A0F',
          borderTop: '1px solid rgba(255,255,255,0.06)',
        }}
      >
        <div className="mx-auto max-w-content grid grid-cols-1 gap-4 sm:grid-cols-3">
          {[
            {
              icon: (
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
                </svg>
              ),
              title: '안전한 결제',
              desc: 'TossPayments PG 보안 결제',
              color: '#16A34A',
              bg: 'rgba(22, 163, 74, 0.12)',
            },
            {
              icon: (
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182" />
                </svg>
              ),
              title: '7일 환불 보장',
              desc: '구매 후 7일 이내 전액 환불',
              color: '#2563EB',
              bg: 'rgba(37, 99, 235, 0.12)',
            },
            {
              icon: (
                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
                </svg>
              ),
              title: '구독자 전용 메시지',
              desc: '아티스트가 구독자에게 보내는 프라이빗 소식',
              color: '#8B5CF6',
              bg: 'rgba(139, 92, 246, 0.12)',
            },
          ].map((item) => (
            <div
              key={item.title}
              className="flex items-center gap-4 rounded-2xl p-5"
              style={{
                background: 'rgba(255,255,255,0.025)',
                border: '1px solid rgba(255,255,255,0.07)',
              }}
            >
              <div
                className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl"
                style={{ background: item.bg, color: item.color }}
              >
                {item.icon}
              </div>
              <div>
                <p className="text-sm font-semibold" style={{ color: '#E5E5E5' }}>{item.title}</p>
                <p className="text-xs mt-0.5" style={{ color: '#6B6B7B' }}>{item.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

    </PageLayout>
  )
}
