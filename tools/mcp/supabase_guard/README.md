# supabase_guard

Supabase migration and RLS static analysis MCP server.

## Tools

### `migration_lint`
Lint migration files for conventions and dangerous SQL.

- **Input**: (none)
- **Output**:
```json
{
  "ok": false,
  "totalFiles": 37,
  "findings": [{
    "severity": "warning",
    "code": "SQL_GRANT_ALL",
    "file": "supabase/migrations/021_funding_schema.sql",
    "line": 45,
    "message": "GRANT ALL detected - overly broad permissions",
    "fixHint": "Use specific privileges instead of ALL."
  }]
}
```

### `rls_audit`
Cross-reference tables with RLS policies.

- **Input**: (none)
- **Output**:
```json
{
  "ok": true,
  "totalTables": 24,
  "tablesWithRls": 22,
  "tablesMissingRls": [],
  "findings": []
}
```

### `prepush_report`
Combined pre-push check.

- **Input**: (none)
- **Output**:
```json
{
  "ok": true,
  "sections": {
    "migrationLint": { "..." },
    "rlsAudit": { "..." },
    "edgeFunctions": { "..." }
  },
  "summary": "All checks passed. 37 migrations, 24 tables, 13 Edge Functions."
}
```

## Lint Rules

**Filename**: `NNN_description.sql` (3-digit zero-padded)
**Sequence**: Contiguous numbers, no gaps or duplicates
**Dangerous SQL**: `DROP TABLE`, `TRUNCATE`, `GRANT ALL`, `GRANT TO public`, `DELETE` without `WHERE`, `REVOKE`
**RLS**: Every `CREATE TABLE` must have corresponding `ENABLE ROW LEVEL SECURITY`

## Error Codes

`MIGRATION_LINT_ERROR`, `RLS_MISSING`, `EF_MISSING_ENTRY`

## Exempt Tables

`schema_migrations`, `encryption_metadata`, `policy_config` are exempt from RLS audit.

## Limitations

- Static analysis only (does not connect to a live database)
- Parses SQL with regex (may miss complex DDL edge cases)
