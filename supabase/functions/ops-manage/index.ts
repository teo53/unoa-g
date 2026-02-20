/**
 * ops-manage — Multiplexer Edge Function for Ops CRM
 *
 * Single endpoint handling all ops CRUD + publish/rollback.
 * POST /ops-manage { action: string, payload: object }
 *
 * Actions:
 *   staff.list / staff.upsert / staff.remove
 *   asset.list / asset.upload_complete / asset.delete
 *   banner.list / banner.get / banner.create / banner.update
 *   banner.submit_review / banner.publish / banner.rollback / banner.archive
 *   fan_ad.list / fan_ad.approve / fan_ad.reject
 *   flag.list / flag.get / flag.create / flag.update
 *   flag.publish / flag.rollback
 *   audit.list
 *   config.refresh
 *
 * Security:
 *   - Auth via Bearer token (getUser)
 *   - RBAC via ops_staff table
 *   - Input validation on every action (no `as any`)
 *   - Rate limiting via DB-based counter
 *   - Structured logging with PII masking
 *   - Atomic publish/rollback/archive via PL/pgSQL RPCs
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders } from '../_shared/cors.ts'
import { checkRateLimit, rateLimitHeaders } from '../_shared/rate_limit.ts'
import { log, maskUserId } from '../_shared/logger.ts'
import { emitMwEvent } from '../_shared/mw_metrics.ts'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

const jsonHeaders = { 'Content-Type': 'application/json' }

// ══════════════════════════════════════════════════
// Input Validation Utilities (pure TS, no external deps)
// ══════════════════════════════════════════════════

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
const FLAG_KEY_RE = /^[a-z][a-z0-9_]{1,63}$/
const SAFE_URL_PROTOCOLS = ['http:', 'https:', '']

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

function optionalISO(v: unknown, field: string): string | null {
  if (v === undefined || v === null || v === '') return null
  if (typeof v !== 'string') {
    throw new ValidationError(`${field}: must be an ISO date string`)
  }
  // Basic ISO format check
  if (isNaN(Date.parse(v))) {
    throw new ValidationError(`${field}: invalid date format`)
  }
  return v
}

function requireSafeUrl(v: unknown, field: string): string {
  if (typeof v !== 'string') {
    throw new ValidationError(`${field}: must be a string URL`)
  }
  // Block dangerous protocols
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

function requireFlagKey(v: unknown, field: string): string {
  if (typeof v !== 'string' || !FLAG_KEY_RE.test(v)) {
    throw new ValidationError(`${field}: must match /^[a-z][a-z0-9_]{1,63}$/`)
  }
  return v
}

function optionalBoolean(v: unknown, field: string): boolean | undefined {
  if (v === undefined || v === null) return undefined
  if (typeof v !== 'boolean') {
    throw new ValidationError(`${field}: must be a boolean`)
  }
  return v
}

function optionalJSON(v: unknown, field: string): Record<string, unknown> | undefined {
  if (v === undefined || v === null) return undefined
  if (typeof v !== 'object' || Array.isArray(v)) {
    throw new ValidationError(`${field}: must be a JSON object`)
  }
  return v as Record<string, unknown>
}

function optionalStringArray(v: unknown, field: string): string[] | undefined {
  if (v === undefined || v === null) return undefined
  if (!Array.isArray(v) || !v.every((item) => typeof item === 'string')) {
    throw new ValidationError(`${field}: must be an array of strings`)
  }
  return v
}

// ══════════════════════════════════════════════════
// Per-Action Validation Schemas
// ══════════════════════════════════════════════════

const BANNER_PLACEMENTS = [
  'home_top',
  'home_bottom',
  'discover_top',
  'chat_top',
  'chat_list',
  'profile_banner',
  'funding_top',
  'popup',
] as const
const BANNER_LINK_TYPES = ['internal', 'external', 'none'] as const
const BANNER_STATUSES = ['draft', 'in_review', 'published', 'archived'] as const
const FAN_AD_STATUSES = ['pending_review', 'approved', 'active', 'completed', 'rejected', 'cancelled'] as const
const TARGET_AUDIENCES = ['all', 'fans', 'creators', 'vip'] as const
const FLAG_STATUSES = ['draft', 'published', 'archived'] as const
const STAFF_ROLES = ['viewer', 'operator', 'publisher', 'admin'] as const
const AUDIT_ENTITY_TYPES = ['ops_banners', 'ops_feature_flags', 'ops_assets', 'ops_staff', 'fan_ads'] as const
const ASSET_MIME_TYPES_PREFIX = 'image/'

// -- Staff --
interface ValidatedStaffUpsert { target_user_id: string; role: string; display_name?: string }
function validateStaffUpsert(p: Record<string, unknown>): ValidatedStaffUpsert {
  return {
    target_user_id: requireUUID(p.target_user_id, 'target_user_id'),
    role: requireEnum(p.role, [...STAFF_ROLES], 'role'),
    display_name: optionalString(p.display_name, 'display_name', 200),
  }
}

interface ValidatedStaffRemove { target_user_id: string }
function validateStaffRemove(p: Record<string, unknown>): ValidatedStaffRemove {
  return { target_user_id: requireUUID(p.target_user_id, 'target_user_id') }
}

// -- Asset --
interface ValidatedAssetList { tag?: string; limit?: number; offset?: number }
function validateAssetList(p: Record<string, unknown>): ValidatedAssetList {
  return {
    tag: optionalString(p.tag, 'tag', 100),
    limit: optionalInt(p.limit, 'limit', 1, 100),
    offset: optionalInt(p.offset, 'offset', 0, 100000),
  }
}

interface ValidatedAssetUpload {
  file_name: string; storage_path: string; public_url: string
  mime_type: string; file_size: number; width?: number; height?: number
  tags?: string[]; alt_text?: string
}
function validateAssetUpload(p: Record<string, unknown>): ValidatedAssetUpload {
  const mimeType = requireString(p.mime_type, 'mime_type', 1, 100)
  if (!mimeType.startsWith(ASSET_MIME_TYPES_PREFIX)) {
    throw new ValidationError('mime_type: must start with image/')
  }
  return {
    file_name: requireString(p.file_name, 'file_name', 1, 500),
    storage_path: requireString(p.storage_path, 'storage_path', 1, 1000),
    public_url: requireSafeUrl(p.public_url, 'public_url'),
    mime_type: mimeType,
    file_size: requireInt(p.file_size, 'file_size', 1, 50 * 1024 * 1024), // 50MB max
    width: optionalInt(p.width, 'width', 1, 20000),
    height: optionalInt(p.height, 'height', 1, 20000),
    tags: optionalStringArray(p.tags, 'tags'),
    alt_text: optionalString(p.alt_text, 'alt_text', 500),
  }
}

interface ValidatedAssetDelete { id: string }
function validateAssetDelete(p: Record<string, unknown>): ValidatedAssetDelete {
  return { id: requireUUID(p.id, 'id') }
}

// -- Banner --
interface ValidatedBannerList { status?: string; placement?: string }
function validateBannerList(p: Record<string, unknown>): ValidatedBannerList {
  return {
    status: p.status ? requireEnum(p.status, [...BANNER_STATUSES], 'status') : undefined,
    placement: p.placement ? requireEnum(p.placement, [...BANNER_PLACEMENTS], 'placement') : undefined,
  }
}

interface ValidatedBannerGet { id: string }
function validateBannerGet(p: Record<string, unknown>): ValidatedBannerGet {
  return { id: requireUUID(p.id, 'id') }
}

interface ValidatedBannerCreate {
  title: string; placement?: string; image_url?: string
  link_url?: string; link_type?: string; priority?: number
  start_at?: string | null; end_at?: string | null; target_audience?: string
}
function validateBannerCreate(p: Record<string, unknown>): ValidatedBannerCreate {
  return {
    title: requireString(p.title, 'title', 1, 200),
    placement: p.placement ? requireEnum(p.placement, [...BANNER_PLACEMENTS], 'placement') : undefined,
    image_url: optionalSafeUrl(p.image_url, 'image_url'),
    link_url: optionalSafeUrl(p.link_url, 'link_url'),
    link_type: p.link_type ? requireEnum(p.link_type, [...BANNER_LINK_TYPES], 'link_type') : undefined,
    priority: optionalInt(p.priority, 'priority', 0, 9999),
    start_at: optionalISO(p.start_at, 'start_at'),
    end_at: optionalISO(p.end_at, 'end_at'),
    target_audience: p.target_audience ? requireEnum(p.target_audience, [...TARGET_AUDIENCES], 'target_audience') : undefined,
  }
}

interface ValidatedBannerUpdate {
  id: string; expected_version: number
  title?: string; placement?: string; image_url?: string
  link_url?: string; link_type?: string; priority?: number
  start_at?: string | null; end_at?: string | null; target_audience?: string
}
function validateBannerUpdate(p: Record<string, unknown>): ValidatedBannerUpdate {
  return {
    id: requireUUID(p.id, 'id'),
    expected_version: requireInt(p.expected_version, 'expected_version', 1, 999999),
    title: optionalString(p.title, 'title', 200),
    placement: p.placement ? requireEnum(p.placement, [...BANNER_PLACEMENTS], 'placement') : undefined,
    image_url: optionalSafeUrl(p.image_url, 'image_url'),
    link_url: optionalSafeUrl(p.link_url, 'link_url'),
    link_type: p.link_type ? requireEnum(p.link_type, [...BANNER_LINK_TYPES], 'link_type') : undefined,
    priority: optionalInt(p.priority, 'priority', 0, 9999),
    start_at: optionalISO(p.start_at, 'start_at'),
    end_at: optionalISO(p.end_at, 'end_at'),
    target_audience: p.target_audience ? requireEnum(p.target_audience, [...TARGET_AUDIENCES], 'target_audience') : undefined,
  }
}

interface ValidatedBannerVersioned { id: string; expected_version: number }
function validateBannerVersioned(p: Record<string, unknown>): ValidatedBannerVersioned {
  return {
    id: requireUUID(p.id, 'id'),
    expected_version: requireInt(p.expected_version, 'expected_version', 1, 999999),
  }
}

interface ValidatedBannerIdOnly { id: string }
function validateBannerIdOnly(p: Record<string, unknown>): ValidatedBannerIdOnly {
  return { id: requireUUID(p.id, 'id') }
}

// -- Flag --
interface ValidatedFlagList { status?: string; limit?: number; offset?: number }
function validateFlagList(p: Record<string, unknown>): ValidatedFlagList {
  return {
    status: p.status ? requireEnum(p.status, [...FLAG_STATUSES], 'status') : undefined,
    limit: optionalInt(p.limit, 'limit', 1, 100),
    offset: optionalInt(p.offset, 'offset', 0, 100000),
  }
}

interface ValidatedFlagGet { id: string }
function validateFlagGet(p: Record<string, unknown>): ValidatedFlagGet {
  return { id: requireUUID(p.id, 'id') }
}

interface ValidatedFlagCreate {
  flag_key: string; title: string; description?: string
  enabled?: boolean; rollout_percent?: number; payload_data?: Record<string, unknown>
}
function validateFlagCreate(p: Record<string, unknown>): ValidatedFlagCreate {
  return {
    flag_key: requireFlagKey(p.flag_key, 'flag_key'),
    title: requireString(p.title, 'title', 1, 200),
    description: optionalString(p.description, 'description', 500),
    enabled: optionalBoolean(p.enabled, 'enabled'),
    rollout_percent: optionalInt(p.rollout_percent, 'rollout_percent', 0, 100),
    payload_data: optionalJSON(p.payload_data, 'payload_data'),
  }
}

interface ValidatedFlagUpdate {
  id: string; expected_version: number
  title?: string; description?: string; flag_key?: string
  enabled?: boolean; rollout_percent?: number; payload_data?: Record<string, unknown>
}
function validateFlagUpdate(p: Record<string, unknown>): ValidatedFlagUpdate {
  return {
    id: requireUUID(p.id, 'id'),
    expected_version: requireInt(p.expected_version, 'expected_version', 1, 999999),
    title: optionalString(p.title, 'title', 200),
    description: optionalString(p.description, 'description', 500),
    flag_key: p.flag_key ? requireFlagKey(p.flag_key, 'flag_key') : undefined,
    enabled: optionalBoolean(p.enabled, 'enabled'),
    rollout_percent: optionalInt(p.rollout_percent, 'rollout_percent', 0, 100),
    payload_data: optionalJSON(p.payload_data, 'payload_data'),
  }
}

interface ValidatedFlagVersioned { id: string; expected_version: number }
function validateFlagVersioned(p: Record<string, unknown>): ValidatedFlagVersioned {
  return {
    id: requireUUID(p.id, 'id'),
    expected_version: requireInt(p.expected_version, 'expected_version', 1, 999999),
  }
}

interface ValidatedFlagIdOnly { id: string }
function validateFlagIdOnly(p: Record<string, unknown>): ValidatedFlagIdOnly {
  return { id: requireUUID(p.id, 'id') }
}

// -- Audit --
interface ValidatedAuditList { entity_type?: string; entity_id?: string; limit?: number; offset?: number }
function validateAuditList(p: Record<string, unknown>): ValidatedAuditList {
  return {
    entity_type: p.entity_type ? requireEnum(p.entity_type, [...AUDIT_ENTITY_TYPES], 'entity_type') : undefined,
    entity_id: p.entity_id ? requireUUID(p.entity_id, 'entity_id') : undefined,
    limit: optionalInt(p.limit, 'limit', 1, 100),
    offset: optionalInt(p.offset, 'offset', 0, 100000),
  }
}

// -- Fan Ads --
interface ValidatedFanAdList { status?: string; limit?: number; offset?: number }
function validateFanAdList(p: Record<string, unknown>): ValidatedFanAdList {
  return {
    status: p.status ? requireEnum(p.status, [...FAN_AD_STATUSES], 'status') : undefined,
    limit: optionalInt(p.limit, 'limit', 1, 100),
    offset: optionalInt(p.offset, 'offset', 0, 100000),
  }
}

interface ValidatedFanAdApprove {
  id: string
  placement: string
  priority?: number
}
function validateFanAdApprove(p: Record<string, unknown>): ValidatedFanAdApprove {
  return {
    id: requireUUID(p.id, 'id'),
    placement: requireEnum(p.placement, [...BANNER_PLACEMENTS], 'placement'),
    priority: optionalInt(p.priority, 'priority', 0, 9999),
  }
}

interface ValidatedFanAdReject {
  id: string
  rejection_reason: string
}
function validateFanAdReject(p: Record<string, unknown>): ValidatedFanAdReject {
  return {
    id: requireUUID(p.id, 'id'),
    rejection_reason: requireString(p.rejection_reason, 'rejection_reason', 1, 500).trim(),
  }
}

// ══════════════════════════════════════════════════
// Role hierarchy
// ══════════════════════════════════════════════════

const ROLE_LEVELS: Record<string, number> = {
  viewer: 1,
  operator: 2,
  publisher: 3,
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

async function getStaffRole(
  admin: SupabaseClient,
  userId: string
): Promise<string | null> {
  const { data } = await admin
    .from('ops_staff')
    .select('role')
    .eq('user_id', userId)
    .single()
  return data?.role ?? null
}

function hasMinRole(userRole: string | null, minRole: string): boolean {
  if (!userRole) return false
  return (ROLE_LEVELS[userRole] ?? 0) >= (ROLE_LEVELS[minRole] ?? 99)
}

async function audit(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  action: string,
  entityType: string,
  entityId: string | null,
  before: unknown | null,
  after: unknown | null,
  metadata: unknown = {}
) {
  // Calculate diff if both before and after exist
  let diffBefore = before as Record<string, unknown> | null
  let diffAfter = after as Record<string, unknown> | null

  if (before && after && typeof before === 'object' && typeof after === 'object') {
    const b = before as Record<string, unknown>
    const a = after as Record<string, unknown>
    const changedKeys = new Set<string>()

    for (const key of Object.keys(a)) {
      if (JSON.stringify(b[key]) !== JSON.stringify(a[key])) {
        changedKeys.add(key)
      }
    }
    for (const key of Object.keys(b)) {
      if (!(key in a)) changedKeys.add(key)
    }

    if (changedKeys.size > 0) {
      diffBefore = {} as Record<string, unknown>
      diffAfter = {} as Record<string, unknown>
      for (const key of changedKeys) {
        if (key in b) diffBefore[key] = b[key]
        if (key in a) diffAfter[key] = a[key]
      }
    } else {
      diffBefore = null
      diffAfter = null
    }
  }

  await admin.from('ops_audit_log').insert({
    actor_id: userId,
    actor_role: userRole,
    action,
    entity_type: entityType,
    entity_id: entityId,
    before: diffBefore,
    after: diffAfter,
    metadata,
  })
}

// ══════════════════════════════════════════════════
// Action Handlers
// ══════════════════════════════════════════════════

// staff.list
async function staffList(admin: SupabaseClient) {
  const { data, error } = await admin
    .from('ops_staff')
    .select('*, user:user_id(email, raw_user_meta_data)')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data
}

// staff.upsert
async function staffUpsert(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedStaffUpsert
) {
  const { data: existing } = await admin
    .from('ops_staff')
    .select('*')
    .eq('user_id', payload.target_user_id)
    .single()

  const { data, error } = await admin
    .from('ops_staff')
    .upsert(
      {
        user_id: payload.target_user_id,
        role: payload.role,
        display_name: payload.display_name || existing?.display_name || '',
      },
      { onConflict: 'user_id' }
    )
    .select()
    .single()
  if (error) throw error

  await audit(
    admin, userId, userRole,
    existing ? 'staff.update' : 'staff.create',
    'ops_staff', data.id,
    existing, data
  )
  return data
}

// staff.remove
async function staffRemove(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedStaffRemove
) {
  const { data: existing } = await admin
    .from('ops_staff')
    .select('*')
    .eq('user_id', payload.target_user_id)
    .single()

  if (!existing) throw new Error('Staff member not found')

  const { error } = await admin
    .from('ops_staff')
    .delete()
    .eq('user_id', payload.target_user_id)
  if (error) throw error

  await audit(admin, userId, userRole, 'staff.remove', 'ops_staff', existing.id, existing, null)
  return { removed: true }
}

// asset.list
async function assetList(admin: SupabaseClient, payload: ValidatedAssetList) {
  let query = admin
    .from('ops_assets')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })

  if (payload.tag) {
    query = query.contains('tags', [payload.tag])
  }
  query = query.range(payload.offset ?? 0, (payload.offset ?? 0) + (payload.limit ?? 20) - 1)

  const { data, error, count } = await query
  if (error) throw error
  return { items: data, total: count }
}

// asset.upload_complete
async function assetUploadComplete(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedAssetUpload
) {
  const { data, error } = await admin
    .from('ops_assets')
    .insert({
      ...payload,
      uploaded_by: userId,
    })
    .select()
    .single()
  if (error) throw error

  await audit(admin, userId, userRole, 'asset.upload', 'ops_assets', data.id, null, data)
  return data
}

// asset.delete
async function assetDelete(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedAssetDelete
) {
  const { data: existing } = await admin
    .from('ops_assets')
    .select('*')
    .eq('id', payload.id)
    .single()

  if (!existing) throw new Error('Asset not found')

  // Delete from storage
  if (existing.storage_path) {
    await admin.storage.from('ops-assets').remove([existing.storage_path])
  }

  const { error } = await admin
    .from('ops_assets')
    .delete()
    .eq('id', payload.id)
  if (error) throw error

  await audit(admin, userId, userRole, 'asset.delete', 'ops_assets', payload.id, existing, null)
  return { deleted: true }
}

// banner.list
async function bannerList(admin: SupabaseClient, payload: ValidatedBannerList) {
  let query = admin
    .from('ops_banners')
    .select('*')
    .order('updated_at', { ascending: false })

  if (payload.status) query = query.eq('status', payload.status)
  if (payload.placement) query = query.eq('placement', payload.placement)

  const { data, error } = await query
  if (error) throw error
  return data
}

// banner.get
async function bannerGet(admin: SupabaseClient, payload: ValidatedBannerGet) {
  const { data, error } = await admin
    .from('ops_banners')
    .select('*')
    .eq('id', payload.id)
    .single()
  if (error) throw error
  return data
}

// banner.create
async function bannerCreate(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedBannerCreate
) {
  const { data, error } = await admin
    .from('ops_banners')
    .insert({
      ...payload,
      status: 'draft',
      version: 1,
      created_by: userId,
      updated_by: userId,
    })
    .select()
    .single()
  if (error) throw error

  await audit(admin, userId, userRole, 'banner.create', 'ops_banners', data.id, null, data)
  return data
}

// banner.update (with optimistic locking)
async function bannerUpdate(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedBannerUpdate
) {
  const { id, expected_version, ...updates } = payload

  // Fetch current for diff + version check
  const { data: before } = await admin
    .from('ops_banners')
    .select('*')
    .eq('id', id)
    .single()

  if (!before) throw new Error('Banner not found')
  if (before.version !== expected_version) {
    throw Object.assign(
      new Error('Version conflict: another user modified this banner. Please refresh.'),
      { statusCode: 409 }
    )
  }

  // Only draft/in_review can be edited
  if (before.status === 'published' || before.status === 'archived') {
    throw new Error('Cannot edit a published or archived banner. Create a new version instead.')
  }

  // Remove undefined values from updates
  const cleanUpdates: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(updates)) {
    if (value !== undefined) cleanUpdates[key] = value
  }

  const { data, error } = await admin
    .from('ops_banners')
    .update({
      ...cleanUpdates,
      version: expected_version + 1,
      updated_by: userId,
    })
    .eq('id', id)
    .eq('version', expected_version) // Optimistic lock
    .select()
    .single()

  if (error) throw error
  if (!data) throw Object.assign(new Error('Version conflict'), { statusCode: 409 })

  await audit(admin, userId, userRole, 'banner.update', 'ops_banners', id, before, data)
  return data
}

// banner.submit_review
async function bannerSubmitReview(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedBannerVersioned
) {
  const { data: before } = await admin
    .from('ops_banners')
    .select('*')
    .eq('id', payload.id)
    .single()

  if (!before) throw new Error('Banner not found')
  if (before.status !== 'draft') throw new Error('Only draft banners can be submitted for review')

  const { data, error } = await admin
    .from('ops_banners')
    .update({
      status: 'in_review',
      version: payload.expected_version + 1,
      updated_by: userId,
    })
    .eq('id', payload.id)
    .eq('version', payload.expected_version)
    .select()
    .single()

  if (error) throw error
  if (!data) throw Object.assign(new Error('Version conflict'), { statusCode: 409 })

  await audit(admin, userId, userRole, 'banner.submit_review', 'ops_banners', payload.id, before, data)
  return data
}

// banner.publish (ATOMIC via PL/pgSQL RPC)
async function bannerPublish(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedBannerVersioned
) {
  const { data, error } = await admin.rpc('publish_banner_atomic', {
    p_banner_id: payload.id,
    p_expected_version: payload.expected_version,
    p_actor_id: userId,
    p_actor_role: userRole,
  })

  if (error) {
    if (error.message.includes('version_conflict')) {
      throw Object.assign(new Error('다른 사용자가 수정했습니다. 새로고침 해주세요.'), { statusCode: 409 })
    }
    if (error.message.includes('invalid_status')) {
      throw Object.assign(new Error('현재 상태에서는 게시할 수 없습니다.'), { statusCode: 400 })
    }
    if (error.message.includes('banner_not_found')) {
      throw Object.assign(new Error('배너를 찾을 수 없습니다.'), { statusCode: 404 })
    }
    throw error
  }
  return data
}

// banner.rollback (ATOMIC via PL/pgSQL RPC)
async function bannerRollback(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedBannerIdOnly
) {
  const { data, error } = await admin.rpc('rollback_banner_atomic', {
    p_banner_id: payload.id,
    p_actor_id: userId,
    p_actor_role: userRole,
  })

  if (error) {
    if (error.message.includes('banner_not_found')) {
      throw Object.assign(new Error('배너를 찾을 수 없습니다.'), { statusCode: 404 })
    }
    if (error.message.includes('invalid_status')) {
      throw Object.assign(new Error('게시된 배너만 롤백할 수 있습니다.'), { statusCode: 400 })
    }
    if (error.message.includes('no_snapshot')) {
      throw Object.assign(new Error('롤백할 스냅샷이 없습니다.'), { statusCode: 400 })
    }
    throw error
  }
  return data
}

// banner.archive (ATOMIC via PL/pgSQL RPC)
async function bannerArchive(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedBannerIdOnly
) {
  const { data, error } = await admin.rpc('archive_banner_atomic', {
    p_banner_id: payload.id,
    p_actor_id: userId,
    p_actor_role: userRole,
  })

  if (error) {
    if (error.message.includes('banner_not_found')) {
      throw Object.assign(new Error('배너를 찾을 수 없습니다.'), { statusCode: 404 })
    }
    if (error.message.includes('invalid_status')) {
      throw Object.assign(new Error('이미 보관된 배너입니다.'), { statusCode: 400 })
    }
    throw error
  }
  return data
}

// fan_ad.list
async function fanAdList(admin: SupabaseClient, payload: ValidatedFanAdList) {
  const limit = payload.limit ?? 50
  const offset = payload.offset ?? 0
  let query = admin
    .from('fan_ads')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })

  if (payload.status) query = query.eq('status', payload.status)

  query = query.range(offset, offset + limit - 1)

  const { data, error, count } = await query
  if (error) throw error
  return {
    items: data ?? [],
    total: count ?? 0,
    limit,
    offset,
  }
}

// fan_ad.approve (ATOMIC via PL/pgSQL RPC)
async function fanAdApprove(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedFanAdApprove
) {
  const { data, error } = await admin.rpc('approve_fan_ad_atomic', {
    p_fan_ad_id: payload.id,
    p_placement: payload.placement,
    p_priority: payload.priority ?? 0,
    p_actor_id: userId,
    p_actor_role: userRole,
  })

  if (error) {
    if (error.message.includes('fan_ad_not_found')) {
      throw Object.assign(new Error('팬 광고를 찾을 수 없습니다.'), { statusCode: 404 })
    }
    if (error.message.includes('invalid_status')) {
      throw Object.assign(new Error('현재 상태에서는 승인할 수 없습니다.'), { statusCode: 400 })
    }
    if (error.message.includes('invalid_placement')) {
      throw Object.assign(new Error('유효하지 않은 placement 값입니다.'), { statusCode: 400 })
    }
    if (error.message.includes('payment_not_paid')) {
      throw Object.assign(new Error('결제 완료된 광고만 승인할 수 있습니다.'), { statusCode: 400 })
    }
    throw error
  }
  return data
}

// fan_ad.reject (ATOMIC via PL/pgSQL RPC)
async function fanAdReject(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedFanAdReject
) {
  const { data, error } = await admin.rpc('reject_fan_ad_atomic', {
    p_fan_ad_id: payload.id,
    p_rejection_reason: payload.rejection_reason,
    p_actor_id: userId,
    p_actor_role: userRole,
  })

  if (error) {
    if (error.message.includes('fan_ad_not_found')) {
      throw Object.assign(new Error('팬 광고를 찾을 수 없습니다.'), { statusCode: 404 })
    }
    if (error.message.includes('invalid_status')) {
      throw Object.assign(new Error('현재 상태에서는 거절할 수 없습니다.'), { statusCode: 400 })
    }
    if (error.message.includes('invalid_rejection_reason')) {
      throw Object.assign(new Error('거절 사유를 확인해주세요.'), { statusCode: 400 })
    }
    throw error
  }
  return data
}

// flag.list
async function flagList(admin: SupabaseClient, payload: ValidatedFlagList) {
  let query = admin
    .from('ops_feature_flags')
    .select('*')
    .order('updated_at', { ascending: false })

  if (payload.status) query = query.eq('status', payload.status)

  const { data, error } = await query
  if (error) throw error
  return data
}

// flag.get
async function flagGet(admin: SupabaseClient, payload: ValidatedFlagGet) {
  const { data, error } = await admin
    .from('ops_feature_flags')
    .select('*')
    .eq('id', payload.id)
    .single()
  if (error) throw error
  return data
}

// flag.create
async function flagCreate(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedFlagCreate
) {
  const { payload_data, ...rest } = payload
  const { data, error } = await admin
    .from('ops_feature_flags')
    .insert({
      ...rest,
      payload: payload_data ?? {},
      status: 'draft',
      version: 1,
      created_by: userId,
      updated_by: userId,
    })
    .select()
    .single()
  if (error) throw error

  await audit(admin, userId, userRole, 'flag.create', 'ops_feature_flags', data.id, null, data)
  return data
}

// flag.update (optimistic locking)
async function flagUpdate(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedFlagUpdate
) {
  const { id, expected_version, payload_data, ...updates } = payload

  const { data: before } = await admin
    .from('ops_feature_flags')
    .select('*')
    .eq('id', id)
    .single()

  if (!before) throw new Error('Flag not found')
  if (before.version !== expected_version) {
    throw Object.assign(new Error('Version conflict'), { statusCode: 409 })
  }

  // Remove undefined values
  const cleanUpdates: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(updates)) {
    if (value !== undefined) cleanUpdates[key] = value
  }
  cleanUpdates.version = expected_version + 1
  cleanUpdates.updated_by = userId
  if (payload_data !== undefined) cleanUpdates.payload = payload_data

  const { data, error } = await admin
    .from('ops_feature_flags')
    .update(cleanUpdates)
    .eq('id', id)
    .eq('version', expected_version)
    .select()
    .single()

  if (error) throw error
  if (!data) throw Object.assign(new Error('Version conflict'), { statusCode: 409 })

  await audit(admin, userId, userRole, 'flag.update', 'ops_feature_flags', id, before, data)
  return data
}

// flag.publish (ATOMIC via PL/pgSQL RPC)
async function flagPublish(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedFlagVersioned
) {
  const { data, error } = await admin.rpc('publish_flag_atomic', {
    p_flag_id: payload.id,
    p_expected_version: payload.expected_version,
    p_actor_id: userId,
    p_actor_role: userRole,
  })

  if (error) {
    if (error.message.includes('version_conflict')) {
      throw Object.assign(new Error('다른 사용자가 수정했습니다. 새로고침 해주세요.'), { statusCode: 409 })
    }
    if (error.message.includes('invalid_status')) {
      throw Object.assign(new Error('현재 상태에서는 게시할 수 없습니다.'), { statusCode: 400 })
    }
    if (error.message.includes('flag_not_found')) {
      throw Object.assign(new Error('플래그를 찾을 수 없습니다.'), { statusCode: 404 })
    }
    throw error
  }
  return data
}

// flag.rollback (ATOMIC via PL/pgSQL RPC)
async function flagRollback(
  admin: SupabaseClient,
  userId: string,
  userRole: string,
  payload: ValidatedFlagIdOnly
) {
  const { data, error } = await admin.rpc('rollback_flag_atomic', {
    p_flag_id: payload.id,
    p_actor_id: userId,
    p_actor_role: userRole,
  })

  if (error) {
    if (error.message.includes('flag_not_found')) {
      throw Object.assign(new Error('플래그를 찾을 수 없습니다.'), { statusCode: 404 })
    }
    if (error.message.includes('invalid_status')) {
      throw Object.assign(new Error('게시된 플래그만 롤백할 수 있습니다.'), { statusCode: 400 })
    }
    if (error.message.includes('no_snapshot')) {
      throw Object.assign(new Error('롤백할 스냅샷이 없습니다.'), { statusCode: 400 })
    }
    throw error
  }
  return data
}

// audit.list
async function auditList(
  admin: SupabaseClient,
  payload: ValidatedAuditList
) {
  let query = admin
    .from('ops_audit_log')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })

  if (payload.entity_type) query = query.eq('entity_type', payload.entity_type)
  if (payload.entity_id) query = query.eq('entity_id', payload.entity_id)
  query = query.range(payload.offset ?? 0, (payload.offset ?? 0) + (payload.limit ?? 50) - 1)

  const { data, error, count } = await query
  if (error) throw error
  return { items: data, total: count }
}

// ══════════════════════════════════════════════════
// Action → Min Role Mapping
// ══════════════════════════════════════════════════
const ACTION_MIN_ROLES: Record<string, string> = {
  // Staff management
  'staff.list': 'admin',
  'staff.upsert': 'admin',
  'staff.remove': 'admin',
  // Assets
  'asset.list': 'viewer',
  'asset.upload_complete': 'operator',
  'asset.delete': 'operator',
  // Banners
  'banner.list': 'viewer',
  'banner.get': 'viewer',
  'banner.create': 'operator',
  'banner.update': 'operator',
  'banner.submit_review': 'operator',
  'banner.publish': 'publisher',
  'banner.rollback': 'publisher',
  'banner.archive': 'publisher',
  // Fan ads
  'fan_ad.list': 'viewer',
  'fan_ad.approve': 'operator',
  'fan_ad.reject': 'operator',
  // Feature flags
  'flag.list': 'viewer',
  'flag.get': 'viewer',
  'flag.create': 'operator',
  'flag.update': 'operator',
  'flag.publish': 'publisher',
  'flag.rollback': 'publisher',
  // Audit
  'audit.list': 'viewer',
  // Config
  'config.refresh': 'publisher',
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
      log({ level: 'warn', fn: 'ops-manage', action: 'auth_failed', details: { requestId } })
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

    // 3. Check role
    const userRole = await getStaffRole(admin, user.id)
    const minRole = ACTION_MIN_ROLES[action]

    if (!minRole) {
      return err(400, `Unknown action: ${action}`, req)
    }

    if (!hasMinRole(userRole, minRole)) {
      log({
        level: 'warn', fn: 'ops-manage', action: 'access_denied',
        userId: user.id,
        details: { requestId, requiredRole: minRole, actualRole: userRole || 'none' },
      })
      return err(403, `Insufficient permissions. Required: ${minRole}`, req)
    }

    // 4. Rate limiting
    const rl = await checkRateLimit(admin, {
      key: `ops:${user.id}`,
      limit: 120,        // 120 requests per minute (generous for CRM)
      windowSeconds: 60,
    })
    if (!rl.allowed) {
      log({ level: 'warn', fn: 'ops-manage', action: 'rate_limited', userId: user.id, details: { requestId } })
      return err(429, 'Too many requests', req, rateLimitHeaders(rl))
    }

    // 5. Log request start
    log({
      level: 'info', fn: 'ops-manage', action,
      userId: user.id,
      details: { requestId },
    })

    // 6. Validate + Dispatch
    let result: unknown

    switch (action) {
      // Staff
      case 'staff.list':
        result = await staffList(admin)
        break
      case 'staff.upsert': {
        const v = validateStaffUpsert(payload)
        result = await staffUpsert(admin, user.id, userRole!, v)
        break
      }
      case 'staff.remove': {
        const v = validateStaffRemove(payload)
        result = await staffRemove(admin, user.id, userRole!, v)
        break
      }

      // Assets
      case 'asset.list': {
        const v = validateAssetList(payload)
        result = await assetList(admin, v)
        break
      }
      case 'asset.upload_complete': {
        const v = validateAssetUpload(payload)
        result = await assetUploadComplete(admin, user.id, userRole!, v)
        break
      }
      case 'asset.delete': {
        const v = validateAssetDelete(payload)
        result = await assetDelete(admin, user.id, userRole!, v)
        break
      }

      // Banners
      case 'banner.list': {
        const v = validateBannerList(payload)
        result = await bannerList(admin, v)
        break
      }
      case 'banner.get': {
        const v = validateBannerGet(payload)
        result = await bannerGet(admin, v)
        break
      }
      case 'banner.create': {
        const v = validateBannerCreate(payload)
        result = await bannerCreate(admin, user.id, userRole!, v)
        break
      }
      case 'banner.update': {
        const v = validateBannerUpdate(payload)
        result = await bannerUpdate(admin, user.id, userRole!, v)
        break
      }
      case 'banner.submit_review': {
        const v = validateBannerVersioned(payload)
        result = await bannerSubmitReview(admin, user.id, userRole!, v)
        break
      }
      case 'banner.publish': {
        const v = validateBannerVersioned(payload)
        result = await bannerPublish(admin, user.id, userRole!, v)
        break
      }
      case 'banner.rollback': {
        const v = validateBannerIdOnly(payload)
        result = await bannerRollback(admin, user.id, userRole!, v)
        break
      }
      case 'banner.archive': {
        const v = validateBannerIdOnly(payload)
        result = await bannerArchive(admin, user.id, userRole!, v)
        break
      }

      // Fan Ads
      case 'fan_ad.list': {
        const v = validateFanAdList(payload)
        result = await fanAdList(admin, v)
        break
      }
      case 'fan_ad.approve': {
        const v = validateFanAdApprove(payload)
        result = await fanAdApprove(admin, user.id, userRole!, v)
        break
      }
      case 'fan_ad.reject': {
        const v = validateFanAdReject(payload)
        result = await fanAdReject(admin, user.id, userRole!, v)
        break
      }

      // Feature Flags
      case 'flag.list': {
        const v = validateFlagList(payload)
        result = await flagList(admin, v)
        break
      }
      case 'flag.get': {
        const v = validateFlagGet(payload)
        result = await flagGet(admin, v)
        break
      }
      case 'flag.create': {
        const v = validateFlagCreate(payload)
        result = await flagCreate(admin, user.id, userRole!, v)
        break
      }
      case 'flag.update': {
        const v = validateFlagUpdate(payload)
        result = await flagUpdate(admin, user.id, userRole!, v)
        break
      }
      case 'flag.publish': {
        const v = validateFlagVersioned(payload)
        result = await flagPublish(admin, user.id, userRole!, v)
        break
      }
      case 'flag.rollback': {
        const v = validateFlagIdOnly(payload)
        result = await flagRollback(admin, user.id, userRole!, v)
        break
      }

      // Audit
      case 'audit.list': {
        const v = validateAuditList(payload)
        result = await auditList(admin, v)
        break
      }

      // Config refresh
      case 'config.refresh':
        await admin.rpc('refresh_app_public_config')
        result = { refreshed: true }
        break

      default:
        return err(400, `Unknown action: ${action}`, req)
    }

    // 7. Log success
    const durationMs = Date.now() - startTime
    log({
      level: 'info', fn: 'ops-manage', action: action + '.ok',
      userId: user.id,
      details: { requestId, durationMs },
    })

    return ok(result, req, rateLimitHeaders(rl))
  } catch (e) {
    const error = e as Error & { statusCode?: number }
    const status = error.statusCode || (error instanceof ValidationError ? 400 : 500)
    const durationMs = Date.now() - startTime

    log({
      level: 'error', fn: 'ops-manage', action: 'error',
      error: error.message,
      details: { requestId, status, durationMs },
    })

    // Emit middleware event for observability (T4)
    if (error instanceof ValidationError) {
      const adminForMetrics = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
      emitMwEvent(adminForMetrics, {
        fnName: 'ops-manage',
        eventType: 'schema_invalid',
        statusCode: 400,
      })
    }

    return err(status, error.message, req)
  }
})
