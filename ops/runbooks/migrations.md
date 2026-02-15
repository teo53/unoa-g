# DB / Migrations Runbook

## 원칙

1. **파괴적 스키마 변경 금지** — 롤백 플랜 없이 `DROP COLUMN`, `DROP TABLE` 불가
2. **마이그레이션은 되돌릴 수 있어야** 한다 — 또는 backfill 스크립트 동반
3. **RLS 기본 적용** — 사용자 데이터 테이블은 RLS 필수
4. **검증 단계**: 로컬 → 스테이징 dry run → 프로덕션 (모니터링 동반)

## 마이그레이션 절차

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ 1. 로컬 작성 │ ──▶ │ 2. 린트 검증 │ ──▶ │ 3. 스테이징  │ ──▶ │ 4. 프로덕션  │
│ SQL 파일     │     │ migration_lint│     │ dry run      │     │ + 모니터링   │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
```

### Step 1: SQL 파일 작성
- 파일명: `NNN_description.sql` (순번 기준)
- `IF NOT EXISTS` / `IF EXISTS` 사용 권장

### Step 2: 린트 검증
```bash
# MCP 도구 사용
mcp__supabase_guard__migration_lint
mcp__supabase_guard__rls_audit
```

### Step 3: 스테이징 적용
```bash
supabase db push --linked
# 또는 스테이징 환경에서 dry run
```

### Step 4: 프로덕션 적용
- 배포 후 30분 모니터링
- 쿼리 성능 확인 (슬로우 쿼리 알림)
- 이상 시 즉시 롤백

## 위험 SQL 체크리스트

| SQL | 위험도 | 대응 |
|-----|--------|------|
| `DROP COLUMN` | 높음 | 데이터 백업 필수 |
| `DROP TABLE` | 매우 높음 | 거의 금지 |
| `ALTER TYPE` | 중간 | 락 시간 확인 |
| `TRUNCATE` | 높음 | 백업 필수 |
| `GRANT ALL` | 중간 | 최소 권한으로 변경 |
| `REVOKE` | 중간 | 영향 범위 확인 |

## 롤백 템플릿

```sql
-- 롤백: NNN_description.sql
-- 작성일: YYYY-MM-DD
-- 사유: ...

-- 추가한 컬럼 제거
ALTER TABLE <table> DROP COLUMN IF EXISTS <column>;

-- 추가한 인덱스 제거
DROP INDEX IF EXISTS <index>;
```
