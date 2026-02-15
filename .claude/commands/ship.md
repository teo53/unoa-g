# /ship — 배포/공지/종결

## 목표
1. Notion WI 상태를 `Ready to Ship` → `Done`으로 마감
2. Slack `#proj-unoa-g`에 릴리즈 요약(링크 포함)을 1회 게시
3. ops/runbooks 업데이트 필요 여부 체크

## 절차

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ 1. WI 마감   │ ──▶ │ 2. Slack 공지│ ──▶ │ 3. 사후 체크 │
│ Status→Done  │     │ 릴리즈 요약  │     │ 모니터링30분 │
└──────────────┘     └──────────────┘     └──────────────┘
```

## 출력

```
## Release Notes (5~10 bullets)
- ...

## Links
- WI: <url>
- PR: <url>
- Deploy: <url>

## Post-release Checklist
- [ ] 모니터링 30분 (Sentry, 로그)
- [ ] 핵심 플로우 수동 테스트
- [ ] 이슈 발생 시 triage → #ops-incidents
- [ ] 런북 업데이트 필요 여부 확인
```
