/**
 * agency-manage — Multiplexer Edge Function for Agency Management
 *
 * Single endpoint handling all agency CRUD + creator management + settlements.
 * POST /agency-manage { action: string, payload: object }
 *
 * Actions:
 *   dashboard.summary
 *   creator.list / creator.search / creator.add / creator.update / creator.remove
 *   stats.overview / stats.creator
 *   settlement.list / settlement.get
 *   tax.certificates / tax.upload
 *   staff.list / staff.invite / staff.update / staff.remove
 *   agency.profile / agency.update
 *   notice.list
 *   audit.list
 *
 * Security:
 *   - Auth via Bearer token (getUser)
 *   - RBAC via agency_staff table
 *   - Agency scoping: all operations filter by user's agency_id
 *   - Input validation on every action (no `as any`)
 *   - Rate limiting via DB-based counter
 *   - Structured logging with PII masking
 *   - Audit logging via log_agency_audit() PL/pgSQL RPC
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders } from '../_shared/cors.ts'
import { checkRateLimit, rateLimitHeaders } from '../_shared/rate_limit.ts'
import { log, maskUserId } from '../_shared/logger.ts'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

const jsonHeaders = { 'Content-Type': 'application/json' }

// ══════════════════════════════════════════════════
// Input Validation Utilities (pure TS, no external deps)
// ══════════════════════════════════════════════════

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

class ValidationError extends Error {
  statusCode = 400
  constructor(message: string) {
    super(message)
    this.name = 'ValidationError'
  }
}

function requireUUID(v: unknown, field: string): string {
  if (typeof v !== 'string' || !UUID_RE.test(v)) {
    throw new ValidationError(`${field}: must be a valid UUID`)
  }
  return v
}

function requireEnum<T extends string>(v: unknown, allowed: T[], field: string): T {
  if (typeof v !== 'string' || !allowed.includes(v as T)) {
    throw new ValidationError(`${field}: must be one of [${allowed.join(', ')}]`)
  }
  return v as T
}

function requireString(v: unknown, field: string, min: number, max: number): string {
  if (typeof v !== 'string') {
    throw new ValidationError(`${field}: must be a string`)
  }
  if (v.length < min || v.length > max) {
    throw new ValidationError(`${field}: length must be ${min}-${max}`)
  }
  return v
}

function optionalString(v: unknown, field: string, max: number): string | undefined {
  if (v === undefined || v === null || v === '') return undefined
  if (typeof v !== 'string') {
    throw new ValidationError(`${field}: must be a string`)
  }
  if (v.length > max) {
    throw new ValidationError(`${field}: max length ${max}`)
  }
  return v
}

function requireInt(v: unknown, field: string, min: number, max: number): number {
  const n = typeof v === 'string' ? parseInt(v, 10) : v
  if (typeof n !== 'number' || !Number.isInteger(n) || n < min || n > max) {
    throw new ValidationError(`${field}: must be integer ${min}-${max}`)
  }
  return n
}

function optionalInt(v: unknown, field: string, min: number, max: number): number | undefined {
  if (v === undefined || v === null) return undefined
  return requireInt(v, field, min, max)
}

function requireNumber(v: unknown, field: string, min: number, max: number): number {
  const n = typeof v === 'string' ? parseFloat(v) : v
  if (typeof n !== 'number' || isNaN(n) || n < min || n > max) {
    throw new ValidationError(`${field}: must be number ${min}-${max}`)
  }
  return n
}

function requireDate(v: unknown, field: string): string {
  if (typeof v !== 'string') {
    throw new ValidationError(`${field}: must be an ISO date string`)
  }
  // Basic date format check (YYYY-MM-DD or ISO 8601)
  if (isNaN(Date.parse(v))) {
    throw new ValidationError(`${field}: invalid date format`)
  }
  return v
}

function optionalDate(v: unknown, field: string): string | null {
  if (v === undefined || v === null || v === '') return null
  return requireDate(v, field)
}

function requireSafeUrl(v: unknown, field: string): string {
  if (typeof v !== 'string') {
    throw new ValidationError(`${field}: must be a string URL`)
  }
  const lower = v.toLowerCase().trim()
  if (lower.startsWith('javascript:') || lower.startsWith('data:') || lower.startsWith('vbscript:')) {
    throw new ValidationError(`${field}: unsafe URL protocol`)
  }
  return v
}

function optionalSafeUrl(v: unknown, field: string): string | undefined {
  if (v === undefined || v === null || v === '') return undefined
  return requireSafeUrl(v, field)
}

function requireEmail(v: unknown, field: string): string {
  if (typeof v !== 'string' || !EMAIL_RE.test(v)) {
    throw new ValidationError(`${field}: must be a valid email`)
  }
  return v
}

// ══════════════════════════════════════════════════
// Per-Action Validation Schemas
// ══════════════════════════════════════════════════

const AGENCY_STAFF_ROLES = ['viewer', 'manager', 'finance', 'admin'] as const
const CREATOR_STATUSES = ['pending', 'active', 'paused', 'terminated'] as const
const SETTLEMENT_BASES = ['weekly', 'biweekly', 'monthly'] as const
const SETTLEMENT_STATUSES = ['draft', 'pending_review', 'approved', 'processing', 'paid', 'cancelled'] as const
const TAX_DOCUMENT_TYPES = ['tax_clearance', 'business_income', 'tax_invoice', 'withholding'] as const
const TAX_STATUSES = ['not_submitted', 'submitted', 'approved', 'rejected'] as const

// -- Creator Management --
interface ValidatedCreatorList { status?: string; limit?: number; offset?: number }
function validateCreatorList(p: Record<string, unknown>): ValidatedCreatorList {
  return {
    status: p.status ? requireEnum(p.status, [...CREATOR_STATUSES], 'status') : undefined,
    limit: optionalInt(p.limit, 'limit', 1, 100),
    offset: optionalInt(p.offset, 'offset', 0, 100000),
  }
}

interface ValidatedCreatorSearch { query?: string; limit?: number }
function validateCreatorSearch(p: Record<string, unknown>): ValidatedCreatorSearch {
  return {
    query: optionalString(p.query, 'query', 200),
    limit: optionalInt(p.limit, 'limit', 1, 50),
  }
}

interface ValidatedCreatorAdd {
  creator_profile_id: string
  contract_start: string
  contract_end?: string | null
  revenue_share_rate: number
  settlement_basis?: string
  contract_document_url?: string
  power_of_attorney_url?: string
  contract_notes?: string
}
function validateCreatorAdd(p: Record<string, unknown>): ValidatedCreatorAdd {
  return {
    creator_profile_id: requireUUID(p.creator_profile_id, 'creator_profile_id'),
    contract_start: requireDate(p.contract_start, 'contract_start'),
    contract_end: optionalDate(p.contract_end, 'contract_end'),
    revenue_share_rate: requireNumber(p.revenue_share_rate, 'revenue_share_rate', 0, 1),
    settlement_basis: p.settlement_basis ? requireEnum(p.settlement_basis, [...SETTLEMENT_BASES], 'settlement_basis') : undefined,
    contract_document_url: optionalSafeUrl(p.contract_document_url, 'contract_document_url'),
    power_of_attorney_url: optionalSafeUrl(p.power_of_attorney_url, 'power_of_attorney_url'),
    contract_notes: optionalString(p.contract_notes, 'contract_notes', 2000),
  }
}

interface ValidatedCreatorUpdate {
  id: string
  revenue_share_rate?: number
  settlement_basis?: string
  contract_end?: string | null
  contract_notes?: string
  contract_document_url?: string
  power_of_attorney_url?: string
}
function validateCreatorUpdate(p: Record<string, unknown>): ValidatedCreatorUpdate {
  return {
    id: requireUUID(p.id, 'id'),
    revenue_share_rate: p.revenue_share_rate !== undefined
      ? requireNumber(p.revenue_share_rate, 'revenue_share_rate', 0, 1)
      : undefined,
    settlement_basis: p.settlement_basis ? requireEnum(p.settlement_basis, [...SETTLEMENT_BASES], 'settlement_basis') : undefined,
    contract_end: p.contract_end !== undefined ? optionalDate(p.contract_end, 'contract_end') : undefined,
    contract_notes: optionalString(p.contract_notes, 'contract_notes', 2000),
    contract_document_url: optionalSafeUrl(p.contract_document_url, 'contract_document_url'),
    power_of_attorney_url: optionalSafeUrl(p.power_of_attorney_url, 'power_of_attorney_url'),
  }
}

interface ValidatedCreatorRemove { id: string }
function validateCreatorRemove(p: Record<string, unknown>): ValidatedCreatorRemove {
  return { id: requireUUID(p.id, 'id') }
}

// -- Stats --
interface ValidatedStatsOverview {
  period_start?: string
  period_end?: string
}
function validateStatsOverview(p: Record<string, unknown>): ValidatedStatsOverview {
  return {
    period_start: p.period_start ? requireDate(p.period_start, 'period_start') : undefined,
    period_end: p.period_end ? requireDate(p.period_end, 'period_end') : undefined,
  }
}

interface ValidatedStatsCreator { creator_profile_id: string }
function validateStatsCreator(p: Record<string, unknown>): ValidatedStatsCreator {
  return {
    creator_profile_id: requireUUID(p.creator_profile_id, 'creator_profile_id'),
  }
}

// -- Settlements --
interface ValidatedSettlementList { status?: string; limit?: number; offset?: number }
function validateSettlementList(p: Record<string, unknown>): ValidatedSettlementList {
  return {
    status: p.status ? requireEnum(p.status, [...SETTLEMENT_STATUSES], 'status') : undefined,
    limit: optionalInt(p.limit, 'limit', 1, 100),
    offset: optionalInt(p.offset, 'offset', 0, 100000),
  }
}

interface ValidatedSettlementGet { id: string }
function validateSettlementGet(p: Record<string, unknown>): ValidatedSettlementGet {
  return { id: requireUUID(p.id, 'id') }
}

// -- Tax --
interface ValidatedTaxUpload {
  year: number
  month: number
  document_type: string
  document_url: string
}
function validateTaxUpload(p: Record<string, unknown>): ValidatedTaxUpload {
  return {
    year: requireInt(p.year, 'year', 2020, 2100),
    month: requireInt(p.month, 'month', 1, 12),
    document_type: requireEnum(p.document_type, [...TAX_DOCUMENT_TYPES], 'document_type'),
    document_url: requireSafeUrl(p.document_url, 'document_url'),
  }
}

// -- Staff --
interface ValidatedStaffInvite { email: string; role: string }
function validateStaffInvite(p: Record<string, unknown>): ValidatedStaffInvite {
  return {
    email: requireEmail(p.email, 'email'),
    role: requireEnum(p.role, [...AGENCY_STAFF_ROLES], 'role'),
  }
}

interface ValidatedStaffUpdate { user_id: string; role: string }
function validateStaffUpdate(p: Record<string, unknown>): ValidatedStaffUpdate {
  return {
    user_id: requireUUID(p.user_id, 'user_id'),
    role: requireEnum(p.role, [...AGENCY_STAFF_ROLES], 'role'),
  }
}

interface ValidatedStaffRemove { user_id: string }
function validateStaffRemove(p: Record<string, unknown>): ValidatedStaffRemove {
  return { user_id: requireUUID(p.user_id, 'user_id') }
}

// -- Agency Profile --
interface ValidatedAgencyUpdate {
  name?: string
  logo_url?: string
  website_url?: string
  phone?: string
  address?: string
  bank_code?: string
  bank_name?: string
  bank_account?: string
  account_holder?: string
}
function validateAgencyUpdate(p: Record<string, unknown>): ValidatedAgencyUpdate {
  return {
    name: optionalString(p.name, 'name', 200),
    logo_url: optionalSafeUrl(p.logo_url, 'logo_url'),
    website_url: optionalSafeUrl(p.website_url, 'website_url'),
    phone: optionalString(p.phone, 'phone', 50),
    address: optionalString(p.address, 'address', 500),
    bank_code: optionalString(p.bank_code, 'bank_code', 10),
    bank_name: optionalString(p.bank_name, 'bank_name', 100),
    bank_account: optionalString(p.bank_account, 'bank_account', 50),
    account_holder: optionalString(p.account_holder, 'account_holder', 100),
  }
}

// -- Audit --
interface ValidatedAuditList { entity_type?: string; entity_id?: string; limit?: number; offset?: number }
function validateAuditList(p: Record<string, unknown>): ValidatedAuditList {
  return {
    entity_type: optionalString(p.entity_type, 'entity_type', 100),
    entity_id: p.entity_id ? requireUUID(p.entity_id, 'entity_id') : undefined,
    limit: optionalInt(p.limit, 'limit', 1, 100),
    offset: optionalInt(p.offset, 'offset', 0, 100000),
  }
}

// ══════════════════════════════════════════════════
// Role hierarchy
// ══════════════════════════════════════════════════

const ROLE_LEVELS: Record<string, number> = {
  viewer: 1,
  manager: 2,
  finance: 3,
  admin: 4,
}

// ══════════════════════════════════════════════════
// Helpers
// ══════════════════════════════════════════════════

function ok(data: unknown, req: Request, extraHeaders: Record<string, string> = {}) {
  return new Response(JSON.stringify({ success: true, data }), {
    status: 200,
    headers: { ...getCorsHeaders(req), ...jsonHeaders, ...extraHeaders },
  })
}

function err(status: number, message: string, req: Request, extraHeaders: Record<string, string> = {}) {
  return new Response(JSON.stringify({ success: false, error: message }), {
    status,
    headers: { ...getCorsHeaders(req), ...jsonHeaders, ...extraHeaders },
  })
}

interface StaffInfo {
  agencyId: string
  role: string
}

async function getStaffInfo(
  admin: SupabaseClient,
  userId: string
): Promise<StaffInfo | null> {
  const { data } = await admin
    .from('agency_staff')
    .select('agency_id, role')
    .eq('user_id', userId)
    .not('accepted_at', 'is', null)
    .order('created_at', { ascending: true })
    .limit(1)
    .single()

  if (!data) return null

  return {
    agencyId: data.agency_id,
    role: data.role,
  }
}

function hasMinRole(userRole: string | null, minRole: string): boolean {
  if (!userRole) return false
  return (ROLE_LEVELS[userRole] ?? 0) >= (ROLE_LEVELS[minRole] ?? 99)
}

async function auditLog(
  admin: SupabaseClient,
  agencyId: string,
  action: string,
  entityType: string,
  entityId: string | null,
  before: unknown | null,
  after: unknown | null,
  metadata: unknown = {}
) {
  await admin.rpc('log_agency_audit', {
    p_agency_id: agencyId,
    p_action: action,
    p_entity_type: entityType,
    p_entity_id: entityId,
    p_before: before,
    p_after: after,
    p_metadata: metadata,
  })
}

// ══════════════════════════════════════════════════
// Action Handlers
// ══════════════════════════════════════════════════

// dashboard.summary
async function dashboardSummary(admin: SupabaseClient, agencyId: string) {
  // Get creator counts by status
  const { data: creators } = await admin
    .from('agency_creators')
    .select('status')
    .eq('agency_id', agencyId)

  const totalCreators = creators?.length || 0
  const activeCreators = creators?.filter(c => c.status === 'active').length || 0
  const pendingCreators = creators?.filter(c => c.status === 'pending').length || 0
  const terminatedCreators = creators?.filter(c => c.status === 'terminated').length || 0

  // Get this month's settlement total
  const now = new Date()
  const periodStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0]

  const { data: settlements } = await admin
    .from('agency_settlements')
    .select('agency_net_krw')
    .eq('agency_id', agencyId)
    .gte('period_start', periodStart)

  const thisMonthSettlement = settlements?.reduce((sum, s) => sum + (s.agency_net_krw || 0), 0) || 0

  return {
    totalCreators,
    activeCreators,
    pendingCreators,
    terminatedCreators,
    thisMonthSettlement,
  }
}

// creator.list
async function creatorList(admin: SupabaseClient, agencyId: string, payload: ValidatedCreatorList) {
  let query = admin
    .from('agency_creators')
    .select('*, creator_profile:creator_profiles(*)')
    .eq('agency_id', agencyId)
    .order('created_at', { ascending: false })

  if (payload.status) {
    query = query.eq('status', payload.status)
  }

  if (payload.limit) {
    query = query.range(payload.offset ?? 0, (payload.offset ?? 0) + payload.limit - 1)
  }

  const { data, error } = await query
  if (error) throw error
  return data
}

// creator.search — Search all creators WITHOUT active agency contract
async function creatorSearch(admin: SupabaseClient, agencyId: string, payload: ValidatedCreatorSearch) {
  let query = admin
    .from('creator_profiles')
    .select('id, stage_name, avatar_url, display_name')
    .is('agency_id', null)

  if (payload.query) {
    query = query.or(`stage_name.ilike.%${payload.query}%,display_name.ilike.%${payload.query}%`)
  }

  query = query.limit(payload.limit ?? 20)

  const { data, error } = await query
  if (error) throw error
  return data
}

// creator.add
async function creatorAdd(
  admin: SupabaseClient,
  agencyId: string,
  userId: string,
  payload: ValidatedCreatorAdd
) {
  // Check if creator already has an active contract
  const { data: existing } = await admin
    .from('agency_creators')
    .select('id, agency_id, status')
    .eq('creator_profile_id', payload.creator_profile_id)
    .in('status', ['pending', 'active', 'paused'])
    .single()

  if (existing) {
    throw new Error('Creator already has an active contract with another agency')
  }

  const { data, error } = await admin
    .from('agency_creators')
    .insert({
      agency_id: agencyId,
      ...payload,
      status: 'pending',
    })
    .select()
    .single()

  if (error) throw error

  await auditLog(admin, agencyId, 'creator.add', 'agency_creators', data.id, null, data)
  return data
}

// creator.update
async function creatorUpdate(
  admin: SupabaseClient,
  agencyId: string,
  userId: string,
  payload: ValidatedCreatorUpdate
) {
  const { id, ...updates } = payload

  // Fetch current for diff
  const { data: before } = await admin
    .from('agency_creators')
    .select('*')
    .eq('id', id)
    .eq('agency_id', agencyId)
    .single()

  if (!before) throw new Error('Creator contract not found')

  // Only allow updates if status is pending, active, or paused
  if (!['pending', 'active', 'paused'].includes(before.status)) {
    throw new Error('Cannot update terminated contract')
  }

  // Remove undefined values
  const cleanUpdates: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(updates)) {
    if (value !== undefined) cleanUpdates[key] = value
  }

  const { data, error } = await admin
    .from('agency_creators')
    .update(cleanUpdates)
    .eq('id', id)
    .eq('agency_id', agencyId)
    .select()
    .single()

  if (error) throw error

  await auditLog(admin, agencyId, 'creator.update', 'agency_creators', id, before, data)
  return data
}

// creator.remove
async function creatorRemove(
  admin: SupabaseClient,
  agencyId: string,
  userId: string,
  payload: ValidatedCreatorRemove
) {
  const { data: before } = await admin
    .from('agency_creators')
    .select('*')
    .eq('id', payload.id)
    .eq('agency_id', agencyId)
    .single()

  if (!before) throw new Error('Creator contract not found')

  const { data, error } = await admin
    .from('agency_creators')
    .update({ status: 'terminated' })
    .eq('id', payload.id)
    .eq('agency_id', agencyId)
    .select()
    .single()

  if (error) throw error

  await auditLog(admin, agencyId, 'creator.remove', 'agency_creators', payload.id, before, data)
  return { terminated: true }
}

// stats.overview
async function statsOverview(admin: SupabaseClient, agencyId: string, payload: ValidatedStatsOverview) {
  // Aggregate stats for the agency
  // This is a simplified version - in production you'd query wallet_ledger, subscriptions, etc.
  const { data: settlements } = await admin
    .from('agency_settlements')
    .select('total_gross_krw, agency_commission_krw')
    .eq('agency_id', agencyId)

  const totalRevenue = settlements?.reduce((sum, s) => sum + (s.total_gross_krw || 0), 0) || 0
  const totalCommission = settlements?.reduce((sum, s) => sum + (s.agency_commission_krw || 0), 0) || 0

  return {
    totalRevenue,
    totalCommission,
    settlementCount: settlements?.length || 0,
  }
}

// stats.creator
async function statsCreator(admin: SupabaseClient, agencyId: string, payload: ValidatedStatsCreator) {
  // Get creator stats
  // In production, this would query wallet_ledger, subscriptions table
  const { data: contract } = await admin
    .from('agency_creators')
    .select('*, creator_profile:creator_profiles(stage_name)')
    .eq('agency_id', agencyId)
    .eq('creator_profile_id', payload.creator_profile_id)
    .single()

  if (!contract) throw new Error('Creator not found in agency')

  return {
    contract,
    // Add more stats here as needed
  }
}

// settlement.list
async function settlementList(admin: SupabaseClient, agencyId: string, payload: ValidatedSettlementList) {
  let query = admin
    .from('agency_settlements')
    .select('*', { count: 'exact' })
    .eq('agency_id', agencyId)
    .order('period_start', { ascending: false })

  if (payload.status) {
    query = query.eq('status', payload.status)
  }

  if (payload.limit) {
    query = query.range(payload.offset ?? 0, (payload.offset ?? 0) + payload.limit - 1)
  }

  const { data, error, count } = await query
  if (error) throw error
  return { items: data, total: count }
}

// settlement.get
async function settlementGet(admin: SupabaseClient, agencyId: string, payload: ValidatedSettlementGet) {
  const { data, error } = await admin
    .from('agency_settlements')
    .select('*')
    .eq('id', payload.id)
    .eq('agency_id', agencyId)
    .single()

  if (error) throw error
  return data
}

// tax.certificates
async function taxCertificates(admin: SupabaseClient, agencyId: string) {
  const { data, error } = await admin
    .from('agency_tax_certificates')
    .select('*')
    .eq('agency_id', agencyId)
    .order('year', { ascending: false })
    .order('month', { ascending: false })

  if (error) throw error
  return data
}

// tax.upload
async function taxUpload(
  admin: SupabaseClient,
  agencyId: string,
  userId: string,
  payload: ValidatedTaxUpload
) {
  const { data, error } = await admin
    .from('agency_tax_certificates')
    .upsert(
      {
        agency_id: agencyId,
        year: payload.year,
        month: payload.month,
        document_type: payload.document_type,
        document_url: payload.document_url,
        status: 'submitted',
        submitted_at: new Date().toISOString(),
      },
      { onConflict: 'agency_id,year,month,document_type' }
    )
    .select()
    .single()

  if (error) throw error

  await auditLog(admin, agencyId, 'tax.upload', 'agency_tax_certificates', data.id, null, data)
  return data
}

// staff.list
async function staffList(admin: SupabaseClient, agencyId: string) {
  const { data, error } = await admin
    .from('agency_staff')
    .select('*, user:auth.users(email)')
    .eq('agency_id', agencyId)
    .order('created_at', { ascending: false })

  if (error) throw error
  return data
}

// staff.invite
async function staffInvite(
  admin: SupabaseClient,
  agencyId: string,
  userId: string,
  payload: ValidatedStaffInvite
) {
  // Look up user by email
  const { data: users } = await admin.auth.admin.listUsers()
  const targetUser = users.users.find(u => u.email === payload.email)

  if (!targetUser) {
    throw new Error('User not found. They must create an account first.')
  }

  // Check if already staff
  const { data: existing } = await admin
    .from('agency_staff')
    .select('id')
    .eq('agency_id', agencyId)
    .eq('user_id', targetUser.id)
    .single()

  if (existing) {
    throw new Error('User is already a staff member')
  }

  const { data, error } = await admin
    .from('agency_staff')
    .insert({
      agency_id: agencyId,
      user_id: targetUser.id,
      role: payload.role,
      email: payload.email,
      invited_by: userId,
      invited_at: new Date().toISOString(),
      accepted_at: null, // Pending invitation
    })
    .select()
    .single()

  if (error) throw error

  await auditLog(admin, agencyId, 'staff.invite', 'agency_staff', data.id, null, data)
  return data
}

// staff.update
async function staffUpdate(
  admin: SupabaseClient,
  agencyId: string,
  userId: string,
  payload: ValidatedStaffUpdate
) {
  // Can't demote self
  if (payload.user_id === userId) {
    throw new Error('Cannot change your own role')
  }

  const { data: before } = await admin
    .from('agency_staff')
    .select('*')
    .eq('agency_id', agencyId)
    .eq('user_id', payload.user_id)
    .single()

  if (!before) throw new Error('Staff member not found')

  const { data, error } = await admin
    .from('agency_staff')
    .update({ role: payload.role })
    .eq('agency_id', agencyId)
    .eq('user_id', payload.user_id)
    .select()
    .single()

  if (error) throw error

  await auditLog(admin, agencyId, 'staff.update', 'agency_staff', data.id, before, data)
  return data
}

// staff.remove
async function staffRemove(
  admin: SupabaseClient,
  agencyId: string,
  userId: string,
  payload: ValidatedStaffRemove
) {
  // Can't remove self
  if (payload.user_id === userId) {
    throw new Error('Cannot remove yourself')
  }

  const { data: before } = await admin
    .from('agency_staff')
    .select('*')
    .eq('agency_id', agencyId)
    .eq('user_id', payload.user_id)
    .single()

  if (!before) throw new Error('Staff member not found')

  const { error } = await admin
    .from('agency_staff')
    .delete()
    .eq('agency_id', agencyId)
    .eq('user_id', payload.user_id)

  if (error) throw error

  await auditLog(admin, agencyId, 'staff.remove', 'agency_staff', before.id, before, null)
  return { removed: true }
}

// agency.profile
async function agencyProfile(admin: SupabaseClient, agencyId: string) {
  const { data, error } = await admin
    .from('agencies')
    .select('*')
    .eq('id', agencyId)
    .single()

  if (error) throw error
  return data
}

// agency.update
async function agencyUpdate(
  admin: SupabaseClient,
  agencyId: string,
  userId: string,
  payload: ValidatedAgencyUpdate
) {
  const { data: before } = await admin
    .from('agencies')
    .select('*')
    .eq('id', agencyId)
    .single()

  if (!before) throw new Error('Agency not found')

  // Remove undefined values
  const cleanUpdates: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(payload)) {
    if (value !== undefined) cleanUpdates[key] = value
  }

  const { data, error } = await admin
    .from('agencies')
    .update(cleanUpdates)
    .eq('id', agencyId)
    .select()
    .single()

  if (error) throw error

  await auditLog(admin, agencyId, 'agency.update', 'agencies', agencyId, before, data)
  return data
}

// notice.list
async function noticeList(admin: SupabaseClient, agencyId: string) {
  const { data, error } = await admin
    .from('agency_notices')
    .select('*')
    .or(`agency_id.is.null,agency_id.eq.${agencyId}`)
    .not('published_at', 'is', null)
    .order('is_pinned', { ascending: false })
    .order('published_at', { ascending: false })

  if (error) throw error
  return data
}

// audit.list
async function auditList(admin: SupabaseClient, agencyId: string, payload: ValidatedAuditList) {
  let query = admin
    .from('agency_audit_log')
    .select('*', { count: 'exact' })
    .eq('agency_id', agencyId)
    .order('created_at', { ascending: false })

  if (payload.entity_type) {
    query = query.eq('entity_type', payload.entity_type)
  }
  if (payload.entity_id) {
    query = query.eq('entity_id', payload.entity_id)
  }

  if (payload.limit) {
    query = query.range(payload.offset ?? 0, (payload.offset ?? 0) + payload.limit - 1)
  }

  const { data, error, count } = await query
  if (error) throw error
  return { items: data, total: count }
}

// ══════════════════════════════════════════════════
// Action → Min Role Mapping
// ══════════════════════════════════════════════════
const ACTION_MIN_ROLES: Record<string, string> = {
  // Dashboard
  'dashboard.summary': 'viewer',

  // Creator management
  'creator.list': 'viewer',
  'creator.search': 'manager',
  'creator.add': 'manager',
  'creator.update': 'manager',
  'creator.remove': 'manager',

  // Statistics
  'stats.overview': 'viewer',
  'stats.creator': 'viewer',

  // Settlements
  'settlement.list': 'finance',
  'settlement.get': 'finance',

  // Tax
  'tax.certificates': 'finance',
  'tax.upload': 'finance',

  // Staff
  'staff.list': 'admin',
  'staff.invite': 'admin',
  'staff.update': 'admin',
  'staff.remove': 'admin',

  // Agency profile
  'agency.profile': 'viewer',
  'agency.update': 'admin',

  // Notices
  'notice.list': 'viewer',

  // Audit
  'audit.list': 'admin',
}

// ══════════════════════════════════════════════════
// Main Handler
// ══════════════════════════════════════════════════
serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: getCorsHeaders(req) })
  }

  if (req.method !== 'POST') {
    return err(405, 'Method not allowed', req)
  }

  const requestId = crypto.randomUUID()
  const startTime = Date.now()

  try {
    // 1. Auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return err(401, 'Missing authorization header', req)
    }

    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await admin.auth.getUser(token)

    if (authError || !user) {
      log({ level: 'warn', fn: 'agency-manage', action: 'auth_failed', details: { requestId } })
      return err(401, 'Invalid or expired token', req)
    }

    // 2. Parse request
    const { action, payload = {} } = await req.json() as {
      action: string
      payload: Record<string, unknown>
    }

    if (!action) {
      return err(400, 'Missing action', req)
    }

    // 3. Get staff info (agency_id + role)
    const staffInfo = await getStaffInfo(admin, user.id)
    if (!staffInfo) {
      log({
        level: 'warn', fn: 'agency-manage', action: 'not_staff',
        userId: user.id,
        details: { requestId },
      })
      return err(403, 'Not an agency staff member', req)
    }

    const { agencyId, role: userRole } = staffInfo
    const minRole = ACTION_MIN_ROLES[action]

    if (!minRole) {
      return err(400, `Unknown action: ${action}`, req)
    }

    if (!hasMinRole(userRole, minRole)) {
      log({
        level: 'warn', fn: 'agency-manage', action: 'access_denied',
        userId: user.id,
        details: { requestId, requiredRole: minRole, actualRole: userRole },
      })
      return err(403, `Insufficient permissions. Required: ${minRole}`, req)
    }

    // 4. Rate limiting
    const rl = await checkRateLimit(admin, {
      key: `agency:${user.id}`,
      limit: 120,        // 120 requests per minute
      windowSeconds: 60,
    })
    if (!rl.allowed) {
      log({ level: 'warn', fn: 'agency-manage', action: 'rate_limited', userId: user.id, details: { requestId } })
      return err(429, 'Too many requests', req, rateLimitHeaders(rl))
    }

    // 5. Log request start
    log({
      level: 'info', fn: 'agency-manage', action,
      userId: user.id,
      details: { requestId, agencyId: maskUserId(agencyId) },
    })

    // 6. Validate + Dispatch
    let result: unknown

    switch (action) {
      // Dashboard
      case 'dashboard.summary':
        result = await dashboardSummary(admin, agencyId)
        break

      // Creator management
      case 'creator.list': {
        const v = validateCreatorList(payload)
        result = await creatorList(admin, agencyId, v)
        break
      }
      case 'creator.search': {
        const v = validateCreatorSearch(payload)
        result = await creatorSearch(admin, agencyId, v)
        break
      }
      case 'creator.add': {
        const v = validateCreatorAdd(payload)
        result = await creatorAdd(admin, agencyId, user.id, v)
        break
      }
      case 'creator.update': {
        const v = validateCreatorUpdate(payload)
        result = await creatorUpdate(admin, agencyId, user.id, v)
        break
      }
      case 'creator.remove': {
        const v = validateCreatorRemove(payload)
        result = await creatorRemove(admin, agencyId, user.id, v)
        break
      }

      // Statistics
      case 'stats.overview': {
        const v = validateStatsOverview(payload)
        result = await statsOverview(admin, agencyId, v)
        break
      }
      case 'stats.creator': {
        const v = validateStatsCreator(payload)
        result = await statsCreator(admin, agencyId, v)
        break
      }

      // Settlements
      case 'settlement.list': {
        const v = validateSettlementList(payload)
        result = await settlementList(admin, agencyId, v)
        break
      }
      case 'settlement.get': {
        const v = validateSettlementGet(payload)
        result = await settlementGet(admin, agencyId, v)
        break
      }

      // Tax
      case 'tax.certificates':
        result = await taxCertificates(admin, agencyId)
        break
      case 'tax.upload': {
        const v = validateTaxUpload(payload)
        result = await taxUpload(admin, agencyId, user.id, v)
        break
      }

      // Staff
      case 'staff.list':
        result = await staffList(admin, agencyId)
        break
      case 'staff.invite': {
        const v = validateStaffInvite(payload)
        result = await staffInvite(admin, agencyId, user.id, v)
        break
      }
      case 'staff.update': {
        const v = validateStaffUpdate(payload)
        result = await staffUpdate(admin, agencyId, user.id, v)
        break
      }
      case 'staff.remove': {
        const v = validateStaffRemove(payload)
        result = await staffRemove(admin, agencyId, user.id, v)
        break
      }

      // Agency profile
      case 'agency.profile':
        result = await agencyProfile(admin, agencyId)
        break
      case 'agency.update': {
        const v = validateAgencyUpdate(payload)
        result = await agencyUpdate(admin, agencyId, user.id, v)
        break
      }

      // Notices
      case 'notice.list':
        result = await noticeList(admin, agencyId)
        break

      // Audit
      case 'audit.list': {
        const v = validateAuditList(payload)
        result = await auditList(admin, agencyId, v)
        break
      }

      default:
        return err(400, `Unknown action: ${action}`, req)
    }

    // 7. Log success
    const durationMs = Date.now() - startTime
    log({
      level: 'info', fn: 'agency-manage', action: action + '.ok',
      userId: user.id,
      details: { requestId, durationMs },
    })

    return ok(result, req, rateLimitHeaders(rl))
  } catch (e) {
    const error = e as Error & { statusCode?: number }
    const status = error.statusCode || (error instanceof ValidationError ? 400 : 500)
    const durationMs = Date.now() - startTime

    log({
      level: 'error', fn: 'agency-manage', action: 'error',
      error: error.message,
      details: { requestId, status, durationMs },
    })

    return err(status, error.message, req)
  }
})
