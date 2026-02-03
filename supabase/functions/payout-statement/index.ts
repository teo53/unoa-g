// Payout Statement Edge Function
// Generates settlement statement documents for creators
// Returns HTML that can be rendered as PDF on client side

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Format number with thousand separators
function formatNumber(num: number): string {
  return num.toLocaleString('ko-KR')
}

// Format date in Korean
function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  return `${date.getFullYear()}년 ${date.getMonth() + 1}월 ${date.getDate()}일`
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { payoutId } = await req.json()

    if (!payoutId) {
      return new Response(
        JSON.stringify({ error: 'Missing payoutId' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get payout with line items
    const { data: payout, error: payoutError } = await supabase
      .from('payouts')
      .select(`
        *,
        payout_line_items (*),
        creator_profiles!inner (
          stage_name,
          user_id
        )
      `)
      .eq('id', payoutId)
      .single()

    if (payoutError || !payout) {
      return new Response(
        JSON.stringify({ error: 'Payout not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate HTML statement
    const html = `
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>정산서 - UNO A</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
      padding: 40px;
      max-width: 800px;
      margin: 0 auto;
      color: #111827;
      line-height: 1.6;
    }
    .header {
      text-align: center;
      margin-bottom: 40px;
      padding-bottom: 20px;
      border-bottom: 2px solid #E5E7EB;
    }
    .logo {
      font-size: 24px;
      font-weight: 700;
      color: #DE332A;
      margin-bottom: 8px;
    }
    .title {
      font-size: 28px;
      font-weight: 600;
      margin-bottom: 8px;
    }
    .period {
      font-size: 16px;
      color: #6B7280;
    }
    .section {
      margin-bottom: 32px;
    }
    .section-title {
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 16px;
      padding-bottom: 8px;
      border-bottom: 1px solid #E5E7EB;
    }
    .info-grid {
      display: grid;
      grid-template-columns: 140px 1fr;
      gap: 8px 16px;
    }
    .info-label {
      color: #6B7280;
      font-size: 14px;
    }
    .info-value {
      font-size: 14px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 16px;
    }
    th, td {
      padding: 12px 16px;
      text-align: left;
      border-bottom: 1px solid #E5E7EB;
    }
    th {
      background: #F9FAFB;
      font-weight: 600;
      font-size: 14px;
    }
    td {
      font-size: 14px;
    }
    .amount {
      text-align: right;
      font-variant-numeric: tabular-nums;
    }
    .total-row {
      background: #FEF2F2;
      font-weight: 600;
    }
    .total-row td {
      border-bottom: 2px solid #DE332A;
    }
    .summary-box {
      background: #F9FAFB;
      padding: 24px;
      border-radius: 8px;
      margin-bottom: 32px;
    }
    .summary-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 0;
    }
    .summary-row.final {
      font-size: 20px;
      font-weight: 700;
      color: #DE332A;
      padding-top: 16px;
      margin-top: 8px;
      border-top: 2px solid #DE332A;
    }
    .notes {
      background: #F3F4F6;
      padding: 20px;
      border-radius: 8px;
      font-size: 13px;
      color: #4B5563;
    }
    .notes h4 {
      font-size: 14px;
      font-weight: 600;
      margin-bottom: 12px;
      color: #374151;
    }
    .notes ul {
      padding-left: 20px;
    }
    .notes li {
      margin-bottom: 6px;
    }
    .footer {
      margin-top: 40px;
      text-align: center;
      font-size: 12px;
      color: #9CA3AF;
      padding-top: 20px;
      border-top: 1px solid #E5E7EB;
    }
    @media print {
      body {
        padding: 20px;
      }
      .no-print {
        display: none;
      }
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">UNO A</div>
    <h1 class="title">수익 정산서</h1>
    <p class="period">${formatDate(payout.period_start)} ~ ${formatDate(payout.period_end)}</p>
  </div>

  <div class="section">
    <h2 class="section-title">크리에이터 정보</h2>
    <div class="info-grid">
      <span class="info-label">활동명</span>
      <span class="info-value">${payout.creator_profiles.stage_name}</span>
      <span class="info-label">정산 계좌</span>
      <span class="info-value">${payout.bank_name} ${payout.bank_account_last4}</span>
      <span class="info-label">예금주</span>
      <span class="info-value">${payout.account_holder_name}</span>
      <span class="info-label">정산서 발급일</span>
      <span class="info-value">${formatDate(new Date().toISOString())}</span>
    </div>
  </div>

  <div class="section">
    <h2 class="section-title">수익 상세</h2>
    <table>
      <thead>
        <tr>
          <th>항목</th>
          <th class="amount">건수</th>
          <th class="amount">DT</th>
          <th class="amount">금액 (원)</th>
        </tr>
      </thead>
      <tbody>
        ${(payout.payout_line_items || []).map((item: any) => `
        <tr>
          <td>${item.item_type === 'tip' ? '선물 (DT 후원)' : item.item_type === 'private_card' ? '프라이빗 카드' : item.item_type}</td>
          <td class="amount">${formatNumber(item.item_count)}건</td>
          <td class="amount">${formatNumber(item.gross_dt)} DT</td>
          <td class="amount">${formatNumber(item.gross_krw)}원</td>
        </tr>
        `).join('')}
        <tr class="total-row">
          <td>총 수익</td>
          <td class="amount">-</td>
          <td class="amount">${formatNumber(payout.gross_dt)} DT</td>
          <td class="amount">${formatNumber(payout.gross_krw)}원</td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="section">
    <h2 class="section-title">정산 내역</h2>
    <div class="summary-box">
      <div class="summary-row">
        <span>총 수익</span>
        <span>${formatNumber(payout.gross_krw)}원</span>
      </div>
      <div class="summary-row">
        <span>플랫폼 수수료 (${(payout.platform_fee_rate * 100).toFixed(0)}%)</span>
        <span>-${formatNumber(payout.platform_fee_krw)}원</span>
      </div>
      <div class="summary-row">
        <span>원천징수세 (${(payout.withholding_tax_rate * 100).toFixed(1)}%)</span>
        <span>-${formatNumber(payout.withholding_tax_krw)}원</span>
      </div>
      <div class="summary-row final">
        <span>실수령액</span>
        <span>${formatNumber(payout.net_krw)}원</span>
      </div>
    </div>
  </div>

  <div class="notes">
    <h4>정산 안내</h4>
    <ul>
      <li>원천징수세 ${(payout.withholding_tax_rate * 100).toFixed(1)}%는 기타소득세 (3%) + 지방소득세 (0.3%)로 구성됩니다.</li>
      <li>정산금은 매월 10일 (공휴일인 경우 다음 영업일)에 지급됩니다.</li>
      <li>최소 정산 금액은 10,000원입니다.</li>
      <li>본 정산서는 세금 신고용 증빙자료로 활용하실 수 있습니다.</li>
      <li>문의사항은 고객센터로 연락해 주세요.</li>
    </ul>
  </div>

  <div class="footer">
    <p>본 정산서는 UNO A에서 자동 발급되었습니다.</p>
    <p>정산서 ID: ${payout.id}</p>
    <p>&copy; ${new Date().getFullYear()} UNO A. All rights reserved.</p>
  </div>
</body>
</html>
    `.trim()

    // Store statement URL
    const fileName = `statements/${payout.id}.html`

    // Upload to Supabase Storage
    const { error: uploadError } = await supabase.storage
      .from('payouts')
      .upload(fileName, html, {
        contentType: 'text/html',
        upsert: true,
      })

    if (uploadError) {
      console.error('Failed to upload statement:', uploadError)
      // Continue anyway - return the HTML directly
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from('payouts')
      .getPublicUrl(fileName)

    // Update payout with statement URL
    await supabase
      .from('payouts')
      .update({
        statement_pdf_url: urlData.publicUrl,
        statement_generated_at: new Date().toISOString(),
      })
      .eq('id', payoutId)

    return new Response(
      JSON.stringify({
        success: true,
        payoutId,
        statementUrl: urlData.publicUrl,
        html, // Also return raw HTML for client-side PDF generation
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Statement generation error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
