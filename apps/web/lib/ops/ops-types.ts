/**
 * Ops CRM TypeScript Type Definitions
 */

// ── RBAC ──
export type OpsRole = 'viewer' | 'operator' | 'publisher' | 'admin'

export interface OpsStaff {
  id: string
  user_id: string
  role: OpsRole
  display_name: string | null
  created_at: string
  updated_at: string
  // joined from auth.users
  user?: {
    email: string
    raw_user_meta_data: Record<string, unknown>
  }
}

// ── Assets ──
export interface OpsAsset {
  id: string
  file_name: string
  storage_path: string
  public_url: string
  mime_type: string
  file_size: number
  width: number | null
  height: number | null
  tags: string[]
  alt_text: string
  uploaded_by: string
  created_at: string
}

// ── Banners ──
export type BannerPlacement =
  | 'home_top'
  | 'home_bottom'
  | 'discover_top'
  | 'chat_top'
  | 'chat_list'
  | 'profile_banner'
  | 'funding_top'
  | 'popup'

export type BannerStatus = 'draft' | 'in_review' | 'published' | 'archived'
export type LinkType = 'internal' | 'external' | 'none'
export type TargetAudience = 'all' | 'fans' | 'creators' | 'vip'

export interface OpsBanner {
  id: string
  title: string
  placement: BannerPlacement
  image_url: string
  link_url: string
  link_type: LinkType
  status: BannerStatus
  priority: number
  start_at: string | null
  end_at: string | null
  target_audience: TargetAudience
  version: number
  published_snapshot: Record<string, unknown> | null
  created_by: string
  updated_by: string | null
  created_at: string
  updated_at: string
}

// ── Fan Ads ──
export type FanAdStatus =
  | 'pending_review'
  | 'approved'
  | 'active'
  | 'completed'
  | 'rejected'
  | 'cancelled'

export type FanAdPaymentStatus = 'pending' | 'paid' | 'refunded' | 'failed'

export interface OpsFanAd {
  id: string
  fan_user_id: string
  artist_channel_id: string
  title: string
  body: string | null
  image_url: string | null
  link_url: string | null
  link_type: LinkType
  start_at: string
  end_at: string
  payment_amount_krw: number
  payment_status: FanAdPaymentStatus
  status: FanAdStatus
  rejection_reason: string | null
  impressions: number
  clicks: number
  created_at: string
  updated_at: string
  ops_banner_id: string | null
}

export interface FanAdListResult {
  items: OpsFanAd[]
  total: number
  limit: number
  offset: number
}

export interface FanAdApproveResult {
  fan_ad_id: string
  ops_banner_id: string
  status: 'approved'
}

export interface FanAdRejectResult {
  fan_ad_id: string
  status: 'rejected'
}

// ── Feature Flags ──
export type FlagStatus = 'draft' | 'published' | 'archived'

export interface OpsFeatureFlag {
  id: string
  flag_key: string
  title: string
  description: string
  status: FlagStatus
  enabled: boolean
  rollout_percent: number
  payload: Record<string, unknown>
  version: number
  published_snapshot: Record<string, unknown> | null
  created_by: string
  updated_by: string | null
  created_at: string
  updated_at: string
}

// ── Audit Log ──
export interface OpsAuditEntry {
  id: string
  actor_id: string
  actor_role: string
  action: string
  entity_type: string
  entity_id: string | null
  before: Record<string, unknown> | null
  after: Record<string, unknown> | null
  metadata: Record<string, unknown>
  created_at: string
}

// ── App Public Config ──
export interface AppPublicConfig {
  id: string
  banners: PublishedBanner[]
  flags: Record<string, PublishedFlag>
  config_hash: string
  refreshed_at: string
}

export interface PublishedBanner {
  id: string
  title: string
  placement: BannerPlacement
  image_url: string
  link_url: string
  link_type: LinkType
  priority: number
  target_audience: TargetAudience
  start_at: string | null
  end_at: string | null
}

export interface PublishedFlag {
  enabled: boolean
  rollout_percent: number
  payload: Record<string, unknown>
}

// ── API Request/Response ──
export interface OpsApiResponse<T = unknown> {
  success: boolean
  data?: T
  error?: string
}

export interface PaginatedResult<T> {
  items: T[]
  total: number
  limit?: number
  offset?: number
}

// ── Banner Form Data ──
export interface BannerFormData {
  title: string
  placement: BannerPlacement
  image_url: string
  link_url: string
  link_type: LinkType
  priority: number
  start_at: string
  end_at: string
  target_audience: TargetAudience
}

// ── Flag Form Data ──
export interface FlagFormData {
  flag_key: string
  title: string
  description: string
  enabled: boolean
  rollout_percent: number
  payload_data: Record<string, unknown>
}

// ── Dashboard Stats ──
export interface OpsDashboardStats {
  activeBanners: number
  activeFlags: number
  pendingReview: number
  recentChanges: OpsAuditEntry[]
}

// ── Status label/color mapping ──
export const STATUS_CONFIG: Record<
  string,
  { label: string; color: string; bgColor: string }
> = {
  draft: { label: '초안', color: 'text-gray-700', bgColor: 'bg-gray-100' },
  in_review: { label: '검수 중', color: 'text-yellow-700', bgColor: 'bg-yellow-100' },
  published: { label: '게시됨', color: 'text-green-700', bgColor: 'bg-green-100' },
  archived: { label: '보관됨', color: 'text-red-700', bgColor: 'bg-red-100' },
}

export const PLACEMENT_LABELS: Record<BannerPlacement, string> = {
  home_top: '홈 상단',
  home_bottom: '홈 하단',
  discover_top: '탐색 상단',
  chat_top: '채팅 상단 (레거시)',
  chat_list: '채팅 목록 배너',
  profile_banner: '프로필 배너',
  funding_top: '펀딩 상단',
  popup: '팝업',
}

export const PLACEMENT_DIMENSIONS: Record<BannerPlacement, {
  width: number; height: number;
  label: string; description: string;
  aspectRatio: string;
  safeZone?: string;
}> = {
  home_top:       { width: 1200, height: 300, label: '홈 상단', description: '메인 히어로 배너 — 풀 너비', aspectRatio: '4:1', safeZone: '좌우 16px 여백' },
  home_bottom:    { width: 1200, height: 200, label: '홈 하단', description: '보조 프로모션 띠 배너', aspectRatio: '6:1' },
  discover_top:   { width: 800, height: 400, label: '탐색 상단', description: '탐색 페이지 배너', aspectRatio: '2:1' },
  chat_top:       { width: 600, height: 150, label: '채팅 상단 (레거시)', description: '채팅 리스트 상단 띠 — chat_list 권장', aspectRatio: '4:1' },
  chat_list:      { width: 600, height: 120, label: '채팅 목록 배너', description: '채팅 목록 검색창 아래 네이티브 배너', aspectRatio: '5:1' },
  profile_banner: { width: 800, height: 300, label: '프로필 배너', description: '프로필 헤더 영역', aspectRatio: '8:3' },
  funding_top:    { width: 800, height: 200, label: '펀딩 상단', description: '펀딩 페이지 헤더 아래 띠 배너', aspectRatio: '4:1' },
  popup:          { width: 600, height: 800, label: '팝업', description: '모달 팝업 (세로)', aspectRatio: '3:4' },
}

export const ROLE_LABELS: Record<OpsRole, string> = {
  viewer: '뷰어',
  operator: '운영자',
  publisher: '발행자',
  admin: '관리자',
}
