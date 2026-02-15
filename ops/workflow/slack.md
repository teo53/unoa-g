# Slack 구조 (고정)

## 채널 목록

| 채널 | Purpose | 용도 |
|------|---------|------|
| `#proj-unoa-g` | WI intake + routing + release comms | 메인 프로젝트 채널 |
| `#gate-security-db` | Gate outputs only. No code changes. | 보안/DB 게이트 산출물 |
| `#gate-uiux-obs` | Gate outputs only. No code changes. | UIUX/관측성 게이트 산출물 |
| `#gate-legal` | Gate outputs only. No code changes. | 법무 게이트 산출물 |
| `#gate-tax-accounting` | Gate outputs only. No code changes. | 세무/회계 게이트 산출물 |
| `#pr-reviews` | PR notifications + review coordination | PR 알림 + 리뷰 |
| `#ops-incidents` | Incident triage + timeline thread | 인시던트 관리 |

## 운영 규칙

- 채널 새 글은 **"WI 링크 1개 + 요약 5줄"**까지만
- 논의/승인은 **스레드에서만**
- 승인 표준 리액션: ✅ 승인 / ❌ 블로커 / 👀 확인중

## 핀 메시지 (채널별)

### #proj-unoa-g 핀 메시지
```
[규칙] WI 1개 = Slack 스레드 1개 = PR 1개.
채널에는 WI 링크 + 요약만. 논의/승인은 스레드에서만.
승인 리액션: ✅ 승인 / ❌ 블로커 / 👀 확인중
시작: /route
```

### #proj-unoa-g 추가 핀: Notion 링크
```
📌 UNOA Ops HQ (Notion): <Notion URL 여기에>
- Work Items DB
- Decision Log
- Incidents
```

### Gate 채널 (#gate-*) 공통 핀 메시지
```
이 채널은 Gate 산출물 전용.
- 코드 수정 금지
- 산출물 포맷: Blockers / Required / Nice-to-have / Evidence / Risk
- 최종본은 Notion WI에 남겨야 완료
```

## 수동 채널 생성 가이드 (Slack MCP 미연결 시)

### 1. 채널 생성
Slack 워크스페이스에서 위 7개 채널을 생성합니다:
1. `+` → "Create a channel" → 이름 입력 → Purpose 설정 → Create
2. 각 채널마다 반복

### 2. 핀 메시지 설정
1. 위 핀 메시지 텍스트를 채널에 붙여넣기
2. 메시지 우측 `...` → "Pin to channel"

### 3. Slack MCP 향후 연결
```bash
claude mcp add slack-mcp -- npx -y @anthropic/slack-mcp
```
연결 후 `/route` 커맨드에서 자동으로 Slack 메시지/핀 생성 가능.
