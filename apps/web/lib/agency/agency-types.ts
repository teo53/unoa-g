/**
 * Agency Portal TypeScript Type Definitions
 * Mirrors DB schema from 066_agency_schema.sql + 067_agency_triggers.sql
 */

// ── RBAC ──
export type AgencyStaffRole = 'viewer' | 'manager' | 'finance' | 'admin'

export type AgencyStatus = 'pending' | 'active' | 'suspended'
export type ContractStatus = 'pending' | 'active' | 'paused' | 'terminated'
export type SettlementStatus = 'draft' | 'pending_review' | 'approved' | 'processing' | 'paid' | 'rejected'
export type SettlementPeriodType = 'weekly' | 'biweekly' | 'monthly'
export type TaxCertificateStatus = 'submitted' | 'verified' | 'rejected'

// ── Agency ──
export interface Agency {
  id: string
  name: string
  business_registration_number: string | null
  representative_name: string | null
  logo_url: string | null
  contact_email: string | null
  contact_phone: string | null
  bank_name: string | null
  bank_account_number: string | null
  bank_account_holder: string | null
  tax_type: 'business' | 'individual' | null
  status: AgencyStatus
  verified_at: string | null
  review_notes: string | null
  created_at: string
  updated_at: string
}

// ── Agency Staff ──
export interface AgencyStaff {
  id: string
  agency_id: string
  user_id: string
  role: AgencyStaffRole
  display_name: string | null
  email: string | null
  invited_by: string | null
  accepted_at: string | null
  created_at: string
  updated_at: string
}

// ── Agency Creator (Contract) ──
export interface AgencyCreator {
  id: string
  agency_id: string
  creator_profile_id: string
  status: ContractStatus
  revenue_share_rate: number
  settlement_period: SettlementPeriodType
  contract_start_date: string | null
  contract_end_date: string | null
  contract_document_url: string | null
  power_of_attorney_url: string | null
  notes: string | null
  created_at: string
  updated_at: string
  // Joined fields (from creator_profiles)
  creator?: {
    id: string
    user_id: string
    stage_name: string | null
    avatar_url: string | null
    subscriber_count: number
    categories: string[]
  }
}

// ── Agency Settlement ──
export interface AgencySettlement {
  id: string
  agency_id: string
  period_start: string
  period_end: string
  total_creators: number
  total_gross_krw: number
  total_platform_fee_krw: number
  total_creator_net_krw: number
  agency_commission_krw: number
  agency_tax_type: string | null
  agency_tax_rate: number
  agency_tax_krw: number
  agency_net_krw: number
  creator_breakdown: CreatorBreakdown[]
  status: SettlementStatus
  reviewed_by: string | null
  reviewed_at: string | null
  paid_at: string | null
  notes: string | null
  created_at: string
  updated_at: string
}

export interface CreatorBreakdown {
  creator_id: string
  creator_name?: string
  gross_krw: number
  platform_fee_krw: number
  net_krw: number
  agency_commission_krw: number
  has_power_of_attorney: boolean
}

// ── Tax Certificate ──
export interface AgencyTaxCertificate {
  id: string
  agency_id: string
  period_year: number
  period_month: number
  certificate_type: string
  file_url: string
  uploaded_by: string
  status: TaxCertificateStatus
  verified_by: string | null
  verified_at: string | null
  notes: string | null
  created_at: string
}

// ── Notice ──
export interface AgencyNotice {
  id: string
  agency_id: string | null
  title: string
  content: string
  is_pinned: boolean
  is_platform_notice: boolean
  created_by: string | null
  created_at: string
  updated_at: string
}

// ── Audit Log ──
export interface AgencyAuditEntry {
  id: string
  agency_id: string
  actor_id: string
  actor_role: string
  action: string
  entity_type: string
  entity_id: string | null
  before_data: Record<string, unknown> | null
  after_data: Record<string, unknown> | null
  metadata: Record<string, unknown>
  created_at: string
}

// ── Dashboard Summary ──
export interface AgencyDashboardSummary {
  agency: Agency
  activeCreators: number
  totalCreators: number
  pendingContracts: number
  currentMonthDT: number
  currentMonthKRW: number
  previousMonthKRW: number
  latestSettlement: AgencySettlement | null
}

// ── Stats ──
export interface AgencyStatsOverview {
  totalDT: number
  totalKRW: number
  totalCommission: number
  creatorStats: {
    creator_id: string
    creator_name: string
    avatar_url: string | null
    total_dt: number
    total_krw: number
    commission_krw: number
  }[]
  dailyTrend: {
    date: string
    dt: number
    krw: number
  }[]
}

// ── Role Hierarchy ──
export const AGENCY_ROLE_LEVELS: Record<AgencyStaffRole, number> = {
  viewer: 0,
  manager: 1,
  finance: 2,
  admin: 3,
}

export function hasMinAgencyRole(userRole: AgencyStaffRole, requiredRole: AgencyStaffRole): boolean {
  return AGENCY_ROLE_LEVELS[userRole] >= AGENCY_ROLE_LEVELS[requiredRole]
}
