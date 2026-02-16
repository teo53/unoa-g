# UNO A - Architecture Documentation

## 개요

UNO A는 팬과 크리에이터를 연결하는 1:1 프리미엄 채팅 플랫폼입니다. 이 문서는 시스템 아키텍처와 주요 설계 결정을 설명합니다.

## 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Client Apps                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │   Android   │    │     iOS     │    │     Web     │                 │
│  │   Flutter   │    │   Flutter   │    │   Flutter   │                 │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                 │
│         │                  │                  │                         │
│         └──────────────────┼──────────────────┘                         │
│                            │                                            │
│                            ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Flutter App Architecture                      │   │
│  │                                                                  │   │
│  │   ┌─────────────────────────────────────────────────────────┐   │   │
│  │   │                      UI Layer                            │   │   │
│  │   │  Screens → Widgets → Navigation (GoRouter)               │   │   │
│  │   └───────────────────────────┬─────────────────────────────┘   │   │
│  │                               │                                  │   │
│  │   ┌───────────────────────────▼─────────────────────────────┐   │   │
│  │   │                   State Management                       │   │   │
│  │   │  Providers (Riverpod) → Notifiers → State Objects        │   │   │
│  │   └───────────────────────────┬─────────────────────────────┘   │   │
│  │                               │                                  │   │
│  │   ┌───────────────────────────▼─────────────────────────────┐   │   │
│  │   │                   Business Logic                         │   │   │
│  │   │  Services → Validation → Business Rules                  │   │   │
│  │   └───────────────────────────┬─────────────────────────────┘   │   │
│  │                               │                                  │   │
│  │   ┌───────────────────────────▼─────────────────────────────┐   │   │
│  │   │                    Data Layer                            │   │   │
│  │   │  Repositories → Models → DTOs                            │   │   │
│  │   └───────────────────────────┬─────────────────────────────┘   │   │
│  └───────────────────────────────┼─────────────────────────────────┘   │
│                                  │                                      │
└──────────────────────────────────┼──────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          Supabase Backend                               │
│                                                                         │
│   ┌───────────────────┐  ┌───────────────────┐  ┌─────────────────┐   │
│   │    PostgreSQL     │  │   Supabase Auth   │  │ Supabase Storage│   │
│   │                   │  │                   │  │                 │   │
│   │  - user_profiles  │  │  - Email/Password │  │  - Avatars      │   │
│   │  - channels       │  │  - Kakao OAuth    │  │  - Media files  │   │
│   │  - subscriptions  │  │  - Apple Sign In  │  │  - Voice msgs   │   │
│   │  - messages       │  │  - Google OAuth   │  │                 │   │
│   │  - wallets        │  │                   │  └─────────────────┘   │
│   │  - dt_donations   │  └───────────────────┘                        │
│   │  - ledger_entries │                                               │
│   │  - reply_quota    │  ┌───────────────────┐  ┌─────────────────┐   │
│   └───────────────────┘  │ Supabase Realtime │  │  Edge Functions │   │
│                          │                   │  │                 │   │
│                          │  - Chat messages  │  │  - payment-     │   │
│                          │  - Presence       │  │    checkout     │   │
│                          │  - Typing         │  │  - payment-     │   │
│                          │                   │  │    webhook      │   │
│                          └───────────────────┘  │  - settlement   │   │
│                                                 │    -batch       │   │
│                                                 └─────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       External Services                                  │
│                                                                         │
│   ┌───────────────────┐  ┌───────────────────┐  ┌─────────────────┐   │
│   │   TossPayments    │  │   Push Services   │  │    OAuth        │   │
│   │                   │  │                   │  │                 │   │
│   │  - 결제 처리       │  │  - FCM (Android)  │  │  - Kakao        │   │
│   │  - Webhook        │  │  - APNs (iOS)     │  │  - Google       │   │
│   │  - 정산           │  │                   │  │  - Apple        │   │
│   └───────────────────┘  └───────────────────┘  └─────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

## 레이어별 책임

### 1. UI Layer (lib/features/)

| 컴포넌트 | 책임 |
|---------|------|
| Screen | 전체 페이지 레이아웃, 라우팅 |
| Widget | 재사용 가능한 UI 컴포넌트 |
| GoRouter | 딥링크, 네비게이션 관리 |

### 2. State Management (lib/providers/)

| 컴포넌트 | 책임 |
|---------|------|
| StateNotifier | 상태 변경 로직 캡슐화 |
| Provider | 의존성 주입, 상태 읽기 |
| FutureProvider | 비동기 데이터 페칭 |

### 3. Business Logic (lib/data/services/)

| 서비스 | 책임 |
|--------|------|
| ChatService | 답장 유효성, 글자수 제한, 스팸 필터 |
| WalletService | 후원 분배 계산, 환불 정책 검증 |
| NotificationService | 알림 포맷팅, 채널 분류 |

### 4. Data Layer (lib/data/)

| 컴포넌트 | 책임 |
|---------|------|
| Repository | 데이터 소스 추상화 |
| Model | 도메인 객체 정의 |
| DTO | API 요청/응답 변환 |

## 데이터 모델

### 핵심 엔티티 관계

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   User      │      │   Channel   │      │   Message   │
│  Profile    │──┐   │             │   ┌──│             │
└─────────────┘  │   └─────────────┘   │  └─────────────┘
                 │         │           │
                 │         │           │
                 ▼         ▼           │
            ┌─────────────────┐        │
            │  Subscription   │        │
            │                 │────────┘
            └─────────────────┘
                 │
                 │
                 ▼
            ┌─────────────┐      ┌─────────────┐
            │ ReplyQuota  │      │   Wallet    │
            │             │      │             │
            └─────────────┘      └─────────────┘
                                       │
                                       │
                                       ▼
                                 ┌─────────────┐
                                 │  Donation   │
                                 │             │
                                 └─────────────┘
```

### 모델 분류

#### 인증/권한 모델
- **UserAuthProfile**: 로그인, 역할, 권한 관리
- **AuthState**: 인증 상태 (로딩, 인증됨, 미인증, 에러)

#### UI 표시 모델
- **UserDisplayProfile**: 프로필 카드, 구독 정보 표시
- **ChatThreadData**: 채팅 목록 표시

#### 비즈니스 모델
- **Channel**: 크리에이터 채널
- **Subscription**: 구독 관계
- **BroadcastMessage**: 채팅 메시지
- **ReplyQuota**: 일일 답장 쿼터

#### 결제 모델
- **Wallet**: 사용자 DT 잔액
- **DtPackage**: 구매 패키지
- **LedgerEntry**: 거래 내역

## 주요 플로우

### 1. 인증 플로우

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  User   │────▶│  AuthScreen │────▶│ AuthService │────▶│  Supabase   │
│         │     │             │     │             │     │    Auth     │
└─────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                      │                   │                    │
                      │                   │                    │
                      ▼                   ▼                    ▼
                ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
                │ AuthProvider│◀────│ AuthNotifier│◀────│   Session   │
                │  (State)    │     │             │     │   Token     │
                └─────────────┘     └─────────────┘     └─────────────┘
                      │
                      │
                      ▼
                ┌─────────────┐
                │   GoRouter  │
                │ (Redirect)  │
                └─────────────┘
```

### 2. 채팅 플로우

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐
│  User   │────▶│ ChatScreen  │────▶│ChatProvider │
│ (Send)  │     │             │     │             │
└─────────┘     └─────────────┘     └─────────────┘
                                          │
                      ┌───────────────────┼───────────────────┐
                      │                   │                   │
                      ▼                   ▼                   ▼
               ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
               │ ChatService │     │   Supabase  │     │  Realtime   │
               │ (Validate)  │     │   (Insert)  │     │ (Broadcast) │
               └─────────────┘     └─────────────┘     └─────────────┘
                      │                   │                   │
                      │                   └───────┬───────────┘
                      │                           │
                      ▼                           ▼
               ┌─────────────┐            ┌─────────────┐
               │ ReplyQuota  │            │   Other     │
               │ (Decrement) │            │   Users     │
               └─────────────┘            └─────────────┘
```

### 3. 결제 플로우

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  User   │────▶│ WalletScreen│────▶│   payment-  │────▶│TossPayments │
│ (Buy DT)│     │             │     │   checkout  │     │             │
└─────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                                              │
                                                              │ (Redirect)
                                                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          TossPayments Checkout                          │
│                     (User completes payment)                            │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                                    │ (Webhook)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          payment-webhook                                 │
│                                                                         │
│  1. Verify signature (HMAC-SHA256)                                      │
│  2. Check idempotency (order already processed?)                        │
│  3. Call atomic transaction:                                            │
│     - Update purchase status                                            │
│     - Create ledger entry                                               │
│     - Update wallet balance                                             │
│  4. Return success/failure                                              │
└─────────────────────────────────────────────────────────────────────────┘
```

## 보안 설계

### Row Level Security (RLS)

```sql
-- 사용자는 자신의 프로필만 수정 가능
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- 구독자만 채널 메시지 조회 가능
CREATE POLICY "Subscribers can view channel messages"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM subscriptions
      WHERE user_id = auth.uid()
        AND channel_id = messages.channel_id
        AND is_active = true
    )
  );
```

### 결제 보안

1. **Webhook 서명 검증**: HMAC-SHA256으로 요청 진위 확인
2. **멱등성 처리**: 동일 orderId 중복 처리 방지
3. **원자적 트랜잭션**: PostgreSQL Function으로 데이터 일관성 보장

### 민감정보 암호화

```sql
-- pgcrypto를 사용한 컬럼 레벨 암호화
ALTER TABLE creator_payout_info
  ALTER COLUMN bank_account
  SET DATA TYPE bytea
  USING pgp_sym_encrypt(bank_account::text, current_setting('app.encryption_key'));
```

## 성능 최적화

### 데이터베이스 인덱스

```sql
-- 채팅 메시지 조회 최적화
CREATE INDEX idx_messages_channel_time
  ON messages(channel_id, created_at DESC);

-- 구독 상태 조회 최적화
CREATE INDEX idx_subscriptions_user_active
  ON subscriptions(user_id, is_active)
  WHERE is_active = true;
```

### 클라이언트 캐싱

- **CachedNetworkImage**: 아바타, 미디어 이미지 캐싱
- **SharedPreferences**: 사용자 설정, 테마 캐싱
- **Riverpod StateNotifier**: 메모리 내 상태 캐싱

### 실시간 최적화

- **Presence 채널**: 온라인 상태 공유
- **메시지 페이지네이션**: 초기 50개만 로드, 스크롤 시 추가 로드
- **Debounced 타이핑**: 타이핑 인디케이터 debounce

## 확장성 고려사항

### 현재 지원

- 팬-크리에이터 1:1 채팅
- 구독 기반 수익 모델
- DT 후원 시스템
- 한국어 UI

### 향후 확장 가능

- **그룹 채팅**: messages 테이블에 group_id 추가
- **다국어**: intl 패키지 + 언어 리소스 파일
- **해외 결제**: Stripe 연동
- **크리에이터 대시보드**: 별도 웹 앱

## 모니터링 및 로깅

### 에러 처리

```dart
// lib/core/services/error_service.dart
class ErrorService {
  static void logError(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint('[$context] Error: $error');
    if (kDebugMode && stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
    // TODO: Sentry 연동
  }
}
```

### 추천 모니터링 도구

- **Sentry**: 런타임 에러 트래킹
- **Firebase Analytics**: 사용자 행동 분석
- **Supabase Dashboard**: 데이터베이스 모니터링

## 배포

### Android

```bash
# 릴리즈 빌드
flutter build apk --release

# App Bundle (Google Play)
flutter build appbundle --release
```

### iOS

```bash
# 릴리즈 빌드
flutter build ios --release

# Archive (App Store Connect)
# Xcode에서 Product > Archive
```

### Supabase

```bash
# Edge Functions 배포
supabase functions deploy payment-checkout
supabase functions deploy payment-webhook
supabase functions deploy settlement-batch

# 마이그레이션 적용
supabase db push
```
