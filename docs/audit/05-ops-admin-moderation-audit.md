# 05. 운영/어드민/모더레이션 감사 (Ops, Admin & Moderation Audit)

## 1. 요약

| 영역 | 현재 상태 | 위험도 |
|------|----------|--------|
| 어드민 패널 | ❌ 미구현 | 🔴 HIGH |
| 신고 처리 | ❌ 미구현 | 🔴 HIGH |
| 사용자 제재 | ⚠️ 필드만 | 🟡 MEDIUM |
| 콘텐츠 모더레이션 | ❌ 미구현 | 🔴 HIGH |
| 감사 추적 | ⚠️ 테이블만 | 🟡 MEDIUM |
| CS 운영 도구 | ❌ 미구현 | 🟡 MEDIUM |

**결론**: 현재 상태로는 **실서비스 운영 불가**. 최소한의 어드민/모더레이션 도구 필수.

---

## 2. 어드민 패널 현황

### 2.1 현재 상태

```
Next.js apps/web 구조:
├── app/
│   ├── (public)/         # 공개 페이지
│   │   ├── funding/      # 펀딩 목록/상세
│   │   └── creator/      # 크리에이터 프로필
│   ├── (studio)/         # 크리에이터 스튜디오
│   │   └── studio/       # 캠페인 관리
│   └── (admin)/          # ❌ 비어있음
│       └── admin/        # ❌ 미구현
```

### 2.2 필요한 어드민 기능

#### Phase 1 MVP (런칭 전 필수)

```
┌─────────────────────────────────────────────────────────────┐
│                     어드민 대시보드                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   심사 큐     │  │   신고 큐     │  │   정산 큐     │      │
│  │   23건 대기   │  │   8건 대기    │  │   5건 대기    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ 실시간 지표                                            │ │
│  │ • 일일 활성 사용자: 1,234                              │ │
│  │ • 오늘 신규 가입: 56                                   │ │
│  │ • 오늘 결제액: ₩2,345,000                             │ │
│  │ • 진행중 캠페인: 12                                    │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

#### 심사 큐 (캠페인 승인)

```typescript
interface CampaignReview {
  // 캠페인 정보
  campaignId: string;
  creatorId: string;
  creatorName: string;
  title: string;
  description: string;
  targetAmount: number;
  category: string;

  // 심사 정보
  submittedAt: Date;
  status: 'pending' | 'approved' | 'rejected' | 'revision_requested';

  // 히스토리
  reviewHistory: ReviewAction[];
}

interface ReviewAction {
  reviewerId: string;
  action: 'approve' | 'reject' | 'request_revision';
  reason?: string;
  timestamp: Date;
}
```

#### 신고 트리아지

```typescript
interface ReportTicket {
  id: string;
  reporterId: string;
  reportedUserId?: string;
  reportedContentId?: string;
  reportedContentType: 'message' | 'profile' | 'campaign';

  reason: ReportReason;
  description?: string;

  status: 'open' | 'in_progress' | 'resolved' | 'dismissed';
  priority: 'low' | 'medium' | 'high' | 'critical';

  assignedTo?: string;
  resolution?: Resolution;

  createdAt: Date;
  updatedAt: Date;
}

enum ReportReason {
  SPAM = 'spam',
  HARASSMENT = 'harassment',
  INAPPROPRIATE_CONTENT = 'inappropriate_content',
  FRAUD = 'fraud',
  COPYRIGHT = 'copyright',
  OTHER = 'other',
}

interface Resolution {
  action: 'no_action' | 'warning' | 'content_removed' | 'user_suspended' | 'user_banned';
  note: string;
  resolvedBy: string;
  resolvedAt: Date;
}
```

#### 사용자 제재 관리

```typescript
interface UserSanction {
  userId: string;
  sanctionType: 'warning' | 'suspension' | 'ban';

  // 정지인 경우
  suspensionEndDate?: Date;

  reason: string;
  issuedBy: string;
  issuedAt: Date;

  // 이의제기
  appeal?: {
    content: string;
    submittedAt: Date;
    status: 'pending' | 'approved' | 'rejected';
    reviewedBy?: string;
    reviewNote?: string;
  };
}
```

---

## 3. 신고/차단 시스템 설계

### 3.1 데이터베이스 스키마 (추가 필요)

```sql
-- 신고 테이블
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES auth.users(id) NOT NULL,

  -- 신고 대상
  reported_user_id UUID REFERENCES auth.users(id),
  reported_content_id UUID,
  reported_content_type TEXT CHECK (reported_content_type IN (
    'message', 'profile', 'campaign', 'comment'
  )),

  -- 신고 내용
  reason report_reason NOT NULL,
  description TEXT,

  -- 처리 상태
  status report_status DEFAULT 'open',
  priority report_priority DEFAULT 'medium',
  assigned_to UUID REFERENCES auth.users(id),

  -- 해결
  resolution_action TEXT,
  resolution_note TEXT,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 차단 테이블
CREATE TABLE user_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID REFERENCES auth.users(id) NOT NULL,
  blocked_id UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(blocker_id, blocked_id)
);

-- 제재 테이블
CREATE TABLE user_sanctions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  sanction_type sanction_type NOT NULL,
  reason TEXT NOT NULL,

  -- 정지 기간 (suspension인 경우)
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  ends_at TIMESTAMPTZ,

  issued_by UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- 이의제기
  appeal_content TEXT,
  appeal_status appeal_status,
  appeal_reviewed_by UUID REFERENCES auth.users(id),
  appeal_note TEXT
);

-- Enum 타입들
CREATE TYPE report_reason AS ENUM (
  'spam', 'harassment', 'inappropriate_content',
  'fraud', 'copyright', 'other'
);

CREATE TYPE report_status AS ENUM (
  'open', 'in_progress', 'resolved', 'dismissed'
);

CREATE TYPE report_priority AS ENUM (
  'low', 'medium', 'high', 'critical'
);

CREATE TYPE sanction_type AS ENUM (
  'warning', 'suspension', 'ban'
);

CREATE TYPE appeal_status AS ENUM (
  'pending', 'approved', 'rejected'
);
```

### 3.2 RLS 정책

```sql
-- reports 테이블
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- 사용자는 본인의 신고만 조회/생성
CREATE POLICY "users_own_reports" ON reports
  FOR SELECT USING (reporter_id = auth.uid());

CREATE POLICY "users_create_reports" ON reports
  FOR INSERT WITH CHECK (reporter_id = auth.uid());

-- 어드민은 모든 신고 조회/처리
CREATE POLICY "admin_all_reports" ON reports
  FOR ALL USING (
    auth.uid() IN (SELECT id FROM user_profiles WHERE role = 'admin')
  );

-- user_blocks 테이블
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- 사용자는 본인의 차단 목록만 관리
CREATE POLICY "users_own_blocks" ON user_blocks
  FOR ALL USING (blocker_id = auth.uid());

-- user_sanctions 테이블
ALTER TABLE user_sanctions ENABLE ROW LEVEL SECURITY;

-- 어드민만 제재 관리
CREATE POLICY "admin_sanctions" ON user_sanctions
  FOR ALL USING (
    auth.uid() IN (SELECT id FROM user_profiles WHERE role = 'admin')
  );

-- 사용자는 본인 제재 조회만
CREATE POLICY "users_view_own_sanctions" ON user_sanctions
  FOR SELECT USING (user_id = auth.uid());
```

### 3.3 Flutter UI 구현 (필요)

```dart
// lib/features/moderation/widgets/report_dialog.dart

class ReportDialog extends StatefulWidget {
  final String? reportedUserId;
  final String? reportedContentId;
  final String reportedContentType;

  // ...
}

// 신고 사유 선택
enum ReportReason {
  spam('스팸'),
  harassment('괴롭힘/폭언'),
  inappropriateContent('부적절한 콘텐츠'),
  fraud('사기/허위 정보'),
  copyright('저작권 침해'),
  other('기타');

  final String label;
  const ReportReason(this.label);
}

// lib/features/chat/widgets/message_actions_sheet.dart

class MessageActionsSheet extends StatelessWidget {
  final BroadcastMessage message;
  final bool isOwnMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isOwnMessage) ...[
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('편집'),
            onTap: () => _editMessage(context),
          ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('삭제'),
            onTap: () => _deleteMessage(context),
          ),
        ],
        if (!isOwnMessage) ...[
          ListTile(
            leading: Icon(Icons.flag),
            title: Text('신고'),
            onTap: () => _reportMessage(context),
          ),
          ListTile(
            leading: Icon(Icons.block),
            title: Text('차단'),
            onTap: () => _blockUser(context),
          ),
        ],
      ],
    );
  }
}
```

---

## 4. 콘텐츠 모더레이션

### 4.1 자동 필터링 (Phase 2)

```typescript
// 욕설/비속어 필터
interface ContentFilter {
  checkMessage(content: string): FilterResult;
  checkProfile(profile: UserProfile): FilterResult;
  checkCampaign(campaign: Campaign): FilterResult;
}

interface FilterResult {
  passed: boolean;
  flags: ContentFlag[];
  severity: 'none' | 'low' | 'medium' | 'high';
  suggestedAction: 'allow' | 'review' | 'block';
}

enum ContentFlag {
  PROFANITY = 'profanity',
  ADULT_CONTENT = 'adult_content',
  VIOLENCE = 'violence',
  SPAM_PATTERN = 'spam_pattern',
  SUSPICIOUS_LINKS = 'suspicious_links',
}
```

### 4.2 이미지/영상 검수 (Phase 2)

```typescript
// AWS Rekognition 또는 Google Vision API 연동
interface MediaModeration {
  scanImage(imageUrl: string): Promise<ModerationResult>;
  scanVideo(videoUrl: string): Promise<ModerationResult>;
}

interface ModerationResult {
  safe: boolean;
  labels: ModerationLabel[];
  confidence: number;
}
```

### 4.3 Edge Function 훅 (Phase 1)

```typescript
// supabase/functions/content-filter/index.ts

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// 한국어 욕설 사전 (기본)
const PROFANITY_LIST = [
  // ... 욕설 목록 (외부 파일로 분리)
];

serve(async (req) => {
  const { content, contentType } = await req.json();

  // 기본 욕설 체크
  const containsProfanity = PROFANITY_LIST.some(word =>
    content.toLowerCase().includes(word)
  );

  // 스팸 패턴 체크
  const spamPatterns = [
    /(.)\1{10,}/,           // 같은 문자 10번 이상 반복
    /https?:\/\/[^\s]+/g,   // URL 포함 (검토 대상)
    /\d{3,}-\d{3,}-\d{4,}/, // 전화번호 패턴
  ];

  const isSpam = spamPatterns.some(pattern => pattern.test(content));

  return new Response(JSON.stringify({
    passed: !containsProfanity && !isSpam,
    flags: {
      profanity: containsProfanity,
      spam: isSpam,
    },
    severity: containsProfanity ? 'high' : (isSpam ? 'medium' : 'none'),
  }));
});
```

---

## 5. 앱스토어 정책 컴플라이언스

### 5.1 Apple App Store

| 요구사항 | 현재 상태 | 조치 필요 |
|----------|----------|----------|
| 디지털 상품은 IAP 사용 | ⚠️ TossPayments 사용 중 | **검토 필요** |
| 신고/차단 기능 | ❌ 미구현 | **필수 구현** |
| 개인정보 처리 고지 | ❌ 미구현 | **필수 구현** |
| 연령 제한 (17+) | ⚠️ 구현됨 | 약관 확인 |
| 콘텐츠 모더레이션 | ❌ 미구현 | **필수 구현** |

**주요 리스크**:
- DT 구매가 IAP 우회로 해석될 수 있음
- 팬-아티스트 DM 플랫폼은 UGC 정책 적용
- 신고/차단 없으면 심사 거절 가능

### 5.2 Google Play Store

| 요구사항 | 현재 상태 | 조치 필요 |
|----------|----------|----------|
| Billing Library 사용 | ⚠️ TossPayments 사용 중 | **검토 필요** |
| 콘텐츠 정책 준수 | ❌ 모더레이션 없음 | **필수 구현** |
| 데이터 안전 섹션 | ❌ 미작성 | **필수 작성** |
| 광고 ID 사용 고지 | 미확인 | 확인 필요 |

### 5.3 결제 정책 대안

```
옵션 A: 웹에서만 DT 구매
├── 장점: IAP 수수료(30%) 회피
├── 단점: 사용자 경험 저하
└── 구현: 앱에서 웹으로 리다이렉트

옵션 B: IAP + 웹 결제 병행
├── 장점: 스토어 정책 준수
├── 단점: 30% 수수료 (앱 내 결제)
└── 구현: in_app_purchase 패키지 추가

옵션 C: 크리에이터 직접 결제
├── 장점: 스토어 정책 우회 가능
├── 단점: 구현 복잡도
└── 구현: 후원 시 크리에이터 페이팔/계좌 직접 연결
```

---

## 6. CS 운영 도구

### 6.1 필요한 기능

```
CS 어드민 패널
├── 사용자 조회
│   ├── 프로필 정보
│   ├── 구독 내역
│   ├── 결제 내역
│   ├── 신고 이력
│   └── 제재 이력
│
├── 문의 관리
│   ├── 문의 목록
│   ├── 답변 작성
│   ├── 템플릿 관리
│   └── 에스컬레이션
│
├── 환불 처리
│   ├── 환불 요청 목록
│   ├── 환불 승인/거절
│   └── 부분 환불
│
└── 통계
    ├── 문의 유형별 통계
    ├── 응답 시간 SLA
    └── 해결률
```

### 6.2 CS 템플릿 (예시)

```typescript
const CS_TEMPLATES = {
  refund_approved: {
    subject: '환불 처리 완료 안내',
    body: `안녕하세요, {{userName}}님.

요청하신 환불이 정상적으로 처리되었습니다.

- 환불 금액: {{amount}}원
- 처리 일시: {{processedAt}}
- 환불 방법: 원 결제 수단

실제 환불까지 결제사 정책에 따라 3-5영업일 소요될 수 있습니다.

추가 문의사항이 있으시면 언제든 연락 주세요.

감사합니다.
UNO A 고객센터`,
  },

  report_resolved: {
    subject: '신고 처리 결과 안내',
    body: `안녕하세요, {{userName}}님.

접수해 주신 신고가 검토 완료되었습니다.

- 신고 번호: {{reportId}}
- 처리 결과: {{resolution}}

커뮤니티 가이드라인 준수에 협조해 주셔서 감사합니다.

UNO A 운영팀`,
  },
};
```

### 6.3 SLA 정의

| 우선순위 | 첫 응답 | 해결 목표 |
|----------|---------|----------|
| Critical (결제 오류) | 1시간 | 4시간 |
| High (계정 문제) | 4시간 | 24시간 |
| Medium (기능 문의) | 24시간 | 72시간 |
| Low (일반 문의) | 48시간 | 1주일 |

---

## 7. 감사 추적 (Audit Trail)

### 7.1 현재 테이블

```sql
-- 이미 존재
CREATE TABLE admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL,
  target_type TEXT,
  target_id UUID,
  details JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 7.2 필요한 로깅 이벤트

| 이벤트 | action 값 | target_type | 필수 details |
|--------|----------|-------------|-------------|
| 캠페인 승인 | `campaign.approve` | `campaign` | `{reason}` |
| 캠페인 반려 | `campaign.reject` | `campaign` | `{reason}` |
| 사용자 경고 | `user.warning` | `user` | `{reason}` |
| 사용자 정지 | `user.suspend` | `user` | `{reason, days}` |
| 사용자 영구정지 | `user.ban` | `user` | `{reason}` |
| 환불 승인 | `payment.refund` | `payment` | `{amount, orderId}` |
| 정산 승인 | `payout.approve` | `payout` | `{amount}` |
| 신고 해결 | `report.resolve` | `report` | `{resolution}` |
| 콘텐츠 삭제 | `content.delete` | `message/campaign` | `{reason}` |

### 7.3 로깅 함수

```sql
CREATE OR REPLACE FUNCTION log_admin_action(
  p_action TEXT,
  p_target_type TEXT,
  p_target_id UUID,
  p_details JSONB DEFAULT '{}'::JSONB
) RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO admin_audit_log (
    admin_user_id,
    action,
    target_type,
    target_id,
    details
  ) VALUES (
    auth.uid(),
    p_action,
    p_target_type,
    p_target_id,
    p_details
  ) RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 8. 구현 우선순위

### Phase 0 (즉시)
- [ ] `admin_audit_log` INSERT 정책 수정

### Phase 1 (런칭 전)
- [ ] 신고 테이블 및 RLS 추가
- [ ] 차단 테이블 및 RLS 추가
- [ ] Flutter 신고/차단 다이얼로그
- [ ] 차단된 사용자 메시지 필터링
- [ ] 어드민 대시보드 MVP (심사 큐)
- [ ] 기본 욕설 필터 Edge Function

### Phase 2 (런칭 후)
- [ ] CS 티켓 시스템
- [ ] 이미지/영상 자동 검수
- [ ] 고급 스팸 필터
- [ ] 사용자 제재 이의제기 시스템
- [ ] SLA 대시보드
