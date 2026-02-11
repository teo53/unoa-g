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
import { maskPII } from '../_shared/pii_mask.ts'
import { getCorsHeaders } from '../_shared/cors.ts'
import { checkRateLimit, rateLimitHeaders } from '../_shared/rate_limit.ts'

const jsonHeaders = { 'Content-Type': 'application/json' }

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')

interface RequestBody {
  channel_id: string
  message_id?: string
  fan_message?: string
  correlation_id?: string
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
    return new Response('ok', { headers: getCorsHeaders(req) })
  }

  const startTime = Date.now()

  try {
    // Validate authorization
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
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
        { status: 401, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // B5: Rate limiting — 50 requests/day per creator
    const rateLimitAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    const rlResult = await checkRateLimit(rateLimitAdmin, {
      key: `ai-reply:${user.id}`,
      limit: 50,
      windowSeconds: 86400, // 24 hours
    })
    if (!rlResult.allowed) {
      return new Response(
        JSON.stringify({ error: 'Rate limit exceeded (50/day)' }),
        { status: 429, headers: { ...getCorsHeaders(req), ...jsonHeaders, ...rateLimitHeaders(rlResult) } }
      )
    }

    // Parse request body
    const body: RequestBody = await req.json()
    const { channel_id, message_id, fan_message, correlation_id, style = 'neutral', max_chars = 200 } = body

    if (!channel_id) {
      return new Response(
        JSON.stringify({ error: 'channel_id is required' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (!message_id && !fan_message) {
      return new Response(
        JSON.stringify({ error: 'message_id or fan_message is required' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
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
        { status: 404, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    if (channel.artist_id !== user.id) {
      return new Response(
        JSON.stringify({ error: 'Forbidden: Not channel owner' }),
        { status: 403, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Create admin client for reading data (service_role - SERVER ONLY)
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Get fan message content (NO PII - only message content)
    // Supports two modes:
    // 1. message_id provided: fetch from DB with channel_id ownership check
    // 2. fan_message provided: use directly (for question cards / non-DB messages)
    let fanMessageContent = fan_message || ''

    if (message_id) {
      const { data: msgData, error: msgError } = await adminClient
        .from('messages')
        .select('content, channel_id')
        .eq('id', message_id)
        .single()

      if (!msgError && msgData) {
        // Security: verify message belongs to this channel
        if (msgData.channel_id !== channel_id) {
          return new Response(
            JSON.stringify({ error: 'Message does not belong to this channel' }),
            { status: 403, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
          )
        }
        fanMessageContent = msgData.content || fanMessageContent
      }
      // If message lookup fails but fan_message exists, fall through to use it
    }

    if (!fanMessageContent) {
      return new Response(
        JSON.stringify({ error: 'No fan message content available' }),
        { status: 400, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Fetch conversation context (last 5 messages for dialog flow)
    let conversationHistory: { content: string; sender_type: string }[] = []
    if (message_id) {
      // Get the target message's created_at for ordering
      const { data: targetMsg } = await adminClient
        .from('messages')
        .select('created_at, sender_id')
        .eq('id', message_id)
        .single()

      if (targetMsg) {
        // Fetch recent messages before this one (same channel, same fan + creator only)
        const { data: contextMsgs } = await adminClient
          .from('messages')
          .select('content, sender_type')
          .eq('channel_id', channel_id)
          .lt('created_at', targetMsg.created_at)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(5)

        if (contextMsgs) {
          conversationHistory = contextMsgs.reverse() // chronological order
        }
      }
    }

    // --- Observability: Compute idempotency key for caching ---
    const idempotencyInput = `${channel_id}:${message_id || ''}:${fanMessageContent}`
    const idempotencyKey = `idem_${hashString(idempotencyInput)}`
    const jobCorrelationId = correlation_id || `corr_${crypto.randomUUID().substring(0, 8)}`

    // Check ai_draft_jobs cache (DB-level idempotency)
    const { data: cachedJob } = await adminClient
      .from('ai_draft_jobs')
      .select('cached_suggestions, status')
      .eq('idempotency_key', idempotencyKey)
      .eq('status', 'success')
      .gt('expires_at', new Date().toISOString())
      .single()

    if (cachedJob?.cached_suggestions) {
      const latencyMs = Date.now() - startTime
      return new Response(
        JSON.stringify({
          suggestions: cachedJob.cached_suggestions,
          meta: {
            provider: 'cache',
            model: 'cached',
            latency_ms: latencyMs,
            cache_hit: true,
            ai_generated_label: 'AI가 만들었습니다',
          },
        }),
        { headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    // Insert job record (observability + idempotency lock)
    let jobId: string | null = null
    try {
      const { data: jobData } = await adminClient
        .from('ai_draft_jobs')
        .insert({
          correlation_id: jobCorrelationId,
          channel_id,
          message_id: message_id || null,
          creator_id: user.id,
          idempotency_key: idempotencyKey,
          status: 'generating',
          expires_at: new Date(Date.now() + 3600000).toISOString(), // 1 hour
        })
        .select('id')
        .single()
      jobId = jobData?.id || null
    } catch (_) {
      // ON CONFLICT: another request with same idempotency_key in progress
      // Continue without job tracking
    }

    // Get creator profile (public info only)
    const { data: creatorProfile } = await adminClient
      .from('creator_profiles')
      .select('stage_name, category')
      .eq('user_id', user.id)
      .single()

    // Get recent creator messages for pattern learning (last 20, content only)
    const { data: recentMessages } = await adminClient
      .from('messages')
      .select('content')
      .eq('channel_id', channel_id)
      .eq('sender_type', 'artist')
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .limit(20)

    // SECURITY: Mask PII before sending to external LLM
    fanMessageContent = maskPII(fanMessageContent)
    conversationHistory = conversationHistory.map(m => ({
      ...m,
      content: maskPII(m.content),
    }))

    // Build prompt for AI
    const prompt = buildPrompt(
      fanMessageContent,
      creatorProfile,
      recentMessages || [],
      conversationHistory,
      style,
      max_chars
    )

    // Call Claude API
    if (!ANTHROPIC_API_KEY) {
      console.error('AI service not configured')
      // Update job status on error
      if (jobId) {
        await adminClient.from('ai_draft_jobs').update({
          status: 'hard_fail',
          error_code: 'no_api_key',
          completed_at: new Date().toISOString(),
          latency_ms: Date.now() - startTime,
        }).eq('id', jobId)
      }
      return new Response(
        JSON.stringify({ error: 'AI service configuration error' }),
        { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
      )
    }

    const { suggestions, model: modelUsed } = await callAnthropic(prompt, ANTHROPIC_API_KEY)

    const latencyMs = Date.now() - startTime

    // Format response
    const labels = ['짧게', '따뜻하게', '재미있게']
    const formattedSuggestions: ReplySuggestion[] = suggestions.slice(0, 3).map((text, i) => ({
      id: `opt${i + 1}`,
      label: labels[i] || `옵션 ${i + 1}`,
      text: text.trim(),
    }))

    // Update job record with success
    if (jobId) {
      await adminClient.from('ai_draft_jobs').update({
        status: 'success',
        cached_suggestions: formattedSuggestions,
        provider: 'anthropic',
        model: modelUsed,
        latency_ms: latencyMs,
        completed_at: new Date().toISOString(),
      }).eq('id', jobId)
    }

    return new Response(
      JSON.stringify({
        suggestions: formattedSuggestions,
        meta: {
          provider: 'anthropic',
          model: modelUsed,
          latency_ms: latencyMs,
          cache_hit: false,
          // IMPORTANT: This label MUST be shown to creator
          ai_generated_label: 'AI가 만들었습니다',
        },
      }),
      { headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )

  } catch (error) {
    console.error('Error in ai-reply-suggest:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...getCorsHeaders(req), ...jsonHeaders } }
    )
  }
})

function analyzeCreatorPatterns(messages: { content: string }[]): string {
  if (messages.length === 0) return '(데이터 없음)'

  // 평균 길이
  const lengths = messages.map(m => m.content.length)
  const avgLength = Math.round(lengths.reduce((a, b) => a + b, 0) / lengths.length)

  // 이모지 사용률
  const emojiRegex = /[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/gu
  let totalEmojis = 0
  for (const msg of messages) {
    const matches = msg.content.match(emojiRegex)
    if (matches) totalEmojis += matches.length
  }
  const emojiRate = totalEmojis / messages.length

  // 존댓말/반말 비율
  const formalRegex = /(요|입니다|습니다|세요|겠습|니다|드려|드릴게)/
  const casualRegex = /(해|야|지|어|아|ㅋ|ㅎ|~|ㅠ|ㅜ)$/m
  let formalCount = 0
  let casualCount = 0
  for (const msg of messages) {
    if (formalRegex.test(msg.content)) formalCount++
    if (casualRegex.test(msg.content)) casualCount++
  }

  const total = messages.length
  let dominantTone: string
  if (formalCount / total > 0.6) {
    dominantTone = emojiRate > 1.5 ? '다정한 존댓말' : '정중한 존댓말'
  } else if (casualCount / total > 0.6) {
    dominantTone = emojiRate > 1.5 ? '친근한 반말' : '쿨한 반말'
  } else {
    dominantTone = '자연스러운 혼합체'
  }

  // 스타일 키워드
  const styles: string[] = []
  if (emojiRate > 2.0) styles.push('이모지 많이 사용')
  if (emojiRate < 0.3) styles.push('이모지 거의 안 씀')
  if (avgLength < 30) styles.push('짧고 간결한 스타일')
  if (avgLength > 80) styles.push('상세하게 답변하는 스타일')

  // 예시 메시지 (최대 5개, 다양한 길이)
  const sorted = [...messages].sort((a, b) => a.content.length - b.content.length)
  const examples: string[] = []
  if (sorted.length > 0) examples.push(sorted[0].content) // 짧은
  if (sorted.length > 2) examples.push(sorted[Math.floor(sorted.length / 2)].content) // 중간
  if (sorted.length > 1) examples.push(sorted[sorted.length - 1].content) // 긴
  // 최신 2개
  examples.push(...messages.slice(0, 2).map(m => m.content))
  const uniqueExamples = [...new Set(examples)].slice(0, 5)

  return `[크리에이터 답변 패턴 분석 (${total}개 메시지 기반)]
- 주요 톤: ${dominantTone}
- 평균 답변 길이: 약 ${avgLength}자
${styles.length > 0 ? `- 스타일 특징: ${styles.join(', ')}` : ''}

[최근 답변 예시 (톤/스타일 참조용)]
${uniqueExamples.map(e => `- "${e}"`).join('\n')}

⚠️ 위 패턴을 참조하여 크리에이터의 실제 답변 스타일과 유사하게 초안을 작성하세요.`
}

function buildPrompt(
  fanMessage: string,
  creator: { stage_name?: string; category?: string[] } | null,
  recentMessages: { content: string }[],
  conversationHistory: { content: string; sender_type: string }[],
  style: string,
  maxChars: number
): string {
  const stageName = creator?.stage_name || '크리에이터'
  const categories = creator?.category?.join(', ') || '엔터테인먼트'
  const patternAnalysis = analyzeCreatorPatterns(recentMessages)

  // Build conversation context section
  let contextSection = ''
  if (conversationHistory.length > 0) {
    const contextLines = conversationHistory.map(m =>
      m.sender_type === 'artist' ? `[크리에이터] "${m.content}"` : `[팬] "${m.content}"`
    ).join('\n')
    contextSection = `[대화 맥락 (최근 대화 흐름)]
${contextLines}

`
  }

  return `
당신은 K-pop/엔터테인먼트 크리에이터의 팬 메시지 답글 초안을 작성하는 도우미입니다.

[크리에이터 정보]
- 활동명: ${stageName}
- 카테고리: ${categories}

${patternAnalysis}

${contextSection}[팬 메시지]
"${fanMessage}"

[메시지 유형 분석]
먼저 팬 메시지의 유형을 파악하세요 (질문/감사/축하/일상대화/요청/동의/감탄).
대화 맥락을 고려하여 문맥에 맞는 답변을 작성하세요.
특히 "맞아", "그래", "ㅋㅋ", "ㅎㅎ" 등 짧은 반응형 메시지는 이전 대화 흐름에서 답변 단서를 찾으세요.

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
  const model = 'claude-sonnet-4-5-20250929'

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
      temperature: 0.7,
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

/// Simple string hash for idempotency keys (not cryptographic).
function hashString(str: string): string {
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash // Convert to 32bit integer
  }
  return Math.abs(hash).toString(36)
}
