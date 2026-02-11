// Funding Studio Submit Edge Function
// Allows creators to submit their draft campaigns for admin review
//
// SECURITY:
// - Requires authenticated user
// - User must be the campaign creator
// - Validates all required fields before submission

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders } from '../_shared/cors.ts'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

const jsonHeaders = { 'Content-Type': 'application/json' }

interface SubmitRequest {
  campaignId: string
}

interface ValidationError {
  field: string
  message: string
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

    // Parse request
    const body: SubmitRequest = await req.json()
    const { campaignId } = body

    if (!campaignId) {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign ID is required' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Get campaign with tiers
    const { data: campaign, error: campaignError } = await supabaseAdmin
      .from('funding_campaigns')
      .select(`
        *,
        funding_reward_tiers (id, title, price_dt, is_active)
      `)
      .eq('id', campaignId)
      .single()

    if (campaignError || !campaign) {
      return new Response(
        JSON.stringify({ success: false, error: 'Campaign not found' }),
        { status: 404, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Check ownership
    if (campaign.creator_id !== user.id) {
      return new Response(
        JSON.stringify({ success: false, error: 'You can only submit your own campaigns' }),
        { status: 403, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Check current status
    if (!['draft', 'rejected'].includes(campaign.status)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Cannot submit campaign with status "${campaign.status}". Only draft or rejected campaigns can be submitted.`,
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Validate required fields
    const errors: ValidationError[] = []

    if (!campaign.title || campaign.title.trim().length < 5) {
      errors.push({ field: 'title', message: 'Title must be at least 5 characters' })
    }

    if (!campaign.description_md || campaign.description_md.trim().length < 100) {
      errors.push({ field: 'description_md', message: 'Description must be at least 100 characters' })
    }

    if (!campaign.cover_image_url) {
      errors.push({ field: 'cover_image_url', message: 'Cover image is required' })
    }

    if (!campaign.goal_amount_dt || campaign.goal_amount_dt < 100) {
      errors.push({ field: 'goal_amount_dt', message: 'Goal amount must be at least 100 DT' })
    }

    if (!campaign.end_at) {
      errors.push({ field: 'end_at', message: 'End date is required' })
    } else {
      const endDate = new Date(campaign.end_at)
      const minEndDate = new Date()
      minEndDate.setDate(minEndDate.getDate() + 7) // At least 7 days from now

      if (endDate < minEndDate) {
        errors.push({ field: 'end_at', message: 'Campaign must run for at least 7 days' })
      }
    }

    // Check for at least one active tier
    const activeTiers = campaign.funding_reward_tiers?.filter((t: { is_active: boolean }) => t.is_active) || []
    if (activeTiers.length === 0) {
      errors.push({ field: 'tiers', message: 'At least one active reward tier is required' })
    }

    // Return validation errors if any
    if (errors.length > 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Validation failed',
          validationErrors: errors,
        }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Update campaign status to submitted
    const { data: updatedCampaign, error: updateError } = await supabaseAdmin
      .from('funding_campaigns')
      .update({
        status: 'submitted',
        submitted_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        // Clear any previous rejection reason
        rejection_reason: null,
        reviewed_by: null,
        reviewed_at: null,
      })
      .eq('id', campaignId)
      .select()
      .single()

    if (updateError) {
      console.error('Update error:', updateError)
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to submit campaign' }),
        { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        campaign: updatedCampaign,
        message: 'Campaign submitted for review. You will be notified once it is reviewed.',
      }),
      { status: 200, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )

  } catch (error) {
    console.error('Studio submit error:', error)
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }
})
