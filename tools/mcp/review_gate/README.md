# review_gate

Git diff analysis and PR checklist generator MCP server.

## Tools

### `diff_summary`
Summarize git diff between current branch and base.

- **Input**: `{ "base?": "main" }`
- **Output**:
```json
{
  "base": "main",
  "filesChanged": 12,
  "insertions": 340,
  "deletions": 45,
  "filesByCategory": {
    "dart": ["lib/..."],
    "sql": ["supabase/migrations/..."],
    "config": ["pubspec.yaml"],
    "typescript": [],
    "other": []
  },
  "riskFlags": ["migration_changed", "pubspec_changed"],
  "summary": "12 file(s) changed (+340/-45) vs main..."
}
```

### `diff_chunks`
Return full diff chunked by file with byte budget.

- **Input**: `{ "base?": "main", "maxBytes?": 100000 }`
- **Output**:
```json
{
  "base": "main",
  "totalFiles": 12,
  "includedFiles": 10,
  "truncated": true,
  "chunks": [{
    "path": "lib/...",
    "status": "modified",
    "insertions": 25,
    "deletions": 3,
    "diff": "...",
    "truncatedAt": null
  }]
}
```

### `pr_checklist`
Auto-generate PR review checklist.

- **Input**: `{ "base?": "main" }`
- **Output**:
```json
{
  "base": "main",
  "checklist": [{
    "category": "testing",
    "item": "Run flutter test and verify all tests pass",
    "required": true,
    "triggered_by": "lib/features/chat/chat_screen.dart"
  }],
  "riskLevel": "high",
  "summary": "15 checklist item(s) (8 required). Risk: high."
}
```

## Risk Flags

`migration_changed`, `rls_policy_modified`, `pubspec_changed`, `config_changed`, `edge_function_changed`, `core_config_changed`, `routing_changed`, `security_related`

## Limitations

- Uses `git diff base...HEAD` (three-dot merge-base diff)
- Requires a git repository with the base branch available
