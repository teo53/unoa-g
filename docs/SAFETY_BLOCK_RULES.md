# UNO A Safety: Block / Hide / Report Rules

> **문서 버전**: 1.0
> **DB 스키마**: migration 009 (moderation)

---

## 1. 기능 비교

| 기능 | 실행자 | 효과 | 취소 가능 | DB 테이블 |
|------|--------|------|:---------:|----------|
| **신고 (Report)** | 팬/크리에이터 | 운영팀 검토 큐에 추가 | ❌ | `reports` |
| **차단 (Block)** | 팬 | 상대방 메시지 수신 차단 | ✅ 설정에서 | `user_blocks` |
| **숨기기 (Hide)** | 크리에이터 | 팬 메시지를 타임라인에서 숨김 | ✅ 설정에서 | `hidden_fans` |

---

## 2. 신고 (Report)

### 신고 사유
- `inappropriate_content`: 부적절한 콘텐츠
- `harassment`: 괴롭힘/혐오 발언
- `spam`: 스팸/광고
- `impersonation`: 사칭
- `other`: 기타 (상세 사유 필수)

### 신고 플로우
```
팬/크리에이터 → report_dialog.dart → reports 테이블 INSERT
  → 운영팀 Slack #ops-moderation 알림 (추후)
  → 운영팀 검토 → 조치 (경고/일시정지/영구정지)
```

### 자동 조치 기준
| 신고 횟수 | 조치 |
|----------|------|
| 3건 (24시간 내) | 자동 일시정지 (24시간) |
| 5건 (7일 내) | 자동 일시정지 (7일) + 운영팀 수동 검토 |
| 10건 (30일 내) | 영구 정지 후보 → 운영팀 최종 결정 |

### DB 구조
```sql
-- reports (migration 009)
reporter_id UUID NOT NULL,
reported_user_id UUID NOT NULL,
reported_message_id UUID,
reason VARCHAR(50) NOT NULL,
details TEXT,
status VARCHAR(20) DEFAULT 'pending',  -- pending/reviewed/resolved/dismissed
resolved_by UUID,
resolution TEXT
```

---

## 3. 차단 (Block)

### 동작 규칙
- 차단된 사용자의 메시지가 차단자에게 표시되지 않음
- RLS 정책이 `user_blocks` 테이블을 확인하여 필터링 (migration 009)
- 차단된 사용자는 차단 사실을 알 수 없음

### Flutter 구현
- `chat_thread_screen_v2.dart` → `_handleBlockUser()`
- 확인 다이얼로그 → `user_blocks` INSERT

### 차단 해제
- 설정 > 차단 관리에서 해제 가능
- `user_blocks` 테이블에서 DELETE

---

## 4. 숨기기 (Hide Fan)

### 동작 규칙
- **크리에이터 전용** 기능
- 숨긴 팬의 메시지는 크리에이터의 채널 타임라인에서 비표시
- 팬은 여전히 메시지를 보낼 수 있음 (팬 입장에서 차이 없음)
- 구독/결제는 정상 유지

### Flutter 구현
- `hide_fan_dialog.dart` → 확인 다이얼로그
- `creator_chat_tab_screen.dart` → 팬 메시지 long-press에서 "숨기기" 옵션

### DB upsert
```dart
await supabase.from('hidden_fans').upsert(
  {
    'creator_id': currentUserId,
    'fan_id': fanUserId,
    'reason': 'manual_hide',
  },
  onConflict: 'creator_id,fan_id',
);
```

### 숨김 해제
- 설정 > 숨긴 팬 관리에서 해제 가능
- `hidden_fans` 테이블에서 DELETE

---

## 5. RLS 정책 요약 (migration 009)

| 테이블 | 정책 | 설명 |
|--------|------|------|
| `reports` | `INSERT`: 인증 사용자 | 누구나 신고 가능 |
| `reports` | `SELECT`: 본인 신고만 | 자신이 한 신고만 조회 |
| `user_blocks` | `ALL`: 본인 차단만 | 자신의 차단 레코드만 CRUD |
| `hidden_fans` | `ALL`: 크리에이터 본인만 | `creator_id = auth.uid()` |

---

## 6. 운영팀 대응 SLA

| 우선도 | 대상 | 응답 시간 |
|--------|------|----------|
| **P0** | 불법 콘텐츠, 아동 안전 | 1시간 |
| **P1** | 괴롭힘, 혐오 발언 | 4시간 |
| **P2** | 스팸, 사칭 | 24시간 |
| **P3** | 기타 | 48시간 |
