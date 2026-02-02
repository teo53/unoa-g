// ============================================
// Edge Function: Refresh Fallback Quotas
// Runs daily via cron to enable fallback tokens
// for subscribers who haven't received broadcasts
// ============================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client with service role key
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get fallback policy configuration
    const { data: policyData, error: policyError } = await supabase
      .from('policy_config')
      .select('value')
      .eq('key', 'long_reply_fallback')
      .eq('is_active', true)
      .single()

    if (policyError) {
      throw new Error(`Failed to get fallback policy: ${policyError.message}`)
    }

    const policy = policyData.value
    const daysWithoutBroadcast = policy.days_without_broadcast || 7
    const isEnabled = policy.enabled !== false

    if (!isEnabled) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Fallback quota feature is disabled',
          updated: 0
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Calculate cutoff date (7 days ago by default)
    const cutoffDate = new Date()
    cutoffDate.setDate(cutoffDate.getDate() - daysWithoutBroadcast)

    // Call the database function to enable fallback quotas
    const { data, error } = await supabase
      .rpc('enable_fallback_quotas', {
        cutoff_date: cutoffDate.toISOString()
      })

    if (error) {
      throw new Error(`Failed to enable fallback quotas: ${error.message}`)
    }

    const updatedCount = data as number

    // Log the operation
    console.log(`[refresh-fallback-quotas] Enabled fallback for ${updatedCount} users`)

    return new Response(
      JSON.stringify({
        success: true,
        message: `Enabled fallback quotas for ${updatedCount} users`,
        updated: updatedCount,
        cutoff_date: cutoffDate.toISOString(),
        policy: {
          days_without_broadcast: daysWithoutBroadcast,
          fallback_tokens: policy.fallback_tokens || 1
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('[refresh-fallback-quotas] Error:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
