import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { runAll, runSingle } from './runner.js';

const server = new McpServer({
  name: 'repo_doctor',
  version: '1.0.0',
});

server.tool(
  'run_all',
  'Run all quality checks sequentially: flutter analyze, flutter test, flutter build web --release, dart format --set-exit-if-changed. Returns JSON report with per-step results.',
  {},
  async () => {
    try {
      const report = await runAll();
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ ok: false, error: String(err) }) }], isError: true };
    }
  }
);

server.tool(
  'run',
  'Run a single allowlisted quality check task.',
  {
    task: z.enum(['analyze', 'test', 'build', 'format']).describe('The task to run: analyze, test, build, or format.'),
  },
  async ({ task }) => {
    try {
      const report = await runSingle(task);
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ ok: false, error: String(err) }) }], isError: true };
    }
  }
);

console.error('[repo_doctor] Starting MCP server...');
const transport = new StdioServerTransport();
await server.connect(transport);
