/**
 * Ops CRM API Client
 *
 * Wrapper for calling the ops-manage Edge Function.
 * Handles auth, demo mode, and error normalization.
 */

import { DEMO_MODE } from '../mock/demo-data'

// Static export guard: skip API calls when Supabase credentials are unavailable
const SKIP_API = !DEMO_MODE && !process.env.NEXT_PUBLIC_SUPABASE_URL
import type {
  OpsApiResponse,
  OpsStaff,
  OpsAsset,
  OpsBanner,
  FanAdListResult,
  OpsFeatureFlag,
  OpsAuditEntry,
  PaginatedResult,
  BannerFormData,
  BannerPlacement,
  FanAdStatus,
  FanAdApproveResult,
  FanAdRejectResult,
  FlagFormData,
  OpsDashboardStats,
} from './ops-types'

// ── Demo mock data ──
const DEMO_BANNERS: OpsBanner[] = [
  {
    id: 'demo-banner-1',
    title: '신규 아티스트 오픈 기념 이벤트',
    placement: 'home_top',
    image_url: 'https://picsum.photos/seed/banner1/800/400',
    link_url: '/discover',
    link_type: 'internal',
    status: 'published',
    priority: 10,
    start_at: null,
    end_at: null,
    target_audience: 'all',
    version: 2,
    published_snapshot: null,
    created_by: 'demo-ops-1',
    updated_by: 'demo-ops-1',
    created_at: '2025-12-01T00:00:00Z',
    updated_at: '2025-12-10T00:00:00Z',
  },
  {
    id: 'demo-banner-2',
    title: 'VIP 전용 특별 혜택',
    placement: 'home_bottom',
    image_url: 'https://picsum.photos/seed/banner2/800/400',
    link_url: '/subscriptions',
    link_type: 'internal',
    status: 'draft',
    priority: 5,
    start_at: null,
    end_at: null,
    target_audience: 'vip',
    version: 1,
    published_snapshot: null,
    created_by: 'demo-ops-1',
    updated_by: null,
    created_at: '2025-12-15T00:00:00Z',
    updated_at: '2025-12-15T00:00:00Z',
  },
]

const DEMO_FLAGS: OpsFeatureFlag[] = [
  {
    id: 'demo-flag-1',
    flag_key: 'dark_mode_v2',
    title: '다크 모드 v2',
    description: '새로운 다크 모드 디자인 테스트',
    status: 'published',
    enabled: true,
    rollout_percent: 50,
    payload: { variant: 'new_palette' },
    version: 3,
    published_snapshot: null,
    created_by: 'demo-ops-1',
    updated_by: 'demo-ops-1',
    created_at: '2025-11-01T00:00:00Z',
    updated_at: '2025-12-05T00:00:00Z',
  },
  {
    id: 'demo-flag-2',
    flag_key: 'gift_feature',
    title: '선물 기능',
    description: '팬 간 선물 전송 기능',
    status: 'draft',
    enabled: false,
    rollout_percent: 0,
    payload: {},
    version: 1,
    published_snapshot: null,
    created_by: 'demo-ops-1',
    updated_by: null,
    created_at: '2025-12-20T00:00:00Z',
    updated_at: '2025-12-20T00:00:00Z',
  },
]

const DEMO_AUDIT: OpsAuditEntry[] = [
  {
    id: 'demo-audit-1',
    actor_id: 'demo-ops-1',
    actor_role: 'publisher',
    action: 'banner.publish',
    entity_type: 'ops_banners',
    entity_id: 'demo-banner-1',
    before: { status: 'in_review' },
    after: { status: 'published' },
    metadata: {},
    created_at: '2025-12-10T14:30:00Z',
  },
  {
    id: 'demo-audit-2',
    actor_id: 'demo-ops-1',
    actor_role: 'operator',
    action: 'flag.create',
    entity_type: 'ops_feature_flags',
    entity_id: 'demo-flag-2',
    before: null,
    after: { flag_key: 'gift_feature', title: '선물 기능' },
    metadata: {},
    created_at: '2025-12-20T09:00:00Z',
  },
  {
    id: 'demo-audit-3',
    actor_id: 'demo-ops-2',
    actor_role: 'admin',
    action: 'settlement.approve',
    entity_type: 'settlements',
    entity_id: 'settlement-2026-01-waker',
    before: { status: 'pending' },
    after: { status: 'approved', title: 'WAKER 2026-01월 정산 승인' },
    metadata: { artist_name: 'WAKER', period: '2026-01' },
    created_at: '2026-02-05T10:15:00Z',
  },
  {
    id: 'demo-audit-4',
    actor_id: 'demo-ops-2',
    actor_role: 'admin',
    action: 'settlement.reject',
    entity_type: 'settlements',
    entity_id: 'settlement-2026-01-moonlight',
    before: { status: 'pending' },
    after: { status: 'rejected', reason: '서류 미비', title: 'MOONLIGHT 정산 반려 (서류 미비)' },
    metadata: { artist_name: 'MOONLIGHT', period: '2026-01' },
    created_at: '2026-02-07T14:22:00Z',
  },
  {
    id: 'demo-audit-5',
    actor_id: 'demo-ops-3',
    actor_role: 'moderator',
    action: 'creator.warn',
    entity_type: 'creators',
    entity_id: 'creator-starlight',
    before: { warning_count: 0 },
    after: { warning_count: 1, title: '크리에이터 \'별빛\' 경고 발송' },
    metadata: { reason: '부적절한 콘텐츠 게시' },
    created_at: '2026-02-08T16:45:00Z',
  },
  {
    id: 'demo-audit-6',
    actor_id: 'demo-ops-3',
    actor_role: 'moderator',
    action: 'creator.suspend',
    entity_type: 'creators',
    entity_id: 'creator-baduser',
    before: { status: 'active' },
    after: { status: 'suspended', title: '크리에이터 \'악성유저\' 정지 처리' },
    metadata: { reason: '약관 위반 (중복)', duration_days: 30 },
    created_at: '2026-02-10T11:30:00Z',
  },
  {
    id: 'demo-audit-7',
    actor_id: 'demo-ops-4',
    actor_role: 'moderator',
    action: 'report.resolve',
    entity_type: 'reports',
    entity_id: 'rpt-002',
    before: { status: 'reviewing' },
    after: { status: 'resolved', title: '신고 #rpt-002 해결 처리', action_taken: '경고 발송' },
    metadata: { report_type: 'harassment' },
    created_at: '2026-02-11T09:18:00Z',
  },
  {
    id: 'demo-audit-8',
    actor_id: 'demo-ops-5',
    actor_role: 'operator',
    action: 'payment.refund',
    entity_type: 'payments',
    entity_id: 'pay-007',
    before: { status: 'completed' },
    after: { status: 'refunded', title: '펀딩 결제 환불 처리 (#pay-007)', amount: 9900 },
    metadata: { reason: '고객 요청', refund_method: 'original' },
    created_at: '2026-02-12T13:50:00Z',
  },
]

// ── Client ──

async function getSupabaseClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  if (!url || !key) {
    throw new Error('Supabase credentials not configured')
  }
  const { createBrowserClient } = await import('@supabase/ssr')
  return createBrowserClient(url, key)
}

async function callOpsManage<T>(
  action: string,
  payload: Record<string, unknown> = {}
): Promise<T> {
  const supabase = await getSupabaseClient()
  const { data: { session } } = await supabase.auth.getSession()

  if (!session?.access_token) {
    throw new Error('인증이 필요합니다. 다시 로그인해주세요.')
  }

  const url = `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/ops-manage`

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${session.access_token}`,
    },
    body: JSON.stringify({ action, payload }),
  })

  const json: OpsApiResponse<T> = await res.json()

  if (!json.success) {
    const errorMsg = json.error || `요청 실패 (${res.status})`
    throw new Error(errorMsg)
  }

  return json.data as T
}

// ── Public API ──

// Staff
export async function listStaff(): Promise<OpsStaff[]> {
  if (DEMO_MODE) return []
  if (SKIP_API) return []
  return callOpsManage<OpsStaff[]>('staff.list')
}

export async function upsertStaff(
  targetUserId: string,
  role: string,
  displayName?: string
): Promise<OpsStaff> {
  return callOpsManage<OpsStaff>('staff.upsert', {
    target_user_id: targetUserId,
    role,
    display_name: displayName,
  })
}

export async function removeStaff(targetUserId: string): Promise<void> {
  await callOpsManage('staff.remove', { target_user_id: targetUserId })
}

// Assets
export async function listAssets(
  options: { tag?: string; limit?: number; offset?: number } = {}
): Promise<PaginatedResult<OpsAsset>> {
  if (DEMO_MODE) return { items: [], total: 0 }
  if (SKIP_API) return { items: [], total: 0 }
  return callOpsManage<PaginatedResult<OpsAsset>>('asset.list', options)
}

export async function completeAssetUpload(
  asset: Omit<OpsAsset, 'id' | 'uploaded_by' | 'created_at'>
): Promise<OpsAsset> {
  return callOpsManage<OpsAsset>('asset.upload_complete', asset)
}

export async function deleteAsset(id: string): Promise<void> {
  await callOpsManage('asset.delete', { id })
}

// Banners
export async function listBanners(
  filters: { status?: string; placement?: string } = {}
): Promise<OpsBanner[]> {
  if (DEMO_MODE) return DEMO_BANNERS
  if (SKIP_API) return []
  return callOpsManage<OpsBanner[]>('banner.list', filters)
}

export async function getBanner(id: string): Promise<OpsBanner> {
  if (DEMO_MODE) {
    const banner = DEMO_BANNERS.find((b) => b.id === id)
    if (!banner) throw new Error('배너를 찾을 수 없습니다')
    return banner
  }
  if (SKIP_API) throw new Error('Supabase not configured')
  return callOpsManage<OpsBanner>('banner.get', { id })
}

export async function createBanner(data: BannerFormData): Promise<OpsBanner> {
  if (DEMO_MODE) {
    return {
      ...DEMO_BANNERS[0],
      ...data,
      id: `demo-banner-${Date.now()}`,
      status: 'draft',
      version: 1,
    }
  }
  return callOpsManage<OpsBanner>('banner.create', { ...data })
}

export async function updateBanner(
  id: string,
  expectedVersion: number,
  data: Partial<BannerFormData>
): Promise<OpsBanner> {
  if (DEMO_MODE) {
    const banner = DEMO_BANNERS.find((b) => b.id === id)
    if (!banner) throw new Error('배너를 찾을 수 없습니다')
    return { ...banner, ...data, version: expectedVersion + 1 }
  }
  return callOpsManage<OpsBanner>('banner.update', {
    id,
    expected_version: expectedVersion,
    ...data,
  })
}

export async function submitBannerReview(
  id: string,
  expectedVersion: number
): Promise<OpsBanner> {
  return callOpsManage<OpsBanner>('banner.submit_review', {
    id,
    expected_version: expectedVersion,
  })
}

export async function publishBanner(
  id: string,
  expectedVersion: number
): Promise<OpsBanner> {
  return callOpsManage<OpsBanner>('banner.publish', {
    id,
    expected_version: expectedVersion,
  })
}

export async function rollbackBanner(id: string): Promise<OpsBanner> {
  return callOpsManage<OpsBanner>('banner.rollback', { id })
}

export async function archiveBanner(
  id: string,
  expectedVersion: number
): Promise<OpsBanner> {
  return callOpsManage<OpsBanner>('banner.archive', {
    id,
    expected_version: expectedVersion,
  })
}

// Fan Ads
export async function listFanAds(
  filters: { status?: FanAdStatus; limit?: number; offset?: number } = {}
): Promise<FanAdListResult> {
  if (DEMO_MODE) {
    return {
      items: [],
      total: 0,
      limit: filters.limit ?? 50,
      offset: filters.offset ?? 0,
    }
  }
  if (SKIP_API) return { items: [], total: 0, limit: filters.limit ?? 50, offset: filters.offset ?? 0 }
  return callOpsManage<FanAdListResult>('fan_ad.list', filters)
}

export async function approveFanAd(
  id: string,
  placement: BannerPlacement = 'home_top',
  priority?: number
): Promise<FanAdApproveResult> {
  if (DEMO_MODE) {
    return {
      fan_ad_id: id,
      ops_banner_id: `demo-fan-ad-banner-${Date.now()}`,
      status: 'approved',
    }
  }
  return callOpsManage<FanAdApproveResult>('fan_ad.approve', {
    id,
    placement,
    priority,
  })
}

export async function rejectFanAd(
  id: string,
  rejectionReason: string
): Promise<FanAdRejectResult> {
  if (DEMO_MODE) {
    return {
      fan_ad_id: id,
      status: 'rejected',
    }
  }
  return callOpsManage<FanAdRejectResult>('fan_ad.reject', {
    id,
    rejection_reason: rejectionReason,
  })
}

// Feature Flags
export async function listFlags(
  filters: { status?: string } = {}
): Promise<OpsFeatureFlag[]> {
  if (DEMO_MODE) return DEMO_FLAGS
  if (SKIP_API) return []
  return callOpsManage<OpsFeatureFlag[]>('flag.list', filters)
}

export async function getFlag(id: string): Promise<OpsFeatureFlag> {
  if (DEMO_MODE) {
    const flag = DEMO_FLAGS.find((f) => f.id === id)
    if (!flag) throw new Error('플래그를 찾을 수 없습니다')
    return flag
  }
  if (SKIP_API) throw new Error('Supabase not configured')
  return callOpsManage<OpsFeatureFlag>('flag.get', { id })
}

export async function createFlag(data: FlagFormData): Promise<OpsFeatureFlag> {
  if (DEMO_MODE) {
    return {
      ...DEMO_FLAGS[0],
      ...data,
      payload: data.payload_data,
      id: `demo-flag-${Date.now()}`,
      status: 'draft',
      version: 1,
    }
  }
  return callOpsManage<OpsFeatureFlag>('flag.create', { ...data })
}

export async function updateFlag(
  id: string,
  expectedVersion: number,
  data: Partial<FlagFormData>
): Promise<OpsFeatureFlag> {
  if (DEMO_MODE) {
    const flag = DEMO_FLAGS.find((f) => f.id === id)
    if (!flag) throw new Error('플래그를 찾을 수 없습니다')
    return { ...flag, ...data, version: expectedVersion + 1 }
  }
  return callOpsManage<OpsFeatureFlag>('flag.update', {
    id,
    expected_version: expectedVersion,
    ...data,
  })
}

export async function publishFlag(
  id: string,
  expectedVersion: number
): Promise<OpsFeatureFlag> {
  return callOpsManage<OpsFeatureFlag>('flag.publish', {
    id,
    expected_version: expectedVersion,
  })
}

export async function rollbackFlag(id: string): Promise<OpsFeatureFlag> {
  return callOpsManage<OpsFeatureFlag>('flag.rollback', { id })
}

// Audit
export async function listAuditLog(
  options: {
    entity_type?: string
    entity_id?: string
    limit?: number
    offset?: number
  } = {}
): Promise<PaginatedResult<OpsAuditEntry>> {
  if (DEMO_MODE) return { items: DEMO_AUDIT, total: DEMO_AUDIT.length }
  if (SKIP_API) return { items: [], total: 0 }
  return callOpsManage<PaginatedResult<OpsAuditEntry>>('audit.list', options)
}

// Config
export async function refreshPublicConfig(): Promise<void> {
  if (DEMO_MODE) return
  if (SKIP_API) return
  await callOpsManage('config.refresh')
}

// Dashboard
export async function getDashboardStats(): Promise<OpsDashboardStats> {
  if (DEMO_MODE) {
    return {
      activeBanners: DEMO_BANNERS.filter((b) => b.status === 'published').length,
      activeFlags: DEMO_FLAGS.filter((f) => f.status === 'published').length,
      pendingReview: DEMO_BANNERS.filter((b) => b.status === 'in_review').length,
      recentChanges: DEMO_AUDIT.slice(0, 5),
    }
  }
  if (SKIP_API) return { activeBanners: 0, activeFlags: 0, pendingReview: 0, recentChanges: [] }

  // Parallel fetch
  const [banners, flags, audit] = await Promise.all([
    listBanners(),
    listFlags(),
    listAuditLog({ limit: 5 }),
  ])

  return {
    activeBanners: banners.filter((b) => b.status === 'published').length,
    activeFlags: flags.filter((f) => f.status === 'published').length,
    pendingReview: banners.filter((b) => b.status === 'in_review').length,
    recentChanges: audit.items,
  }
}
