# Bootstrap / Re-run Guide

## 이 문서의 역할
본 문서와 `CLAUDE.md`가 "운영 계약서"다.
모든 운영 규칙/프로세스/도구 설정이 여기에 고정된다.

## 전체 구조 한눈에

```
┌─────────────────────────────────────────────────────────┐
│                    UNOA Ops Stack                        │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Notion   │  │  Slack   │  │  GitHub  │              │
│  │  Ops HQ   │  │ Channels │  │   Repo   │              │
│  │           │  │          │  │          │              │
│  │ • WI DB   │  │ • proj   │  │ • .claude│              │
│  │ • Decision│  │ • gates  │  │ • ops/   │              │
│  │ • Incident│  │ • pr-rev │  │ • .github│              │
│  │           │  │ • ops-inc│  │          │              │
│  └─────┬─────┘  └────┬─────┘  └────┬─────┘              │
│        │             │             │                    │
│        └─────────────┼─────────────┘                    │
│                      │                                  │
│              WI 1개 = Thread 1개 = PR 1개                │
└─────────────────────────────────────────────────────────┘
```

## 재실행 규칙

- Slack/Notion 자원이 이미 있으면 **재사용** (중복 생성 금지)
- 파일이 이미 있으면 **안전하게 업데이트** (덮어쓰기 주의)
- 비밀정보는 절대 파일에 포함하지 않는다

## 하드 블로커 대응

| 블로커 | 해결 방법 |
|--------|-----------|
| Notion에서 부모 페이지 접근권한 없음 | 사용자에게 parent page ID 1개 요청 |
| Slack 채널 생성 권한 없음 | `ops/workflow/slack.md`의 수동 생성 가이드 참고 |
| MCP 서버 미연결 | `claude mcp add <server>` 실행 |
| Git push 권한 없음 | fork → PR 방식으로 변경 |

## 온보딩: 첫 번째 WI 만들기 (3단계)

```
┌────────────────────────────────────────────────┐
│  Step 1: /route 실행                            │
│  "새 WI를 만들고 싶어요. 제목: OOO"             │
│                                                │
│     ↓                                          │
│                                                │
│  Step 2: Gate 산출물 확인                       │
│  자동 지정된 Gate들의 산출물을 검토              │
│  → Slack thread에 게시됨                        │
│                                                │
│     ↓                                          │
│                                                │
│  Step 3: Builder 구현 → 검증 → 배포             │
│  /qa → /verify → /ship                          │
│  → PR 생성 → 머지 → 릴리즈                     │
└────────────────────────────────────────────────┘
```

## 필수 도구

| 도구 | 설치 | 용도 |
|------|------|------|
| Claude Code | 이미 설치됨 | AI 기반 워크플로우 |
| Notion MCP | `claude mcp add notion` | WI/DB 관리 |
| Slack MCP | `claude mcp add slack-mcp -- npx -y @anthropic/slack-mcp` | 채널/메시지 관리 |
| GitHub CLI | `brew install gh` / `winget install gh` | PR 생성/관리 |
