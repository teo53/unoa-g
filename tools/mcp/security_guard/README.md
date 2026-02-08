# security_guard

Secret and environment leak scanner MCP server.

## Tools

### `scan_secrets`
Scan for hardcoded API keys, tokens, and passwords.

- **Input**: `{ "paths?": ["lib/", "supabase/"] }`
- **Output**:
```json
{
  "ok": false,
  "scannedFiles": 142,
  "findings": [{
    "severity": "critical",
    "code": "SECRET_ANTHROPIC_KEY",
    "file": "lib/data/services/example.dart",
    "line": 42,
    "message": "Anthropic API key",
    "fixHint": "Move to Supabase Edge Function env variable.",
    "snippetRedacted": "  'x-api-key': '****REDACTED****'"
  }]
}
```

### `scan_env_leaks`
Find patterns where secrets might be logged or exposed.

- **Input**: `{ "paths?": ["lib/", "supabase/"] }`
- **Output**: Same structure as `scan_secrets`.

### `precommit_gate`
Combined security gate. Blocks if critical/high findings exist.

- **Input**: (none)
- **Output**:
```json
{
  "ok": false,
  "secretsScan": { "..." },
  "envLeaksScan": { "..." },
  "summary": "BLOCKED: 2 critical/high finding(s).",
  "blockReason": "2 critical/high finding(s): SECRET_ANTHROPIC_KEY, LEAK_HEADER_HARDCODE"
}
```

## Secret Patterns

| Code | Severity | Pattern |
|------|----------|---------|
| `SECRET_ANTHROPIC_KEY` | critical | `sk-ant-*` |
| `SECRET_OPENAI_KEY` | critical | `sk-*` (20+ chars) |
| `SECRET_AWS_KEY` | critical | `AKIA` + 16 chars |
| `SECRET_PRIVATE_KEY` | critical | `-----BEGIN PRIVATE KEY-----` |
| `SECRET_FIREBASE_SA` | critical | `"type": "service_account"` |
| `SECRET_PAYMENT_KEY` | critical | `test_sk_*`, `live_sk_*`, `imp_*` |
| `SECRET_SUPABASE_SERVICE_ROLE` | critical | `service_role` + JWT |
| `SECRET_JWT_HARDCODED` | high | Hardcoded JWT strings |
| `SECRET_GENERIC_API_KEY` | high | `api_key = "..."` |
| `SECRET_PASSWORD_URL` | high | DB connection string with password |

## Scan Exclusions

`node_modules/`, `build/`, `dist/`, `.dart_tool/`, `stitch/`, `.env.example`

## Error Codes

`SECRETS_FOUND`, `ENV_LEAKS_FOUND`, `PRECOMMIT_BLOCKED`

## Limitations

- Regex-based detection (may have false positives)
- Skips comment lines and `String.fromEnvironment` declarations
- Secret values are always masked in output (never exposed)
