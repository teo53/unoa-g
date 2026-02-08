import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { getRepoRoot } from '../../_shared/src/paths.js';
import type { Finding, RlsAuditReport } from '../../_shared/src/types.js';

/** Extract all CREATE TABLE table names from SQL content */
function extractTables(sql: string): string[] {
  const tables: string[] = [];
  const regex = /CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:public\.)?(\w+)/gi;
  let match;
  while ((match = regex.exec(sql)) !== null) {
    tables.push(match[1].toLowerCase());
  }
  return tables;
}

/** Extract tables that have RLS enabled */
function extractRlsTables(sql: string): string[] {
  const tables: string[] = [];
  const regex = /ALTER\s+TABLE\s+(?:public\.)?(\w+)\s+ENABLE\s+ROW\s+LEVEL\s+SECURITY/gi;
  let match;
  while ((match = regex.exec(sql)) !== null) {
    tables.push(match[1].toLowerCase());
  }
  return tables;
}

/** Extract tables that have at least one policy */
function extractPolicyTables(sql: string): string[] {
  const tables: string[] = [];
  const regex = /CREATE\s+POLICY\s+[^\n]+\s+ON\s+(?:public\.)?(\w+)/gi;
  let match;
  while ((match = regex.exec(sql)) !== null) {
    tables.push(match[1].toLowerCase());
  }
  return tables;
}

/** Tables that are OK to not have RLS (system/internal tables) */
const RLS_EXEMPT_TABLES = new Set([
  'schema_migrations',
  'encryption_metadata',
  'policy_config',
]);

export function rlsAudit(): RlsAuditReport {
  const root = getRepoRoot();
  const migrationsDir = join(root, 'supabase', 'migrations');

  let files: string[];
  try {
    files = readdirSync(migrationsDir).filter(f => f.endsWith('.sql')).sort();
  } catch {
    return {
      ok: false,
      totalTables: 0,
      tablesWithRls: 0,
      tablesMissingRls: [],
      findings: [{
        severity: 'error',
        code: 'MIGRATION_DIR_NOT_FOUND',
        file: 'supabase/migrations/',
        message: 'Migrations directory not found',
        fixHint: 'Create supabase/migrations/ directory.',
      }],
    };
  }

  // Aggregate all SQL content across all migrations
  const allTables = new Set<string>();
  const rlsEnabled = new Set<string>();
  const hasPolicies = new Set<string>();

  for (const file of files) {
    let content: string;
    try {
      content = readFileSync(join(migrationsDir, file), 'utf-8');
    } catch {
      continue;
    }

    for (const t of extractTables(content)) allTables.add(t);
    for (const t of extractRlsTables(content)) rlsEnabled.add(t);
    for (const t of extractPolicyTables(content)) hasPolicies.add(t);
  }

  const findings: Finding[] = [];
  const tablesMissingRls: string[] = [];

  for (const table of allTables) {
    if (RLS_EXEMPT_TABLES.has(table)) continue;

    if (!rlsEnabled.has(table)) {
      tablesMissingRls.push(table);
      findings.push({
        severity: 'error',
        code: 'RLS_MISSING',
        file: 'supabase/migrations/',
        message: `Table "${table}" has no ENABLE ROW LEVEL SECURITY`,
        fixHint: `Add: ALTER TABLE ${table} ENABLE ROW LEVEL SECURITY;`,
      });
    } else if (!hasPolicies.has(table)) {
      findings.push({
        severity: 'warning',
        code: 'RLS_NO_POLICY',
        file: 'supabase/migrations/',
        message: `Table "${table}" has RLS enabled but no policies defined`,
        fixHint: `Add at least one CREATE POLICY for table "${table}".`,
      });
    }
  }

  const hasErrors = findings.some(f => f.severity === 'error');
  return {
    ok: !hasErrors,
    totalTables: allTables.size,
    tablesWithRls: rlsEnabled.size,
    tablesMissingRls,
    findings,
  };
}
