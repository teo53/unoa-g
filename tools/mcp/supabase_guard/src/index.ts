import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { migrationLint } from './migration_lint.js';
import { rlsAudit } from './rls_audit.js';
import { prepushReport } from './prepush.js';

const server = new McpServer({
  name: 'supabase_guard',
  version: '1.0.0',
});

server.tool(
  'migration_lint',
  'Lint supabase/migrations/ for filename conventions, ordering gaps, and dangerous SQL (DROP, TRUNCATE, GRANT ALL, etc.).',
  {},
  async () => {
    try {
      const report = migrationLint();
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ ok: false, error: String(err) }) }], isError: true };
    }
  }
);

server.tool(
  'rls_audit',
  'Cross-reference CREATE TABLE with ENABLE ROW LEVEL SECURITY across all migrations. Reports tables missing RLS or policies.',
  {},
  async () => {
    try {
      const report = rlsAudit();
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ ok: false, error: String(err) }) }], isError: true };
    }
  }
);

server.tool(
  'prepush_report',
  'Combined pre-push check: migration lint + RLS audit + Edge Function structural validation.',
  {},
  async () => {
    try {
      const report = prepushReport();
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ ok: false, error: String(err) }) }], isError: true };
    }
  }
);

console.error('[supabase_guard] Starting MCP server...');
const transport = new StdioServerTransport();
await server.connect(transport);
