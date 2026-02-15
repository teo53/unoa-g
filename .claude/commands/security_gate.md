# /security_gate — 보안/DB 게이트

## 목표
변경사항(또는 WI/PR 링크) 기준으로 보안/DB 위험을 식별하고 산출물을 생성한다.

## 규칙
- **레포 수정 금지** — 읽기 전용
- `security-db` subagent를 호출하여 산출물 생성

## 점검 항목
1. 인증/권한 — 관리자 라우트/서버 액션 보호, 권한 상승 경로
2. DB/RLS — RLS 누락, 서비스 롤 키 노출, 정책 우회
3. 마이그레이션 — 파괴적 변경, 롤백, 락/타임아웃
4. 비밀정보 — env/secret, 로그에 민감정보 출력
5. 외부 의존성 — 결제/웹훅, 서명 검증, 리플레이 방지

## MCP 도구 활용
```
mcp__security_guard__scan_secrets     → 하드코딩 키/토큰
mcp__security_guard__scan_env_leaks   → 환경변수 노출
mcp__supabase_guard__rls_audit        → RLS 누락 테이블
mcp__supabase_guard__migration_lint   → 위험 SQL
```

## 출력 → Slack thread 게시 + Notion WI 기록
```
Blockers / Required / Nice-to-have / Evidence / Risk Rating(P0~P3)
```
