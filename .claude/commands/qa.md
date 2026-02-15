# /qa — 검증 (테스트/린트/빌드) 커맨드

## 목표
프로젝트 표준 테스트/린트/빌드를 실행하고 결과를 PR + Notion에 남길 수 있는 형태로 출력한다.

## 절차

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ 1. 환경 감지 │ ──▶ │ 2. 표준 검증 │ ──▶ │ 3. 결과 출력 │
│ (Flutter/Web)│     │    실행      │     │ (PR 양식)    │
└──────────────┘     └──────────────┘     └──────────────┘
```

### Step 1: 환경 감지
- Flutter 프로젝트: `pubspec.yaml` 존재 확인

### Step 2: 표준 검증 실행 (최소 1개 이상)

| 도구 | 커맨드 | 목적 |
|------|--------|------|
| `repo_doctor` | `mcp__repo_doctor__run_all` | analyze + test + build + format |
| `security_guard` | `mcp__security_guard__precommit_gate` | 시크릿 + env 누출 |
| `supabase_guard` | `mcp__supabase_guard__prepush_report` | 마이그레이션 + RLS |

### Step 3: 결과 요약 출력

```
## QA Results
- flutter analyze: ✅/❌ (issues count)
- flutter test: ✅/❌ (pass/fail)
- flutter build web: ✅/❌
- secrets scan: ✅/❌
- migration lint: ✅/❌
- RLS audit: ✅/❌

## 재현 커맨드
flutter analyze && flutter test && flutter build web --release
```
