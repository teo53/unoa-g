// AI Poll Suggestion Edge Function
// Generates poll/VS candidates for creators to use as conversation starters.
//
// IMPORTANT:
// - Creator must select and send — AI never auto-posts polls
// - Safety filter blocks sensitive topics
// - Rate limited: max 5 sent polls per channel per KST day

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')

interface RequestBody {
  channel_id: string
  count?: number
  categories?: string[]
}

interface PollCandidate {
  category: string
  question: string
  options: { id: string; text: string }[]
}

const VALID_CATEGORIES = [
  'preference_vs',
  'content_choice',
  'light_tmi',
  'schedule_choice',
  'mini_mission',
]

// Sensitive topic keywords to filter out
const SAFETY_BLOCKLIST = [
  '정치', '대통령', '선거', '정당', '투표',
  '종교', '교회', '성당', '절', '이슬람',
  '성적', '19금', '야한', '섹시',
  '자해', '자살', '죽고 싶',
  '혐오', '차별', '인종',
  '외모 평가', '몸무게', '키 작',
  '마약', '도박',
]

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const startTime = Date.now()
  const correlationId = `corr_poll_${crypto.randomUUID().substring(0, 8)}`

  try {
    // Auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header', correlation_id: correlationId }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', correlation_id: correlationId }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request
    const body: RequestBody = await req.json()
    const { channel_id, count = 5, categories } = body

    if (!channel_id) {
      return new Response(
        JSON.stringify({ error: 'channel_id is required', correlation_id: correlationId }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify creator owns channel
    const { data: channel } = await supabaseClient
      .from('channels')
      .select('artist_id, name')
      .eq('id', channel_id)
      .single()

    if (!channel || channel.artist_id !== user.id) {
      return new Response(
        JSON.stringify({ error: 'Not channel owner', correlation_id: correlationId }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check API key
    if (!ANTHROPIC_API_KEY) {
      console.error('AI service not configured')
      return new Response(
        JSON.stringify({ error: 'AI service configuration error', correlation_id: correlationId }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Load recent polls for dedup (last 30 days)
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
    const { data: recentPolls } = await adminClient
      .from('message_polls')
      .select('question')
      .gte('created_at', thirtyDaysAgo)

    const recentQuestions = (recentPolls || []).map(p => p.question)

    // Build prompt
    const selectedCategories = categories?.filter(c => VALID_CATEGORIES.includes(c)) || VALID_CATEGORIES
    const prompt = buildPrompt(count, selectedCategories, recentQuestions)

    // Call Claude (using Haiku for speed)
    const candidates = await callAnthropic(prompt, ANTHROPIC_API_KEY)

    // Safety filter
    const safeCandidates = candidates.filter(c => !isSensitive(c.question, c.options))

    // Insert into poll_drafts
    const draftsToInsert = safeCandidates.map(c => ({
      channel_id,
      creator_id: user.id,
      correlation_id: correlationId,
      category: c.category,
      question: c.question,
      options: c.options,
      status: 'suggested',
    }))

    if (draftsToInsert.length > 0) {
      await supabaseClient.from('poll_drafts').insert(draftsToInsert)
    }

    const latencyMs = Date.now() - startTime

    return new Response(
      JSON.stringify({
        drafts: safeCandidates.map((c, i) => ({
          id: `draft_${i}`,
          ...c,
        })),
        correlation_id: correlationId,
        meta: {
          provider: 'anthropic',
          model: 'claude-haiku-4-5-20251001',
          latency_ms: latencyMs,
          total_generated: candidates.length,
          safety_filtered: candidates.length - safeCandidates.length,
        },
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error(`[${correlationId}] Error in ai-poll-suggest:`, error)
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
        correlation_id: correlationId,
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function buildPrompt(count: number, categories: string[], recentQuestions: string[]): string {
  const categoryDescriptions: Record<string, string> = {
    preference_vs: '취향 VS (둘 중 하나 고르기, 예: "여름 vs 겨울")',
    content_choice: '콘텐츠 선택 (다음에 어떤 콘텐츠를 원하는지, 예: "댄스 커버 vs 노래 커버")',
    light_tmi: '가벼운 TMI (재미있는 사소한 질문, 예: "오늘 아침에 뭐 먹었는지 맞춰봐")',
    schedule_choice: '일정 선택 (활동/스케줄 관련, 예: "라이브 시간대 투표")',
    mini_mission: '미니 미션 (참여형 활동, 예: "오늘 하루 긍정 한마디 남기기")',
  }

  const categoryList = categories
    .map(c => `- ${c}: ${categoryDescriptions[c] || c}`)
    .join('\n')

  const recentContext = recentQuestions.length > 0
    ? `\n[최근 30일 사용된 질문들 (중복 방지)]\n${recentQuestions.slice(0, 10).map(q => `- "${q}"`).join('\n')}\n`
    : ''

  return `당신은 K-pop/엔터테인먼트 팬 채팅방의 투표/VS 질문을 생성하는 도우미입니다.

[목표]
대부분의 사람들이 일반적으로 좋아할 만한, 가볍고 재미있는 투표 질문을 생성하세요.
팬들이 부담 없이 참여할 수 있는 질문이어야 합니다.

[카테고리]
${categoryList}

${recentContext}

[안전 규칙 - 반드시 준수]
- 정치, 종교, 성적 콘텐츠, 자해/폭력, 혐오 발언 관련 질문 절대 금지
- 외모 평가, 체형 비교 관련 질문 금지
- 특정 실존 인물을 비교하거나 평가하는 질문 금지
- 논란이 될 수 있는 민감한 주제 피하기
- 모든 질문은 긍정적이고 재미있는 톤으로

[출력 형식]
정확히 ${count}개의 투표 질문을 JSON 배열로 반환하세요.
각 질문에는 category, question, options (2-4개) 필드가 있어야 합니다.

예시:
[
  {
    "category": "preference_vs",
    "question": "여름 vs 겨울 어느 쪽?",
    "options": [
      {"id": "opt_a", "text": "여름! ☀️"},
      {"id": "opt_b", "text": "겨울! ❄️"}
    ]
  }
]

JSON만 출력하고 다른 설명은 포함하지 마세요.`
}

async function callAnthropic(prompt: string, apiKey: string): Promise<PollCandidate[]> {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 2048,
      messages: [{ role: 'user', content: prompt }],
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`Anthropic API error: ${error}`)
  }

  const data = await response.json()
  const text = data.content?.[0]?.text || '[]'

  return parsePollCandidates(text)
}

function parsePollCandidates(text: string): PollCandidate[] {
  try {
    const match = text.match(/\[[\s\S]*\]/)
    if (match) {
      const parsed = JSON.parse(match[0])
      if (Array.isArray(parsed)) {
        return parsed
          .filter(
            (item: any) =>
              item.category &&
              item.question &&
              Array.isArray(item.options) &&
              item.options.length >= 2
          )
          .map((item: any) => ({
            category: item.category,
            question: item.question,
            options: item.options.slice(0, 4).map((opt: any, i: number) => ({
              id: opt.id || `opt_${String.fromCharCode(97 + i)}`,
              text: opt.text || `옵션 ${i + 1}`,
            })),
          }))
      }
    }
  } catch (e) {
    console.error('Failed to parse poll candidates:', e)
  }
  return []
}

function isSensitive(question: string, options: { text: string }[]): boolean {
  const allText = [question, ...options.map(o => o.text)].join(' ')
  return SAFETY_BLOCKLIST.some(keyword => allText.includes(keyword))
}
