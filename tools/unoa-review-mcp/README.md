# UNO-A Review MCP (unoa-review)

UI/UX + Legal(KR) + Tax(KR) issue-spotting review MCP server (STDIO).

> This is issue-spotting, not legal/tax advice. Final review by attorney/CPA required.

## Setup

```bash
cd tools/unoa-review-mcp
npm install
```

## Run locally

```bash
npm run start
```

## Claude Code Integration

Project root `.mcp.json` registers this server. Claude Code auto-connects on startup.

### Prompts

| Command | Description |
|---------|-------------|
| `uiux_review` | UI/UX audit across key flows |
| `legal_review_kr` | Legal/compliance issue-spotting (KR) |
| `tax_review_kr` | Tax/accounting issue-spotting (KR) |
| `release_gate` | Pre-release P0/P1 gate check |

### Tools

| Tool | Description |
|------|-------------|
| `risk_map` | Prioritized review paths + existence check |
| `review_output_template` | Report format template |

### Resources

| URI | Description |
|-----|-------------|
| `review://checklists/uiux` | UI/UX checklist |
| `review://checklists/legal_kr` | Legal(KR) checklist |
| `review://checklists/tax_kr` | Tax(KR) checklist |
