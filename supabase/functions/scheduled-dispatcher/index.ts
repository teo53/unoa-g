// Scheduled Message Dispatcher Edge Function
// Processes scheduled messages and sends them at the scheduled time
// Should be run via cron job every minute

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const now = new Date().toISOString()

    // Find all pending scheduled messages that should be sent
    const { data: messages, error: fetchError } = await supabase
      .from('messages')
      .select('*')
      .eq('scheduled_status', 'pending')
      .lte('scheduled_at', now)
      .order('scheduled_at', { ascending: true })
      .limit(100) // Process max 100 at a time

    if (fetchError) {
      console.error('Failed to fetch scheduled messages:', fetchError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch messages' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!messages || messages.length === 0) {
      return new Response(
        JSON.stringify({ success: true, processed: 0, message: 'No messages to process' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Processing ${messages.length} scheduled messages`)

    const results = {
      processed: 0,
      sent: 0,
      failed: 0,
      errors: [] as string[],
    }

    for (const message of messages) {
      results.processed++

      try {
        // Update message status to sent and set created_at to now (makes it visible)
        const { error: updateError } = await supabase
          .from('messages')
          .update({
            scheduled_status: 'sent',
            created_at: now, // This makes it appear as "just sent"
            updated_at: now,
          })
          .eq('id', message.id)
          .eq('scheduled_status', 'pending') // Ensure we only update pending messages

        if (updateError) {
          console.error(`Failed to update message ${message.id}:`, updateError)
          results.failed++
          results.errors.push(`Message ${message.id}: ${updateError.message}`)
          continue
        }

        // If it's a broadcast, create delivery records for all subscribers
        if (message.delivery_scope === 'broadcast') {
          const { data: subscribers, error: subError } = await supabase
            .from('subscriptions')
            .select('user_id')
            .eq('channel_id', message.channel_id)
            .eq('is_active', true)

          if (subError) {
            console.error(`Failed to fetch subscribers for channel ${message.channel_id}:`, subError)
          } else if (subscribers && subscribers.length > 0) {
            // Create delivery records in batches
            const deliveryRecords = subscribers.map(sub => ({
              message_id: message.id,
              user_id: sub.user_id,
            }))

            const batchSize = 100
            for (let i = 0; i < deliveryRecords.length; i += batchSize) {
              const batch = deliveryRecords.slice(i, i + batchSize)
              const { error: deliveryError } = await supabase
                .from('message_delivery')
                .insert(batch)
                .onConflict('message_id,user_id')
                .ignore()

              if (deliveryError) {
                console.error(`Failed to create delivery records:`, deliveryError)
              }
            }

            // Update reply quotas for subscribers (refresh tokens)
            // This is handled by the trigger on messages table
            console.log(`Created delivery records for ${subscribers.length} subscribers`)
          }
        }

        results.sent++
        console.log(`Successfully sent scheduled message ${message.id}`)
      } catch (error) {
        console.error(`Error processing message ${message.id}:`, error)
        results.failed++
        results.errors.push(`Message ${message.id}: ${String(error)}`)
      }
    }

    // Clean up old typing indicators while we're at it
    const { error: cleanupError } = await supabase
      .from('typing_indicators')
      .delete()
      .lt('expires_at', now)

    if (cleanupError) {
      console.log('Failed to clean up typing indicators:', cleanupError)
    }

    console.log('Scheduled message processing complete:', results)

    return new Response(
      JSON.stringify({
        success: true,
        ...results,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Scheduled dispatcher error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
