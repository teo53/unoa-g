import { readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { getRepoRoot } from '../../_shared/src/paths.js';
import type { Finding, EdgeFunctionReport, PrepushReport } from '../../_shared/src/types.js';
import { migrationLint } from './migration_lint.js';
import { rlsAudit } from './rls_audit.js';

/** Check Edge Functions for basic structural issues */
function checkEdgeFunctions(): EdgeFunctionReport {
  const root = getRepoRoot();
  const functionsDir = join(root, 'supabase', 'functions');
  const findings: Finding[] = [];

  let dirs: string[];
  try {
    dirs = readdirSync(functionsDir, { withFileTypes: true })
      .filter(d => d.isDirectory() && !d.name.startsWith('_'))
      .map(d => d.name);
  } catch {
    return {
      ok: true,
      totalFunctions: 0,
      findings: [{
        severity: 'info',
        code: 'EF_DIR_NOT_FOUND',
        file: 'supabase/functions/',
        message: 'Edge Functions directory not found',
        fixHint: 'Create supabase/functions/ if Edge Functions are needed.',
      }],
    };
  }

  for (const dir of dirs) {
    const indexPath = join(functionsDir, dir, 'index.ts');
    if (!existsSync(indexPath)) {
      findings.push({
        severity: 'error',
        code: 'EF_MISSING_ENTRY',
        file: `supabase/functions/${dir}/`,
        message: `Edge Function "${dir}" missing index.ts entry point`,
        fixHint: `Add index.ts to supabase/functions/${dir}/`,
      });
    }
  }

  return {
    ok: findings.filter(f => f.severity === 'error').length === 0,
    totalFunctions: dirs.length,
    findings,
  };
}

/** Combined pre-push report: migration lint + RLS audit + Edge Function checks */
export function prepushReport(): PrepushReport {
  const migLint = migrationLint();
  const rls = rlsAudit();
  const ef = checkEdgeFunctions();

  const ok = migLint.ok && rls.ok && ef.ok;

  const parts: string[] = [];
  if (!migLint.ok) parts.push(`Migration lint: ${migLint.findings.filter(f => f.severity === 'error').length} error(s)`);
  if (!rls.ok) parts.push(`RLS audit: ${rls.tablesMissingRls.length} table(s) missing RLS`);
  if (!ef.ok) parts.push(`Edge Functions: ${ef.findings.filter(f => f.severity === 'error').length} issue(s)`);

  const summary = ok
    ? `All checks passed. ${migLint.totalFiles} migrations, ${rls.totalTables} tables, ${ef.totalFunctions} Edge Functions.`
    : `ISSUES FOUND: ${parts.join('; ')}`;

  return {
    ok,
    sections: {
      migrationLint: migLint,
      rlsAudit: rls,
      edgeFunctions: ef,
    },
    summary,
  };
}
