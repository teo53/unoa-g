# repo_doctor

Flutter quality check runner MCP server.

## Tools

### `run_all`
Run all quality checks sequentially.

- **Input**: (none)
- **Output**:
```json
{
  "ok": true,
  "steps": [{
    "name": "analyze",
    "cmd": "flutter analyze",
    "exitCode": 0,
    "durationMs": 5200,
    "stdoutTail": "...",
    "stderrTail": "",
    "ok": true
  }],
  "summary": "All 4 checks passed in 45.2s",
  "errorCode": null,
  "nextActions": [],
  "durationMs": 45200
}
```

### `run`
Run a single task.

- **Input**: `{ "task": "analyze" | "test" | "build" | "format" }`
- **Output**: Same as `run_all` with a single step.

## Allowlisted Commands

| Task | Command | Timeout |
|------|---------|---------|
| `analyze` | `flutter analyze` | 120s |
| `test` | `flutter test` | 300s |
| `build` | `flutter build web --release` | 300s |
| `format` | `dart format . --set-exit-if-changed` | 60s |

## Error Codes

`ANALYZE_FAIL`, `TEST_FAIL`, `BUILD_FAIL`, `FORMAT_FAIL`, `UNKNOWN_TASK`, `TASK_TIMEOUT`

## Limitations

- Only allowlisted commands can be executed
- Output is truncated to last 2000 chars per step
- Secrets in output are automatically masked
