/**
 * Route Constants
 *
 * 모든 웹 라우트 경로를 상수로 정의.
 * 하드코딩 방지 + 라우트 변경 시 단일 수정 지점.
 */
export const ROUTES = {
  // ============================================================
  // Public
  // ============================================================
  home: '/',
  funding: '/funding',
  pricing: '/pricing',
  store: {
    dt: '/store/dt',
  },
  campaign: (slug: string) => `/p/${slug}`,

  // ============================================================
  // Studio (크리에이터)
  // ============================================================
  studio: {
    dashboard: '/studio',
    campaigns: '/studio/campaigns',
    campaignEdit: (id: string) => `/studio/campaigns/${id}/edit`,
    campaignNew: '/studio/campaigns/new',
  },

  // ============================================================
  // Admin (관리자)
  // ============================================================
  admin: {
    dashboard: '/admin',
    campaigns: '/admin/campaigns',
    campaignReview: (id: string) => `/admin/campaigns/${id}`,
    settlements: '/admin/settlements',
    taxReports: '/admin/tax-reports',
    users: '/admin/users',
  },

  // ============================================================
  // Agency (소속사)
  // ============================================================
  agency: {
    dashboard: '/agency',
    artists: '/agency/artists',
    analytics: '/agency/analytics',
    settlements: '/agency/settlements',
  },

  // ============================================================
  // Legal (법적 페이지)
  // ============================================================
  legal: {
    terms: '/legal/terms',
    privacy: '/legal/privacy',
    refund: '/legal/refund',
    company: '/legal/company',
    dtUsage: '/legal/dt-usage',
    creator: '/legal/creator',
    funding: '/legal/funding',
    community: '/legal/community',
    settlement: '/legal/settlement',
  },

  // ============================================================
  // External
  // ============================================================
  external: {
    flutterApp: 'https://unoa-app-demo.web.app',
    support: 'mailto:support@unoa.app',
  },
} as const

/** Alias for convenience — pricing / DT store pages import `routes`. */
export const routes = ROUTES
