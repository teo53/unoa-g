import Link from 'next/link'
import { PageLayout } from '@/components/shared/page-layout'
import { StatsCounter } from '@/components/shared/stats-counter'
import { ROUTES } from '@/lib/constants/routes'
import { mockCampaigns, mockCreators } from '@/lib/mock/demo-data'
import { formatFundingAmount, formatPercent, formatDaysLeft } from '@/lib/utils/format'

export default function HomePage() {
  // Featured campaigns (top 3 by progress)
  const featured = mockCampaigns
    .filter((c) => c.status === 'active')
    .sort((a, b) => (b.current_amount_dt / b.goal_amount_dt) - (a.current_amount_dt / a.goal_amount_dt))
    .slice(0, 3)

  // Platform stats
  const totalFunding = mockCampaigns.reduce((sum, c) => sum + c.current_amount_dt, 0)
  const totalBackers = mockCampaigns.reduce((sum, c) => sum + c.backer_count, 0)
  const totalCampaigns = mockCampaigns.length

  return (
    <PageLayout variant="public" maxWidth="full" contentClassName="!px-0 !py-0">
      {/* ================================================ */}
      {/* Hero Section */}
      {/* ================================================ */}
      <section className="relative overflow-hidden bg-gradient-to-b from-primary-50/50 to-white px-4 pb-20 pt-16 sm:pt-24">
        <div className="mx-auto max-w-content text-center">
          <h1 className="text-4xl font-bold leading-tight text-neutral-900 sm:text-5xl md:text-6xl">
            좋아하는 크리에이터의
            <br />
            <span className="text-primary-600">새로운 시작</span>을 응원하세요
          </h1>
          <p className="mx-auto mt-6 max-w-2xl text-lg text-neutral-600 sm:text-xl">
            UNO A에서 크리에이터들의 특별한 프로젝트를 후원하고,
            <br className="hidden sm:block" />
            세상에 하나뿐인 리워드를 받아보세요.
          </p>
          <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
            <Link
              href={ROUTES.funding}
              className="inline-flex items-center gap-2 rounded-xl bg-primary-600 px-8 py-4 text-lg font-semibold text-white transition-colors hover:bg-primary-700"
            >
              펀딩 둘러보기
              <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
              </svg>
            </Link>
            <Link
              href={ROUTES.studio.dashboard}
              className="inline-flex items-center gap-2 rounded-xl border-2 border-neutral-200 bg-white px-8 py-4 text-lg font-semibold text-neutral-900 transition-colors hover:border-primary-300 hover:bg-primary-50"
            >
              크리에이터로 시작하기
            </Link>
          </div>
        </div>
      </section>

      {/* ================================================ */}
      {/* Platform Stats */}
      {/* ================================================ */}
      <section className="border-y border-neutral-100 bg-white px-4 py-12">
        <div className="mx-auto grid max-w-content grid-cols-1 gap-8 sm:grid-cols-3">
          <StatsCounter value={totalFunding} suffix="원" label="총 펀딩 금액" />
          <StatsCounter value={totalBackers} suffix="명" label="참여자 수" />
          <StatsCounter value={totalCampaigns} suffix="개" label="진행 캠페인" />
        </div>
      </section>

      {/* ================================================ */}
      {/* Featured Campaigns */}
      {/* ================================================ */}
      <section className="bg-white px-4 py-16">
        <div className="mx-auto max-w-content">
          <div className="mb-8 flex items-end justify-between">
            <div>
              <h2 className="text-2xl font-bold text-neutral-900 sm:text-3xl">인기 캠페인</h2>
              <p className="mt-1 text-neutral-500">지금 가장 주목받는 프로젝트</p>
            </div>
            <Link
              href={ROUTES.funding}
              className="text-sm font-medium text-primary-600 hover:text-primary-700"
            >
              전체 보기 &rarr;
            </Link>
          </div>

          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {featured.map((campaign) => {
              const creator = mockCreators[campaign.creator_id]
              const percent = formatPercent(campaign.current_amount_dt, campaign.goal_amount_dt)

              return (
                <Link
                  key={campaign.id}
                  href={ROUTES.campaign(campaign.slug)}
                  className="group overflow-hidden rounded-2xl border border-neutral-200 bg-white transition-all hover:border-primary-200 hover:shadow-lg"
                >
                  {/* Cover Image */}
                  <div className="relative aspect-[16/10] overflow-hidden bg-neutral-100">
                    {campaign.cover_image_url && (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={campaign.cover_image_url}
                        alt={campaign.title}
                        className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                      />
                    )}
                    <span className="absolute left-3 top-3 rounded-full bg-white/90 px-2.5 py-1 text-xs font-medium text-neutral-700 backdrop-blur-sm">
                      {campaign.category}
                    </span>
                  </div>

                  {/* Content */}
                  <div className="p-4">
                    {/* Creator */}
                    {creator && (
                      <div className="mb-2 flex items-center gap-2">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          src={creator.avatar_url || ''}
                          alt={creator.display_name || ''}
                          className="h-6 w-6 rounded-full object-cover"
                        />
                        <span className="text-xs font-medium text-neutral-500">
                          {creator.display_name}
                        </span>
                      </div>
                    )}

                    <h3 className="line-clamp-2 text-sm font-semibold text-neutral-900 group-hover:text-primary-600">
                      {campaign.title}
                    </h3>

                    {/* Progress */}
                    <div className="mt-3">
                      <div className="h-1.5 overflow-hidden rounded-full bg-neutral-100">
                        <div
                          className="h-full rounded-full bg-primary-500 transition-all"
                          style={{ width: `${Math.min(percent, 100)}%` }}
                        />
                      </div>
                      <div className="mt-2 flex items-baseline justify-between">
                        <span className="text-sm font-bold text-primary-600">{percent}%</span>
                        <span className="text-xs text-neutral-500">
                          {formatFundingAmount(campaign.current_amount_dt)} / {formatFundingAmount(campaign.goal_amount_dt)}
                        </span>
                      </div>
                      <div className="mt-1 flex justify-between text-xs text-neutral-400">
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

      {/* ================================================ */}
      {/* How It Works */}
      {/* ================================================ */}
      <section className="bg-neutral-50 px-4 py-16">
        <div className="mx-auto max-w-content">
          <h2 className="mb-12 text-center text-2xl font-bold text-neutral-900 sm:text-3xl">
            이용 방법
          </h2>
          <div className="grid gap-8 sm:grid-cols-3">
            {[
              {
                step: '01',
                title: '캠페인 탐색',
                desc: '관심 있는 크리에이터의 프로젝트를 찾아보세요.',
                icon: (
                  <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                  </svg>
                ),
              },
              {
                step: '02',
                title: '리워드 선택',
                desc: '원하는 리워드 티어를 선택하고 후원하세요.',
                icon: (
                  <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M21 11.25v8.25a1.5 1.5 0 01-1.5 1.5H5.25a1.5 1.5 0 01-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 109.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1114.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
                  </svg>
                ),
              },
              {
                step: '03',
                title: '리워드 수령',
                desc: '프로젝트 성공 시 특별한 리워드를 받아보세요.',
                icon: (
                  <svg className="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12c0 1.268-.63 2.39-1.593 3.068a3.745 3.745 0 01-1.043 3.296 3.745 3.745 0 01-3.296 1.043A3.745 3.745 0 0112 21c-1.268 0-2.39-.63-3.068-1.593a3.746 3.746 0 01-3.296-1.043 3.745 3.745 0 01-1.043-3.296A3.745 3.745 0 013 12c0-1.268.63-2.39 1.593-3.068a3.745 3.745 0 011.043-3.296 3.746 3.746 0 013.296-1.043A3.746 3.746 0 0112 3c1.268 0 2.39.63 3.068 1.593a3.746 3.746 0 013.296 1.043 3.745 3.745 0 011.043 3.296A3.745 3.745 0 0121 12z" />
                  </svg>
                ),
              },
            ].map((item) => (
              <div key={item.step} className="text-center">
                <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary-100 text-primary-600">
                  {item.icon}
                </div>
                <span className="text-xs font-bold text-primary-600">STEP {item.step}</span>
                <h3 className="mt-1 text-lg font-semibold text-neutral-900">{item.title}</h3>
                <p className="mt-2 text-sm text-neutral-500">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ================================================ */}
      {/* Creator CTA */}
      {/* ================================================ */}
      <section className="bg-white px-4 py-16">
        <div className="mx-auto max-w-narrow text-center">
          <h2 className="text-2xl font-bold text-neutral-900 sm:text-3xl">
            크리에이터이신가요?
          </h2>
          <p className="mx-auto mt-3 max-w-lg text-neutral-500">
            UNO A에서 팬들과 함께 새로운 프로젝트를 시작하세요.
            캠페인 생성, 리워드 관리, 정산까지 모든 것을 지원합니다.
          </p>
          <Link
            href={ROUTES.studio.dashboard}
            className="mt-8 inline-flex items-center gap-2 rounded-xl bg-neutral-900 px-8 py-4 text-lg font-semibold text-white transition-colors hover:bg-neutral-800"
          >
            스튜디오 시작하기
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
            </svg>
          </Link>
        </div>
      </section>

      {/* ================================================ */}
      {/* Trust Indicators */}
      {/* ================================================ */}
      <section className="border-t border-neutral-100 bg-neutral-50 px-4 py-12">
        <div className="mx-auto grid max-w-content grid-cols-1 gap-6 sm:grid-cols-3">
          <div className="flex items-center gap-3 rounded-xl bg-white p-4">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-semantic-success-light">
              <svg className="h-5 w-5 text-semantic-success" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
              </svg>
            </div>
            <div>
              <p className="text-sm font-semibold text-neutral-900">안전한 결제</p>
              <p className="text-xs text-neutral-500">PG사 인증 보안 결제</p>
            </div>
          </div>

          <div className="flex items-center gap-3 rounded-xl bg-white p-4">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-semantic-info-light">
              <svg className="h-5 w-5 text-semantic-info" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182" />
              </svg>
            </div>
            <div>
              <p className="text-sm font-semibold text-neutral-900">7일 환불 보장</p>
              <p className="text-xs text-neutral-500">구매 후 7일 이내 환불</p>
            </div>
          </div>

          <div className="flex items-center gap-3 rounded-xl bg-white p-4">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-tier-vip-light">
              <svg className="h-5 w-5 text-tier-vip" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
              </svg>
            </div>
            <div>
              <p className="text-sm font-semibold text-neutral-900">독점 리워드</p>
              <p className="text-xs text-neutral-500">후원자만의 특별한 혜택</p>
            </div>
          </div>
        </div>
      </section>
    </PageLayout>
  )
}
