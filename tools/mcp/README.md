# UNO A MCP Stability Gates

4 MCP (Model Context Protocol) servers for automated quality, security, and review checks.

## Setup

```bash
cd tools/mcp
npm install
npm run build
```

## Servers

| Server | Tools | Purpose |
|--------|-------|---------|
| `repo_doctor` | `run_all`, `run` | Flutter analyze/test/build/format |
| `review_gate` | `diff_summary`, `diff_chunks`, `pr_checklist` | Git diff analysis + PR checklist |
| `supabase_guard` | `migration_lint`, `rls_audit`, `prepush_report` | Migration/RLS static checks |
| `security_guard` | `scan_secrets`, `scan_env_leaks`, `precommit_gate` | Secret/env leak scanning |

## .mcp.json

Servers are registered in the project root `.mcp.json` (gitignored). Each runs via `node tools/mcp/<server>/dist/index.js`.

## Rebuilding

```bash
cd tools/mcp && npm run build
```
