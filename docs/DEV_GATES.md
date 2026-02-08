# Development Quality Gates

UNO A 프로젝트의 개발 안정성 자동화 시스템.

## 3층 방어 구조

| 층 | 메커니즘 | 동작 시점 | 차단 여부 |
|----|----------|----------|----------|
| 1층 | Claude Code Hooks | `git commit` / `git push` 시 자동 | 차단 (exit 2) |
| 2층 | PowerShell 스크립트 | 수동 실행 가능 | exit 1 = 실패 |
| 3층 | GitHub Actions CI | push/PR 시 자동 | PR 머지 차단 |

## 새 PC 세팅

```powershell
powershell -File scripts/bootstrap-mcp.ps1
```

이 스크립트가 수행하는 작업:
1. `.claude/settings.local.json` 생성 (템플릿에서 복사)
2. MCP 서버 의존성 설치 및 빌드
3. Flutter 의존성 설치

## 게이트 스크립트

### 커밋 전 수동 검증 (빠른 검사)

```powershell
powershell -File scripts/gates/run-fast.ps1
```

- `flutter analyze` 실행
- `flutter test` 실행
- 실패 시 exit 1

### 풀 검증 (전체 빌드 포함)

```powershell
powershell -File scripts/gates/run-full.ps1
```

- `run-fast.ps1` 실행 (analyze + test)
- `flutter build web --release` 실행
- 웹 빌드 건너뛰기: `$env:UNO_GATE_SKIP_WEB_BUILD = '1'`

### 시크릿 스캔

```powershell
powershell -File scripts/gates/scan-secrets.ps1
```

- `git diff --cached`의 staged 변경사항에서 시크릿 패턴 탐지
- 탐지 패턴: Anthropic/OpenAI API 키, AWS 키, Private Key, Supabase service_role, 결제 키, Firebase SA
- 발견 시 exit 1 + 파일:라인 출력

### Supabase 마이그레이션 검증

```powershell
powershell -File scripts/gates/guard-supabase.ps1
```

- 파일명 규칙 (`NNN_description.sql`) 검증
- 시퀀스 번호 중복/갭 검사
- 위험 SQL 경고 (DROP TABLE, TRUNCATE, GRANT ALL)
- 항상 exit 0 (경고만, 비차단)

## Hook 동작

Claude Code에서 `git commit` 또는 `git push` 명령 실행 시 자동으로 게이트가 동작합니다.

| 명령 | 실행되는 게이트 |
|------|----------------|
| `git commit` | scan-secrets → run-fast |
| `git push` | scan-secrets → run-full → guard-supabase |

실패 시 해당 명령이 차단됩니다 (exit 2).

## 설정 파일

| 파일 | 커밋 | 용도 |
|------|:----:|------|
| `.claude/settings.json` | O | Hooks + deny 규칙 (공유) |
| `.claude/settings.local.json` | X | 로컬 권한 설정 (개인) |
| `.claude/settings.template.local.json` | O | 로컬 설정 템플릿 |
| `.mcp.json` | X | MCP 서버 설정 (로컬) |

## 절대 커밋 금지 파일

- `.env`, `.env.*` (`.env.example` 제외)
- `.claude/settings.local.json`
- `.mcp.json`
- API 키가 포함된 모든 파일
- `**/secrets/` 디렉토리

## CI (GitHub Actions)

`.github/workflows/ci.yml`:
- **push (main)**: analyze + test
- **PR (main)**: analyze + test + build web

Hook을 우회하더라도 CI가 최종 강제 게이트 역할을 합니다.

## 트러블슈팅

### Hook이 너무 오래 걸릴 때
```powershell
# 웹 빌드 건너뛰기 (push 시)
$env:UNO_GATE_SKIP_WEB_BUILD = '1'
```

### flutter analyze 경고가 많을 때
- 기존 650+ info/deprecated_member_use 경고는 무시됨 (에러 아님)
- `flutter analyze`는 error 레벨만 exit 1로 처리

### 시크릿 스캔 오탐
- `.env.example`, `*.lock`, `*.md` 파일은 자동 제외
- 패턴이 맞지만 실제 시크릿이 아닌 경우: 해당 파일을 unstage 후 커밋
