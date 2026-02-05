// AI Reply Suggestion Edge Function
// Generates draft reply suggestions for creators (NEVER auto-sends)
//
// IMPORTANT CONSTRAINTS:
// - AI can ONLY suggest drafts, NOT send messages
// - All suggestions must be labeled as "AI가 만들었습니다"
// - No PII is sent to AI
// - service_role is used ONLY on server-side

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const AI_PROVIDER = Deno.env.get('AI_PROVIDER') || 'anthropic'
const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')
const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')

interface RequestBody {
  channel_id: string
  message_id: string
  style?: 'neutral' | 'warm' | 'playful'
  max_chars?: number
}

interface ReplySuggestion {
  id: string
  label: string
  text: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const startTime = Date.now()

  try {
    // Validate authorization
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client with user's auth
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    // Get current user
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const body: RequestBody = await req.json()
    const { channel_id, message_id, style = 'neutral', max_chars = 200 } = body

    if (!channel_id || !message_id) {
      return new Response(
        JSON.stringify({ error: 'channel_id and message_id are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify creator owns this channel
    const { data: channel, error: channelError } = await supabaseClient
      .from('channels')
      .select('artist_id')
      .eq('id', channel_id)
      .single()

    if (channelError || !channel) {
      return new Response(
        JSON.stringify({ error: 'Channel not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (channel.artist_id !== user.id) {
      return new Response(
        JSON.stringify({ error: 'Forbidden: Not channel owner' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create admin client for reading data (service_role - SERVER ONLY)
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Get fan message content (NO PII - only message content)
    const { data: fanMessage, error: msgError } = await adminClient
      .from('messages')
      .select('content')
      .eq('id', message_id)
      .single()

    if (msgError || !fanMessage) {
      return new Response(
        JSON.stringify({ error: 'Message not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get creator profile (public info only)
    const { data: creatorProfile } = await adminClient
      .from('creator_profiles')
      .select('stage_name, category')
      .eq('user_id', user.id)
      .single()

    // Get recent creator messages for tone reference (last 3, content only)
    const { data: recentMessages } = await adminClient
      .from('messages')
      .select('content')
      .eq('channel_id', channel_id)
      .eq('sender_type', 'artist')
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .limit(3)

    // Build prompt for AI
    const prompt = buildPrompt(
      fanMessage.content || '',
      creatorProfile,
      recentMessages || [],
      style,
      max_chars
    )

    // Call LLM
    let suggestions: string[]
    let modelUsed: string

    if (AI_PROVIDER === 'openai' && OPENAI_API_KEY) {
      const result = await callOpenAI(prompt, OPENAI_API_KEY)
      suggestions = result.suggestions
      modelUsed = result.model
    } else if (ANTHROPIC_API_KEY) {
      const result = await callAnthropic(prompt, ANTHROPIC_API_KEY)
      suggestions = result.suggestions
      modelUsed = result.model
    } else {
      return new Response(
        JSON.stringify({ error: 'No AI provider configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const latencyMs = Date.now() - startTime

    // Format response
    const labels = ['짧게', '따뜻하게', '재미있게']
    const formattedSuggestions: ReplySuggestion[] = suggestions.slice(0, 3).map((text, i) => ({
      id: `opt${i + 1}`,
      label: labels[i] || `옵션 ${i + 1}`,
      text: text.trim(),
    }))

    return new Response(
      JSON.stringify({
        suggestions: formattedSuggestions,
        meta: {
          provider: AI_PROVIDER,
          model: modelUsed,
          latency_ms: latencyMs,
          // IMPORTANT: This label MUST be shown to creator
          ai_generated_label: 'AI가 만들었습니다',
        },
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in ai-reply-suggest:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function buildPrompt(
  fanMessage: string,
  creator: { stage_name?: string; category?: string[] } | null,
  recentMessages: { content: string }[],
  style: string,
  maxChars: number
): string {
  const stageName = creator?.stage_name || '크리에이터'
  const categories = creator?.category?.join(', ') || '엔터테인먼트'
  const recentTone = recentMessages.length > 0
    ? recentMessages.map(m => `- "${m.content}"`).join('\n')
    : '(없음)'

  return `
당신은 K-pop/엔터테인먼트 크리에이터의 팬 메시지 답글 초안을 작성하는 도우미입니다.

[크리에이터 정보]
- 활동명: ${stageName}
- 카테고리: ${categories}

[팬 메시지]
"${fanMessage}"

[최근 크리에이터 메시지 톤 참조]
${recentTone}

[스타일 가이드]: ${style === 'warm' ? '따뜻하고 다정하게' : style === 'playful' ? '재미있고 유쾌하게' : '자연스럽고 친근하게'}
[글자 제한]: 각 답변 ${maxChars}자 이내

[안전 규칙 - 반드시 준수]
- 크리에이터의 오프라인 행동에 대한 구체적 사실 주장 금지
- 오프플랫폼 연락처 요청/공유 금지 (전화번호, 이메일, SNS 등)
- 성적/로맨틱 압박 콘텐츠 금지
- 미성년자 위험 언어 금지
- 괴롭힘, 혐오 발언, 불법 지시 금지
- 친근하되 기만적이지 않게 작성
- "AI"라는 단어 사용 금지 (크리에이터가 직접 쓴 것처럼)

정확히 3개의 서로 다른 스타일의 답글 초안을 JSON 배열 형식으로 반환하세요.
각 답글은 따옴표로 감싸고, 배열 형식이어야 합니다.

예시 형식:
["첫 번째 답글", "두 번째 답글", "세 번째 답글"]

답글만 출력하고 다른 설명은 포함하지 마세요.
`
}

async function callAnthropic(prompt: string, apiKey: string): Promise<{ suggestions: string[], model: string }> {
  const model = 'claude-3-haiku-20240307'

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model,
      max_tokens: 1024,
      messages: [{ role: 'user', content: prompt }],
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Anthropic API error: ${error}`)
  }

  const data = await response.json()
  const text = data.content?.[0]?.text || '[]'

  // Parse JSON array from response
  const suggestions = parseJsonArray(text)

  return { suggestions, model }
}

async function callOpenAI(prompt: string, apiKey: string): Promise<{ suggestions: string[], model: string }> {
  const model = 'gpt-4o-mini'

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 1024,
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`OpenAI API error: ${error}`)
  }

  const data = await response.json()
  const text = data.choices?.[0]?.message?.content || '[]'

  // Parse JSON array from response
  const suggestions = parseJsonArray(text)

  return { suggestions, model }
}

function parseJsonArray(text: string): string[] {
  try {
    // Try to find JSON array in the response
    const match = text.match(/\[[\s\S]*\]/)
    if (match) {
      const parsed = JSON.parse(match[0])
      if (Array.isArray(parsed)) {
        return parsed.filter(item => typeof item === 'string')
      }
    }
  } catch (e) {
    console.error('Failed to parse JSON array:', e)
  }

  // Fallback: split by newlines if JSON parsing fails
  const lines = text.split('\n').filter(line => line.trim().length > 0)
  return lines.slice(0, 3).map(line => line.replace(/^["'\d\.\)]+\s*/, '').trim())
}
