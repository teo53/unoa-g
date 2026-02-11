// Funding Admin Review Edge Function
// Allows admins to approve or reject funding campaigns
//
// SECURITY:
// - Requires authenticated admin user (role = 'admin')
// - Validates campaign status before transition

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders } from '../_shared/cors.ts'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

const jsonHeaders = { 'Content-Type': 'application/json' }

interface ReviewRequest {
  campaignId: string
  action: 'approve' | 'reject'
  reason?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: getCorsHeaders(req) })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ success: false, error: 'Method not allowed' }),
      { status: 405, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }

  try {
    // Get auth token
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing authorization header' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Create admin client
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Verify user
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid authentication' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Check if user is admin
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('user_profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profileError || !profile || profile.role !== 'admin') {
      return new Response(
        JSON.stringify({ success: false, error: 'Admin access required' }),
        { status: 403, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Parse request
    const body: ReviewRequest = await req.json()
    const { campaignId, action, reason } = body

    if (!campaignId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign ID is required' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (!action || !['approve', 'reject'].includes(action)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Action must be "approve" or "reject"' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (action === 'reject' && !reason) {
      return new Response(
        JSON.stringify({ success: false, error: 'Rejection reason is required' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Get campaign
    const { data: campaign, error: campaignError } = await supabaseAdmin
      .from('funding_campaigns')
      .select('*')
      .eq('id', campaignId)
      .single()

    if (campaignError || !campaign) {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign not found' }),
        { status: 404, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Validate current status
    if (campaign.status !== 'submitted') {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Cannot review campaign with status "${campaign.status}". Only "submitted" campaigns can be reviewed.`,
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Determine new status
    let newStatus: string
    if (action === 'approve') {
      // If start_at is in the past or null, set to active immediately
      const startAt = campaign.start_at ? new Date(campaign.start_at) : null
      if (!startAt || startAt <= new Date()) {
        newStatus = 'active'
      } else {
        newStatus = 'approved'
      }
    } else {
      newStatus = 'rejected'
    }

    // Update campaign
    const updateData: Record<string, unknown> = {
      status: newStatus,
      reviewed_by: user.id,
      reviewed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }

    if (action === 'approve') {
      updateData.approved_at = new Date().toISOString()
    } else {
      updateData.rejection_reason = reason
    }

    const { data: updatedCampaign, error: updateError } = await supabaseAdmin
      .from('funding_campaigns')
      .update(updateData)
      .eq('id', campaignId)
      .select()
      .single()

    if (updateError) {
      console.error('Update error:', updateError)
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to update campaign' }),
        { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        campaign: updatedCampaign,
        message: action === 'approve'
          ? `Campaign approved and set to "${newStatus}"`
          : 'Campaign rejected',
      }),
      { status: 200, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )

  } catch (error) {
    console.error('Admin review error:', error)
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }
})
