# /uiux_obs_gate — UI/UX + Observability 게이트

## 목표
실패 UX 정책 + 로깅/Sentry 태그 규칙 + 운영 안전장치를 산출한다.

## 규칙
- **레포 수정 금지** — 읽기 전용
- `uiux-obs` subagent를 호출하여 산출물 생성

## 점검 항목
1. 실패 UX — 로딩/재시도/타임아웃/결제 실패/네트워크 불안정/권한 거부
2. 메시지 톤 — 과장/오해 유발 금지, 사용자 책임 전가 금지
3. 관측성 — 이벤트/로그 네이밍, Sentry 태그, 에러 분류
4. 안전장치 — Feature flag, 단계적 롤아웃, kill-switch

## 참고
```
docs/ux/                              → UX 디자인 문서
tools/unoa-review-mcp/checklists/uiux.md → UIUX 체크리스트
lib/shared/widgets/error_boundary.dart → 에러 바운더리
lib/shared/widgets/state_widgets.dart  → 상태 위젯
```

## 출력 → Slack thread 게시 + Notion WI 기록
```
Blockers / Required / Nice-to-have / Evidence / Risk Rating(P0~P3)
```
