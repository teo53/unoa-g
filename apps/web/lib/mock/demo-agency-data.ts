/**
 * Demo mock data for Agency Portal
 * Used when Supabase is not configured (DEMO_MODE === true)
 */

import { DEMO_MODE, mockCreators } from './demo-data'
import type {
  Agency,
  AgencyStaff,
  AgencyCreator,
  AgencySettlement,
  AgencyTaxCertificate,
  AgencyNotice,
  AgencyAuditEntry,
  AgencyDashboardSummary,
} from '../agency/agency-types'

export { DEMO_MODE }

// ── Demo Agency ──
export const mockAgency: Agency = {
  id: 'demo-agency-001',
  name: '스타빛엔터테인먼트',
  business_registration_number: '123-45-67890',
  representative_name: '박대표',
  logo_url: 'https://images.unsplash.com/photo-1614680376573-df3480f0c6ff?w=200&h=200&fit=crop',
  contact_email: 'admin@starlight-ent.co.kr',
  contact_phone: '02-1234-5678',
  bank_name: '국민은행',
  bank_account_number: '***-***-****-123',
  bank_account_holder: '(주)스타빛엔터테인먼트',
  tax_type: 'business',
  status: 'active',
  verified_at: '2025-06-15T00:00:00Z',
  review_notes: null,
  created_at: '2025-06-01T00:00:00Z',
  updated_at: '2026-01-15T00:00:00Z',
}

// ── Demo Staff ──
export const mockAgencyStaff: AgencyStaff[] = [
  {
    id: 'demo-staff-001',
    agency_id: 'demo-agency-001',
    user_id: 'demo-staff-user-001',
    role: 'admin',
    display_name: '김운영',
    email: 'kim@starlight-ent.co.kr',
    invited_by: null,
    accepted_at: '2025-06-01T00:00:00Z',
    created_at: '2025-06-01T00:00:00Z',
    updated_at: '2025-06-01T00:00:00Z',
  },
  {
    id: 'demo-staff-002',
    agency_id: 'demo-agency-001',
    user_id: 'demo-staff-user-002',
    role: 'manager',
    display_name: '이매니저',
    email: 'lee@starlight-ent.co.kr',
    invited_by: 'demo-staff-user-001',
    accepted_at: '2025-07-10T00:00:00Z',
    created_at: '2025-07-01T00:00:00Z',
    updated_at: '2025-07-10T00:00:00Z',
  },
  {
    id: 'demo-staff-003',
    agency_id: 'demo-agency-001',
    user_id: 'demo-staff-user-003',
    role: 'finance',
    display_name: '박회계',
    email: 'park@starlight-ent.co.kr',
    invited_by: 'demo-staff-user-001',
    accepted_at: '2025-08-01T00:00:00Z',
    created_at: '2025-07-25T00:00:00Z',
    updated_at: '2025-08-01T00:00:00Z',
  },
  {
    id: 'demo-staff-004',
    agency_id: 'demo-agency-001',
    user_id: 'demo-staff-user-004',
    role: 'viewer',
    display_name: '최인턴',
    email: 'choi@starlight-ent.co.kr',
    invited_by: 'demo-staff-user-001',
    accepted_at: '2026-01-05T00:00:00Z',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-05T00:00:00Z',
  },
]

// ── Demo Creators (Agency Contracts) ──
export const mockAgencyCreators: AgencyCreator[] = [
  {
    id: 'demo-contract-001',
    agency_id: 'demo-agency-001',
    creator_profile_id: 'demo-creator-1',
    status: 'active',
    revenue_share_rate: 0.10,
    settlement_period: 'monthly',
    contract_start_date: '2025-07-01',
    contract_end_date: '2027-06-30',
    contract_document_url: '/documents/contract-waker.pdf',
    power_of_attorney_url: null,
    notes: null,
    created_at: '2025-06-20T00:00:00Z',
    updated_at: '2025-07-01T00:00:00Z',
    creator: {
      id: 'demo-creator-1',
      user_id: 'demo-user-creator-1',
      stage_name: 'WAKER',
      avatar_url: mockCreators['demo-creator-1']?.avatar_url || null,
      subscriber_count: 1234,
      categories: ['K-POP', '아이돌'],
    },
  },
  {
    id: 'demo-contract-002',
    agency_id: 'demo-agency-001',
    creator_profile_id: 'demo-creator-2',
    status: 'active',
    revenue_share_rate: 0.15,
    settlement_period: 'monthly',
    contract_start_date: '2025-09-01',
    contract_end_date: '2027-08-31',
    contract_document_url: '/documents/contract-moonlight.pdf',
    power_of_attorney_url: '/documents/poa-moonlight.pdf',
    notes: '통합 정산 (위임장 있음)',
    created_at: '2025-08-15T00:00:00Z',
    updated_at: '2025-09-01T00:00:00Z',
    creator: {
      id: 'demo-creator-2',
      user_id: 'demo-user-creator-2',
      stage_name: 'MOONLIGHT',
      avatar_url: mockCreators['demo-creator-2']?.avatar_url || null,
      subscriber_count: 856,
      categories: ['독립', '싱어송라이터'],
    },
  },
  {
    id: 'demo-contract-003',
    agency_id: 'demo-agency-001',
    creator_profile_id: 'demo-creator-3',
    status: 'pending',
    revenue_share_rate: 0.10,
    settlement_period: 'monthly',
    contract_start_date: '2026-03-01',
    contract_end_date: null,
    contract_document_url: null,
    power_of_attorney_url: null,
    notes: '계약 승인 대기 중',
    created_at: '2026-02-10T00:00:00Z',
    updated_at: '2026-02-10T00:00:00Z',
    creator: {
      id: 'demo-creator-3',
      user_id: 'demo-user-creator-3',
      stage_name: 'STARLIGHT',
      avatar_url: mockCreators['demo-creator-3']?.avatar_url || null,
      subscriber_count: 432,
      categories: ['솔로', 'R&B'],
    },
  },
]

// ── Demo Settlements ──
export const mockAgencySettlements: AgencySettlement[] = [
  {
    id: 'demo-settlement-001',
    agency_id: 'demo-agency-001',
    period_start: '2026-01-01',
    period_end: '2026-01-31',
    total_creators: 2,
    total_gross_krw: 3500000,
    total_platform_fee_krw: 700000,
    total_creator_net_krw: 2800000,
    agency_commission_krw: 330000,
    agency_tax_type: 'invoice',
    agency_tax_rate: 0,
    agency_tax_krw: 0,
    agency_net_krw: 330000,
    creator_breakdown: [
      {
        creator_id: 'demo-creator-1',
        creator_name: 'WAKER',
        gross_krw: 2000000,
        platform_fee_krw: 400000,
        net_krw: 1600000,
        agency_commission_krw: 160000,
        has_power_of_attorney: false,
      },
      {
        creator_id: 'demo-creator-2',
        creator_name: 'MOONLIGHT',
        gross_krw: 1500000,
        platform_fee_krw: 300000,
        net_krw: 1200000,
        agency_commission_krw: 180000,
        has_power_of_attorney: true,
      },
    ],
    status: 'paid',
    reviewed_by: 'ops-admin-001',
    reviewed_at: '2026-02-03T10:00:00Z',
    paid_at: '2026-02-05T14:00:00Z',
    notes: null,
    created_at: '2026-02-01T00:00:00Z',
    updated_at: '2026-02-05T14:00:00Z',
  },
  {
    id: 'demo-settlement-002',
    agency_id: 'demo-agency-001',
    period_start: '2026-02-01',
    period_end: '2026-02-28',
    total_creators: 2,
    total_gross_krw: 4200000,
    total_platform_fee_krw: 840000,
    total_creator_net_krw: 3360000,
    agency_commission_krw: 396000,
    agency_tax_type: 'invoice',
    agency_tax_rate: 0,
    agency_tax_krw: 0,
    agency_net_krw: 396000,
    creator_breakdown: [
      {
        creator_id: 'demo-creator-1',
        creator_name: 'WAKER',
        gross_krw: 2500000,
        platform_fee_krw: 500000,
        net_krw: 2000000,
        agency_commission_krw: 200000,
        has_power_of_attorney: false,
      },
      {
        creator_id: 'demo-creator-2',
        creator_name: 'MOONLIGHT',
        gross_krw: 1700000,
        platform_fee_krw: 340000,
        net_krw: 1360000,
        agency_commission_krw: 204000,
        has_power_of_attorney: true,
      },
    ],
    status: 'pending_review',
    reviewed_by: null,
    reviewed_at: null,
    paid_at: null,
    notes: null,
    created_at: '2026-03-01T00:00:00Z',
    updated_at: '2026-03-01T00:00:00Z',
  },
]

// ── Demo Tax Certificates ──
export const mockAgencyTaxCertificates: AgencyTaxCertificate[] = [
  {
    id: 'demo-tax-001',
    agency_id: 'demo-agency-001',
    period_year: 2026,
    period_month: 1,
    certificate_type: 'tax_clearance',
    file_url: '/documents/tax-202601.pdf',
    uploaded_by: 'demo-staff-user-003',
    status: 'verified',
    verified_by: 'ops-admin-001',
    verified_at: '2026-02-10T00:00:00Z',
    notes: null,
    created_at: '2026-02-05T00:00:00Z',
  },
]

// ── Demo Notices ──
export const mockAgencyNotices: AgencyNotice[] = [
  {
    id: 'demo-notice-001',
    agency_id: null,
    title: '[공지] 2026년 2월 정산 일정 안내',
    content: '2026년 2월 정산은 3월 5일(목)에 진행됩니다. 정산 내역 확인 후 이상 시 2월 28일까지 문의 바랍니다.',
    is_pinned: true,
    is_platform_notice: true,
    created_by: null,
    created_at: '2026-02-01T09:00:00Z',
    updated_at: '2026-02-01T09:00:00Z',
  },
  {
    id: 'demo-notice-002',
    agency_id: null,
    title: '[안내] 세금완납증명서 제출 기한 변경',
    content: '2026년부터 세금완납증명서 제출 기한이 매월 10일에서 15일로 변경됩니다. 자세한 내용은 아래를 참고해주세요.',
    is_pinned: false,
    is_platform_notice: true,
    created_by: null,
    created_at: '2026-01-15T09:00:00Z',
    updated_at: '2026-01-15T09:00:00Z',
  },
  {
    id: 'demo-notice-003',
    agency_id: 'demo-agency-001',
    title: 'WAKER 3월 컴백 일정 내부 공유',
    content: 'WAKER의 3월 컴백 관련 일정입니다. 내부 참고용으로 외부 유출 금지.',
    is_pinned: false,
    is_platform_notice: false,
    created_by: 'demo-staff-user-001',
    created_at: '2026-02-12T14:00:00Z',
    updated_at: '2026-02-12T14:00:00Z',
  },
]

// ── Demo Audit Log ──
export const mockAgencyAuditLog: AgencyAuditEntry[] = [
  {
    id: 'demo-audit-001',
    agency_id: 'demo-agency-001',
    actor_id: 'demo-staff-user-001',
    actor_role: 'admin',
    action: 'creator.add',
    entity_type: 'agency_creators',
    entity_id: 'demo-contract-003',
    before_data: null,
    after_data: { status: 'pending', creator: 'STARLIGHT', revenue_share_rate: 0.10 },
    metadata: {},
    created_at: '2026-02-10T15:30:00Z',
  },
  {
    id: 'demo-audit-002',
    agency_id: 'demo-agency-001',
    actor_id: 'demo-staff-user-001',
    actor_role: 'admin',
    action: 'staff.invite',
    entity_type: 'agency_staff',
    entity_id: 'demo-staff-004',
    before_data: null,
    after_data: { role: 'viewer', display_name: '최인턴' },
    metadata: {},
    created_at: '2026-01-01T10:00:00Z',
  },
  {
    id: 'demo-audit-003',
    agency_id: 'demo-agency-001',
    actor_id: 'demo-staff-user-003',
    actor_role: 'finance',
    action: 'tax.upload',
    entity_type: 'agency_tax_certificates',
    entity_id: 'demo-tax-001',
    before_data: null,
    after_data: { period: '2026-01', type: 'tax_clearance' },
    metadata: {},
    created_at: '2026-02-05T11:00:00Z',
  },
]

// ── Static Params Helpers (for Next.js static export) ──
export function getMockAgencyCreatorIds(): string[] {
  return mockAgencyCreators.map(c => c.id)
}

export function getMockAgencySettlementIds(): string[] {
  return mockAgencySettlements.map(s => s.id)
}

// ── Dashboard Summary ──
export const mockAgencyDashboard: AgencyDashboardSummary = {
  agency: mockAgency,
  activeCreators: 2,
  totalCreators: 3,
  pendingContracts: 1,
  currentMonthDT: 42000,
  currentMonthKRW: 4200000,
  previousMonthKRW: 3500000,
  latestSettlement: mockAgencySettlements[1],
}
