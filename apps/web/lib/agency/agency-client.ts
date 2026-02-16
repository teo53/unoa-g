/**
 * Agency Portal API Client
 * Follows the same pattern as ops-client.ts (callOpsManage).
 * Each wrapper checks DEMO_MODE and falls back to mock data.
 */

import { createBrowserClient } from '@supabase/ssr'
import type { OpsApiResponse } from '../ops/ops-types'
import {
  DEMO_MODE,
  mockAgency,
  mockAgencyStaff,
  mockAgencyCreators,
  mockAgencySettlements,
  mockAgencyTaxCertificates,
  mockAgencyNotices,
  mockAgencyAuditLog,
  mockAgencyDashboard,
} from '../mock/demo-agency-data'
import type {
  Agency,
  AgencyStaff,
  AgencyCreator,
  AgencySettlement,
  AgencyTaxCertificate,
  AgencyNotice,
  AgencyAuditEntry,
  AgencyDashboardSummary,
} from './agency-types'

// ── Client ──

function getSupabaseClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
  return createBrowserClient(url, key)
}

async function callAgencyManage<T>(
  action: string,
  payload: Record<string, unknown> = {}
): Promise<T> {
  const supabase = getSupabaseClient()
  const { data: { session } } = await supabase.auth.getSession()

  if (!session?.access_token) {
    throw new Error('인증이 필요합니다. 다시 로그인해주세요.')
  }

  const url = `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/agency-manage`

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

// ── Dashboard ──

export async function getAgencyDashboard(): Promise<AgencyDashboardSummary> {
  if (DEMO_MODE) return mockAgencyDashboard
  return callAgencyManage<AgencyDashboardSummary>('dashboard.summary')
}

// ── Creators ──

export async function listAgencyCreators(): Promise<AgencyCreator[]> {
  if (DEMO_MODE) return mockAgencyCreators
  return callAgencyManage<AgencyCreator[]>('creator.list')
}

export async function getAgencyCreator(id: string): Promise<AgencyCreator | null> {
  if (DEMO_MODE) return mockAgencyCreators.find(c => c.id === id) ?? null
  return callAgencyManage<AgencyCreator | null>('creator.get', { id })
}

export async function registerCreator(data: Record<string, unknown>): Promise<AgencyCreator> {
  if (DEMO_MODE) throw new Error('데모 모드에서는 등록할 수 없습니다')
  return callAgencyManage<AgencyCreator>('creator.register', data)
}

// ── Settlements ──

export async function listAgencySettlements(): Promise<AgencySettlement[]> {
  if (DEMO_MODE) return mockAgencySettlements
  return callAgencyManage<AgencySettlement[]>('settlement.list')
}

export async function getAgencySettlement(id: string): Promise<AgencySettlement | null> {
  if (DEMO_MODE) return mockAgencySettlements.find(s => s.id === id) ?? null
  return callAgencyManage<AgencySettlement | null>('settlement.get', { id })
}

export async function approveSettlement(id: string): Promise<AgencySettlement> {
  if (DEMO_MODE) throw new Error('데모 모드에서는 승인할 수 없습니다')
  return callAgencyManage<AgencySettlement>('settlement.approve', { id })
}

// ── Agency Settings ──

export async function getAgencySettings(): Promise<Agency> {
  if (DEMO_MODE) return mockAgency
  return callAgencyManage<Agency>('agency.get')
}

export async function updateAgencySettings(data: Record<string, unknown>): Promise<Agency> {
  if (DEMO_MODE) throw new Error('데모 모드에서는 변경할 수 없습니다')
  return callAgencyManage<Agency>('agency.update', data)
}

// ── Staff ──

export async function listAgencyStaff(): Promise<AgencyStaff[]> {
  if (DEMO_MODE) return mockAgencyStaff
  return callAgencyManage<AgencyStaff[]>('staff.list')
}

export async function inviteStaffMember(email: string, role: string): Promise<AgencyStaff> {
  if (DEMO_MODE) throw new Error('데모 모드에서는 초대할 수 없습니다')
  return callAgencyManage<AgencyStaff>('staff.invite', { email, role })
}

// ── Notices ──

export async function listAgencyNotices(): Promise<AgencyNotice[]> {
  if (DEMO_MODE) return mockAgencyNotices
  return callAgencyManage<AgencyNotice[]>('notice.list')
}

// ── Tax Certificates ──

export async function listAgencyTaxCertificates(): Promise<AgencyTaxCertificate[]> {
  if (DEMO_MODE) return mockAgencyTaxCertificates
  return callAgencyManage<AgencyTaxCertificate[]>('tax.list')
}

// ── Audit Log ──

export async function listAgencyAuditLog(): Promise<AgencyAuditEntry[]> {
  if (DEMO_MODE) return mockAgencyAuditLog
  return callAgencyManage<AgencyAuditEntry[]>('audit.list')
}

// ── Statistics ──

export async function getAgencyStatistics(): Promise<AgencyDashboardSummary> {
  if (DEMO_MODE) return mockAgencyDashboard
  return callAgencyManage<AgencyDashboardSummary>('statistics.overview')
}

// ── Recent Data (for dashboard) ──

export async function getRecentCreators(): Promise<AgencyCreator[]> {
  if (DEMO_MODE) return mockAgencyCreators
  return callAgencyManage<AgencyCreator[]>('creator.list', { limit: 5 })
}

export async function getRecentSettlements(): Promise<AgencySettlement[]> {
  if (DEMO_MODE) return mockAgencySettlements
  return callAgencyManage<AgencySettlement[]>('settlement.list', { limit: 5 })
}
