# 04. 보안/개인정보/결제 감사 (Security, Privacy & Payments Audit)

## 1. 요약

| 영역 | 등급 | 주요 발견 |
|------|------|----------|
| RLS (Row-Level Security) | ✅ A | 15/15 테이블 적용, 1건 정책 수정 필요 |
| 암호화 | ⚠️ B | AES-256-GCM 적용, fallback 키 하드코딩 문제 |
| 웹훅 보안 | ✅ A | 서명검증, idempotency 구현됨 |
| 키 관리 | ⚠️ C | Service Role Key 안전, 암호화 키 관리 개선 필요 |
| 결제 처리 | ⚠️ B | 기본 구조 좋음, 환불/실패 처리 미완 |
| Rate Limiting | ❌ F | 미구현 |

---

## 2. 🔴 CRITICAL 이슈

### 2.1 암호화 키 하드코딩 (CRITICAL)

**위치**: `supabase/migrations/011_encrypt_sensitive_data.sql`

```sql
-- Lines 50-58
CREATE OR REPLACE FUNCTION get_encryption_key()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('app.encryption_key', true),
    'DEVELOPMENT_KEY_DO_NOT_USE_IN_PRODUCTION_32B!'  -- ⚠️ CRITICAL
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;
```

**문제점**:
- 프로덕션에서 `app.encryption_key` 미설정 시 개발용 키로 fallback
- 개발용 키가 코드에 노출되어 있음
- 이 키로 암호화된 데이터는 누구나 복호화 가능

**영향받는 데이터**:
- `creator_payout_accounts.bank_account_number_encrypted`
- `creator_payout_accounts.resident_registration_number_encrypted` (있을 경우)

**수정 방안**:
```sql
CREATE OR REPLACE FUNCTION get_encryption_key()
RETURNS TEXT AS $$
DECLARE
  key TEXT;
BEGIN
  key := current_setting('app.encryption_key', true);
  IF key IS NULL OR key = '' THEN
    RAISE EXCEPTION 'CRITICAL: app.encryption_key not configured';
  END IF;
  RETURN key;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
```

---

### 2.2 감사로그 INSERT 정책 과다허용 (HIGH)

**위치**: `supabase/migrations/014_admin_policies.sql` (line 230)

```sql
-- 현재 정책
CREATE POLICY "admin_audit_insert" ON admin_audit_log
  FOR INSERT WITH CHECK (true);  -- ⚠️ 누구나 삽입 가능
```

**문제점**:
- 인증되지 않은 사용자도 가짜 감사로그 삽입 가능
- 감사 추적의 무결성 훼손
- 악의적 행위자가 로그 오염 가능

**수정 방안**:
```sql
CREATE POLICY "admin_audit_insert" ON admin_audit_log
  FOR INSERT WITH CHECK (
    auth.jwt()->>'role' = 'service_role'
    OR auth.uid() IN (
      SELECT id FROM user_profiles WHERE role = 'admin'
    )
  );
```

---

## 3. RLS 정책 전수 점검

### 3.1 테이블별 RLS 상태

| 테이블 | RLS 활성화 | SELECT | INSERT | UPDATE | DELETE |
|--------|-----------|--------|--------|--------|--------|
| user_profiles | ✅ | user_own + admin | user_own | user_own + admin | - |
| channels | ✅ | public(active) | artist_own | artist_own | - |
| subscriptions | ✅ | user_own + artist_channel + admin | service_role | user_own | - |
| messages | ✅ | subscribed + own + admin | authenticated | sender_own | - |
| message_delivery | ✅ | user_own | service_role | user_own | - |
| reply_quota | ✅ | user_own + admin | service_role | service_role | - |
| policy_config | ✅ | public(active) | admin | admin | - |
| creator_payout_accounts | ✅ | creator_own | creator_own | service_role | - |
| creator_profiles | ✅ | user_own + admin | creator_own | creator_own | - |
| wallets | ✅ | user_own + admin | service_role | service_role | - |
| dt_purchases | ✅ | user_own + admin | service_role | admin | - |
| ledger_entries | ✅ | user_own + admin | service_role | - | - |
| dt_donations | ✅ | user_own + admin | service_role | - | - |
| admin_audit_log | ✅ | admin | **anyone** ⚠️ | - | - |
| sensitive_data_access_log | ✅ | admin | service_role | - | - |
| payment_webhook_logs | ✅ | service_role | service_role | - | - |

### 3.2 RLS 정책 상세 분석

#### messages 테이블 정책

```sql
-- SELECT: 구독한 채널의 브로드캐스트 + 본인 메시지 + 본인에게 온 메시지
CREATE POLICY "messages_select" ON messages FOR SELECT USING (
  -- 브로드캐스트는 구독자에게만
  (delivery_scope = 'broadcast' AND channel_id IN (
    SELECT channel_id FROM subscriptions
    WHERE user_id = auth.uid() AND is_active = true
  ))
  OR
  -- 본인이 보낸 메시지
  sender_id = auth.uid()
  OR
  -- 본인에게 온 1:1 메시지 (donation_reply)
  (delivery_scope = 'donation_reply' AND recipient_id = auth.uid())
  OR
  -- 어드민
  auth.jwt()->>'role' = 'admin'
);

-- INSERT: 인증된 사용자만, 자신의 sender_id로만
CREATE POLICY "messages_insert" ON messages FOR INSERT WITH CHECK (
  auth.uid() IS NOT NULL
  AND sender_id = auth.uid()
);

-- UPDATE: 본인 메시지만 (편집용)
CREATE POLICY "messages_update" ON messages FOR UPDATE USING (
  sender_id = auth.uid()
);
```

#### wallets 테이블 정책

```sql
-- SELECT: 본인 지갑만
CREATE POLICY "wallets_select" ON wallets FOR SELECT USING (
  user_id = auth.uid()
  OR auth.jwt()->>'role' = 'service_role'
  OR auth.jwt()->>'role' = 'admin'
);

-- INSERT/UPDATE: service_role만 (웹훅을 통한 결제 처리용)
CREATE POLICY "wallets_modify" ON wallets
  FOR ALL USING (auth.jwt()->>'role' = 'service_role');
```

---

## 4. 서비스 키 노출 점검

### 4.1 Flutter 앱 점검

```bash
# 검색 대상
- lib/**/*.dart
- .env*
- pubspec.yaml
- android/app/src/main/AndroidManifest.xml
- ios/Runner/Info.plist
```

**결과**: ✅ 안전
- `supabase_flutter` 사용: 클라이언트는 anon key만 사용
- Service Role Key 노출 없음
- `.env` 파일 없음 (DemoConfig로 대체)

### 4.2 Next.js 웹 점검

**파일**: `apps/web/.env.example`

```env
# Public (클라이언트 노출)
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...

# Private (서버 전용)
SUPABASE_SERVICE_ROLE_KEY=...  # ✅ NEXT_PUBLIC_ 아님
```

**서버 클라이언트 사용처**:

```typescript
// apps/web/lib/supabase/server.ts
export async function createAdminClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,  // 서버 전용
    { ... }
  );
}
```

**결과**: ⚠️ 개선 권장
- Service Role Key는 서버 전용으로 올바르게 설정됨
- 단, `createAdminClient()`가 모든 서버 컴포넌트에서 호출 가능
- **권장**: API Route에서만 사용하도록 제한

### 4.3 CI/CD 점검

```yaml
# .github/workflows/* 검색 필요
# 현재 CI/CD 설정 파일 미확인
```

**권장 사항**:
- GitHub Secrets에 민감 키 저장
- 빌드 로그에 키 출력 금지
- 환경별 키 분리 (dev/staging/prod)

---

## 5. 웹훅 보안

### 5.1 TossPayments 웹훅

**파일**: `supabase/functions/payment-webhook/index.ts`

```typescript
// 서명 검증 (✅ 구현됨)
function verifySignature(
  payload: string,
  signature: string,
  secretKey: string
): boolean {
  const hmac = crypto.createHmac('sha256', secretKey);
  hmac.update(payload);
  const expectedSignature = hmac.digest('base64');

  // 타이밍 안전 비교 (✅)
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

// Idempotency 체크 (✅ 구현됨)
const { data: existing } = await supabase
  .from('payment_webhook_logs')
  .select('id')
  .eq('event_id', eventId)
  .single();

if (existing) {
  return new Response('Already processed', { status: 200 });
}
```

### 5.2 개선 필요 사항

```typescript
// ⚠️ 개발 환경 바이패스 (라인 21-23)
if (Deno.env.get('ENVIRONMENT') === 'development'
    && Deno.env.get('SKIP_WEBHOOK_SIGNATURE') === 'true') {
  // 서명 검증 생략
}
```

**위험**: 프로덕션에서 실수로 `SKIP_WEBHOOK_SIGNATURE=true` 설정 시 보안 무력화

**수정 방안**:
```typescript
// 개발 환경에서도 바이패스 제거, 대신 테스트 키 사용
const secretKey = Deno.env.get('ENVIRONMENT') === 'development'
  ? Deno.env.get('TOSS_TEST_SECRET_KEY')
  : Deno.env.get('TOSS_SECRET_KEY');
```

---

## 6. 스토리지 보안

### 6.1 버킷 설정 점검

현재 Supabase Storage 설정 확인 필요:

| 버킷 | 용도 | 권장 설정 |
|------|------|----------|
| avatars | 프로필 이미지 | public, 5MB 제한 |
| media | 채팅 미디어 | private, 서명 URL |
| campaigns | 캠페인 이미지 | public, 10MB 제한 |
| payouts | 정산서 PDF | private, 서명 URL |

### 6.2 업로드 보안

```dart
// Flutter 앱에서 업로드 시
// lib/services/media_service.dart 확인 필요

// 권장 검증 사항:
// 1. MIME 타입 검증 (Content-Type 스푸핑 방지)
// 2. 파일 크기 제한 (서버 측)
// 3. 악성 파일 스캔 (선택)
// 4. 파일명 sanitize
```

### 6.3 서명 URL 만료

```typescript
// private 버킷 접근 시
const { data } = await supabase.storage
  .from('payouts')
  .createSignedUrl(path, 60 * 60);  // 1시간 만료
```

**권장**: 민감 파일은 15분 이내 만료

---

## 7. 결제 처리 보안

### 7.1 결제 상태 머신

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│ pending │ ──▶ │ success │ ──▶ │completed│
└─────────┘     └─────────┘     └─────────┘
     │               │
     ▼               ▼
┌─────────┐     ┌─────────┐
│ failed  │     │ refunded│
└─────────┘     └─────────┘
```

### 7.2 Atomic 처리

```sql
-- supabase/migrations/010_atomic_payment.sql
CREATE OR REPLACE FUNCTION process_payment_atomic(
  p_user_id UUID,
  p_amount INTEGER,
  p_idempotency_key TEXT
) RETURNS BOOLEAN AS $$
BEGIN
  -- 트랜잭션 시작 (implicit)

  -- 1. Idempotency 체크
  IF EXISTS (
    SELECT 1 FROM ledger_entries
    WHERE idempotency_key = p_idempotency_key
  ) THEN
    RETURN TRUE;  -- 이미 처리됨
  END IF;

  -- 2. 지갑 업데이트 (Row Lock)
  UPDATE wallets
  SET balance_dt = balance_dt + p_amount,
      lifetime_purchased_dt = lifetime_purchased_dt + p_amount
  WHERE user_id = p_user_id;

  -- 3. 원장 기록
  INSERT INTO ledger_entries (
    wallet_id, amount_dt, entry_type, idempotency_key
  )
  SELECT id, p_amount, 'purchase', p_idempotency_key
  FROM wallets WHERE user_id = p_user_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
```

### 7.3 환불 처리 (미구현)

```typescript
// 필요한 환불 로직
async function processRefund(orderId: string, amount: number) {
  // 1. TossPayments 환불 API 호출
  // 2. 지갑 차감 (atomic)
  // 3. 원장 기록 (entry_type: 'refund')
  // 4. 감사 로그
}
```

---

## 8. Rate Limiting (미구현)

### 8.1 필요한 Rate Limit

| 엔드포인트 | 권장 제한 | 이유 |
|-----------|----------|------|
| payment-webhook | 100/분/IP | 웹훅 flood 방지 |
| identity-verification | 5/분/user | 본인인증 남용 방지 |
| payout-calculate | 10/시간/user | 정산 요청 제한 |
| messages (INSERT) | 30/분/user | 스팸 방지 |

### 8.2 구현 방안

```typescript
// Edge Function에서 Upstash Redis 사용
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(100, "1 m"),
});

export default async function handler(req: Request) {
  const ip = req.headers.get("x-forwarded-for") ?? "anonymous";
  const { success } = await ratelimit.limit(ip);

  if (!success) {
    return new Response("Rate limit exceeded", { status: 429 });
  }
  // ... 처리 계속
}
```

---

## 9. 감사 로그

### 9.1 현재 구현

```sql
-- admin_audit_log 테이블
CREATE TABLE admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  target_type TEXT,        -- 'user', 'campaign', 'payout', etc.
  target_id UUID,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 민감 데이터 접근 로그
CREATE TABLE sensitive_data_access_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  accessed_by UUID REFERENCES auth.users(id),
  accessed_table TEXT,
  accessed_record_id UUID,
  access_type TEXT,        -- 'view', 'decrypt', 'export'
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 9.2 필요한 로깅 이벤트

| 이벤트 | 현재 | 필요 |
|--------|------|------|
| 어드민 로그인 | ❌ | ✅ |
| 캠페인 승인/반려 | ❌ | ✅ |
| 사용자 제재 | ❌ | ✅ |
| 환불 처리 | ❌ | ✅ |
| 정산 승인 | ⚠️ | ✅ |
| 계좌 정보 조회 | ⚠️ | ✅ |
| RLS 정책 변경 | ❌ | ✅ |

---

## 10. 권장 조치 요약

### 즉시 (Phase 0)

1. **암호화 키 fallback 제거**
   - 파일: `supabase/migrations/011_encrypt_sensitive_data.sql`
   - 키 없으면 예외 발생하도록 수정

2. **감사로그 INSERT 정책 수정**
   - 파일: `supabase/migrations/014_admin_policies.sql`
   - service_role 또는 admin만 허용

3. **Service Role Key 사용처 감사**
   - `createAdminClient()` 호출 위치 목록화
   - API Route로 제한

### 단기 (Phase 1)

4. **Rate Limiting 구현**
   - Upstash Redis 또는 Supabase Rate Limit
   - 웹훅, 인증, 메시지 엔드포인트

5. **환불 처리 구현**
   - TossPayments 환불 API 연동
   - Atomic 지갑 차감

6. **에러 메시지 sanitize**
   - 로그에 민감 정보 포함 방지

### 중기 (Phase 2)

7. **API 키 로테이션 절차**
   - 문서화
   - 자동화 스크립트

8. **로그 보존 정책**
   - 금융 거래: 5년 (전자상거래법/세법)
   - 감사 로그: 3년
   - 일반 로그: 1년

9. **CSRF 보호**
   - SameSite 쿠키
   - CSRF 토큰 (어드민)
