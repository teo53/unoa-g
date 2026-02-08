import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { diffSummary } from './diff.js';
import { diffChunks } from './chunks.js';
import { prChecklist } from './checklist.js';

const server = new McpServer({
  name: 'review_gate',
  version: '1.0.0',
});

server.tool(
  'diff_summary',
  'Summarize git diff between current branch and base: files changed, insertions/deletions, categorized by type, risk flags.',
  {
    base: z.string().optional().describe('Base branch to diff against. Default: "main".'),
  },
  async ({ base }) => {
    try {
      const report = await diffSummary(base);
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ error: String(err) }) }], isError: true };
    }
  }
);

server.tool(
  'diff_chunks',
  'Return full git diff chunked by file with a byte budget. Useful for reviewing large diffs.',
  {
    base: z.string().optional().describe('Base branch to diff against. Default: "main".'),
    maxBytes: z.number().optional().describe('Maximum total bytes for diff output. Default: 100000.'),
  },
  async ({ base, maxBytes }) => {
    try {
      const report = await diffChunks(base, maxBytes);
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ error: String(err) }) }], isError: true };
    }
  }
);

server.tool(
  'pr_checklist',
  'Auto-generate a PR review checklist based on changed files. Checks for testing, error UX, logging, migration, RLS, rollback, security.',
  {
    base: z.string().optional().describe('Base branch to diff against. Default: "main".'),
  },
  async ({ base }) => {
    try {
      const report = await prChecklist(base);
      return { content: [{ type: 'text', text: JSON.stringify(report, null, 2) }] };
    } catch (err) {
      return { content: [{ type: 'text', text: JSON.stringify({ error: String(err) }) }], isError: true };
    }
  }
);

console.error('[review_gate] Starting MCP server...');
const transport = new StdioServerTransport();
await server.connect(transport);
