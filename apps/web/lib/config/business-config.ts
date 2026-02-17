/**
 * Business Configuration
 *
 * Flutter BusinessConfig 미러링.
 * 모든 비즈니스 규칙, 수수료율, 세율, 정산 비율 등 중앙 관리.
 * 하드코딩 방지: 모든 비즈니스 상수는 이 파일에서만 정의.
 */

export const tiers = ['BASIC', 'STANDARD', 'VIP'] as const
export type Tier = (typeof tiers)[number]

export const purchasePlatforms = ['web', 'android', 'ios'] as const
export type PurchasePlatform = (typeof purchasePlatforms)[number]

type TierPriceByPlatform = Record<PurchasePlatform, Record<Tier, number>>

export type DtPackageByPlatform = {
  id: string
  dt: number
  bonus: number
  web: number
  android: number
  ios: number
}

export const businessConfig = {
  // ============================================================
  // 구독 티어
  // ============================================================
  subscriptionTiers: ['BASIC', 'STANDARD', 'VIP'] as const,

  tierDisplayNames: {
    BASIC: '베이직',
    STANDARD: '스탠다드',
    VIP: 'VIP',
  } as const,

  tierPrices: {
    BASIC: 4900,
    STANDARD: 9900,
    VIP: 19900,
  } as const,

  tierPricesByPlatform: {
    web: { BASIC: 4900, STANDARD: 9900, VIP: 19900 },
    android: { BASIC: 5900, STANDARD: 11900, VIP: 22900 },
    ios: { BASIC: 6900, STANDARD: 13900, VIP: 27900 },
  } satisfies TierPriceByPlatform,

  tierBenefits: {
    BASIC: ['아티스트 메시지 수신', '기본 이모티콘 사용'],
    STANDARD: ['아티스트 메시지 수신', '모든 이모티콘 사용', '답글 토큰 +1', '프로필 배지'],
    VIP: ['모든 STANDARD 혜택', '답글 토큰 +2', '독점 콘텐츠 접근', 'VIP 전용 배지', '우선 응답 기회'],
  } as const,

  // ============================================================
  // 답글 토큰 시스템
  // ============================================================
  defaultReplyTokens: 3,
  standardTierBonusTokens: 1,
  vipTierBonusTokens: 2,

  // Structured token rules for pricing pages
  tokenRules: {
    baseTokensPerBroadcast: 3,
    bonusTokensByTier: {
      BASIC: 0,
      STANDARD: 1,
      VIP: 2,
    } satisfies Record<Tier, number>,
  },

  getTokensForTier(tier: string): number {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return this.defaultReplyTokens + this.vipTierBonusTokens
      case 'STANDARD':
        return this.defaultReplyTokens + this.standardTierBonusTokens
      default:
        return this.defaultReplyTokens
    }
  },

  // ============================================================
  // 글자수 제한 (구독 일수별)
  // ============================================================
  characterLimitsByDays: {
    0: 50,
    50: 50,
    77: 77,
    100: 100,
    150: 150,
    200: 200,
    300: 300,
  } as Record<number, number>,

  getCharacterLimit(daysSubscribed: number): number {
    let limit = 50
    for (const [days, chars] of Object.entries(this.characterLimitsByDays)) {
      if (daysSubscribed >= Number(days)) {
        limit = chars
      }
    }
    return limit
  },

  // ============================================================
  // 정산/수수료
  // ============================================================
  platformCommissionPercent: 20,
  get creatorPayoutPercent(): number {
    return 100 - this.platformCommissionPercent
  },

  // ============================================================
  // 세율 (원천징수)
  // ============================================================
  taxRates: {
    /** 사업소득: 소득세 3.0% + 지방소득세 0.3% */
    businessIncome: 3.3,
    /** 기타소득: 소득세 8.0% + 지방소득세 0.8% */
    otherIncome: 8.8,
    /** 세금계산서 발행 사업자: 원천징수 없음 */
    invoice: 0,
  } as const,

  // ============================================================
  // 환불
  // ============================================================
  refundPeriodDays: 7,
  refundProcessingDays: 3,

  // ============================================================
  // DT (디지털 토큰) / 화폐
  // ============================================================
  /** DT:KRW 비율 (1:1, 참고용) */
  dtPerKrw: 1,

  /** 펀딩 결제 화폐 */
  fundingCurrency: 'KRW' as const,
  fundingCurrencySymbol: '원',

  /** DT 구매 가능 금액 */
  chargeAmounts: [1000, 3000, 5000, 10000, 30000, 50000, 100000] as const,
  minChargeDt: 1000,
  maxChargeDt: 1000000,

  /** DT packages with platform-specific prices */
  dtPackagesByPlatform: [
    { id: 'dt_10', dt: 10, bonus: 0, web: 1000, android: 1200, ios: 1400 },
    { id: 'dt_50', dt: 50, bonus: 0, web: 5000, android: 5900, ios: 6900 },
    { id: 'dt_100', dt: 100, bonus: 5, web: 10000, android: 11900, ios: 13900 },
    { id: 'dt_500', dt: 500, bonus: 50, web: 50000, android: 59000, ios: 69000 },
    { id: 'dt_1000', dt: 1000, bonus: 150, web: 100000, android: 119000, ios: 139000 },
    { id: 'dt_5000', dt: 5000, bonus: 1000, web: 500000, android: 590000, ios: 690000 },
  ] satisfies DtPackageByPlatform[],

  // ============================================================
  // 펀딩 캠페인
  // ============================================================
  minFundingGoalKrw: 100000,
  maxFundingGoalKrw: 100000000,
  maxCampaignDurationDays: 90,
  minCampaignDurationDays: 7,

  // ============================================================
  // 콘텐츠 제한
  // ============================================================
  maxBroadcastLength: 2000,
  maxBioLength: 200,
  maxDisplayNameLength: 20,
  minDisplayNameLength: 2,
  maxMediaAttachments: 10,

  // ============================================================
  // 투표/VS 시스템
  // ============================================================
  maxPollsPerDay: 5,
  defaultPollDurationHours: 24,
  maxPollOptions: 4,

  // ============================================================
  // 기념일 시스템
  // ============================================================
  milestoneDays: [50, 100, 365] as const,
  celebrationExpiryDays: 7,
} as const

// ============================================================
// Helper functions (외부에서 import하여 사용)
// ============================================================

/** 플랫폼별 구독 티어 가격 조회 */
export function getTierPrice(tier: Tier, platform: PurchasePlatform): number {
  return businessConfig.tierPricesByPlatform[platform][tier]
}

/** 플랫폼별 DT 패키지 가격 조회 */
export function getDtPackagePrice(
  packageId: string,
  platform: PurchasePlatform,
): number {
  const pkg = businessConfig.dtPackagesByPlatform.find((p) => p.id === packageId)
  if (!pkg) return 0
  return pkg[platform]
}

/** 할인율 계산 (%) */
export function getSavingsPercent(
  originalPrice: number,
  discountedPrice: number,
): number {
  if (originalPrice <= 0) return 0
  return Math.floor(((originalPrice - discountedPrice) / originalPrice) * 100)
}
