import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { scanSecrets } from './secrets.js';
import { scanEnvLeaks } from './env_leaks.js';
import { precommitGate } from './precommit.js';

const server = new McpServer({
  name: 'security_guard',
  version: '1.0.0',
});

server.tool(
  'scan_secrets',
  'Scan the repository for hardcoded API keys, tokens, and passwords using a regex denylist. Returns findings with severity, redacted snippets, and fix hints.',
  {
    paths: z.array(z.string()).optional().describe('Subdirectories to scan (e.g. ["lib/", "supabase/"]). Defaults to common source dirs.'),
  },
  async ({ paths }) => {
    try {
      const report = scanSecrets(paths);
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ ok: false, error: String(err) }) }], isError: true };
    }
  }
);

server.tool(
  'scan_env_leaks',
  'Find patterns where env variables or secrets might be logged, printed, or exposed in HTTP responses.',
  {
    paths: z.array(z.string()).optional().describe('Subdirectories to scan. Defaults to ["lib/", "supabase/", "tools/"].'),
  },
  async ({ paths }) => {
    try {
      const report = scanEnvLeaks(paths);
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ ok: false, error: String(err) }) }], isError: true };
    }
  }
);

server.tool(
  'precommit_gate',
  'Combined secrets + env leaks scan. Returns ok=false if any critical or high severity findings exist, blocking the commit.',
  {},
  async () => {
    try {
      const report = precommitGate();
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ ok: false, error: String(err) }) }], isError: true };
    }
  }
);

console.error('[security_guard] Starting MCP server...');
const transport = new StdioServerTransport();
await server.connect(transport);
