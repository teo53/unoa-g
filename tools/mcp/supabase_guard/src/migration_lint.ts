import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { getRepoRoot, toRelative } from '../../_shared/src/paths.js';
import type { Finding, MigrationLintReport } from '../../_shared/src/types.js';

const FILENAME_PATTERN = /^(\d{3})_[\w]+\.sql$/;

interface DangerousPattern {
  regex: RegExp;
  code: string;
  severity: Finding['severity'];
  message: string;
  fixHint: string;
}

const DANGEROUS_SQL: DangerousPattern[] = [
  {
    regex: /\bDROP\s+TABLE\b/i,
    code: 'SQL_DROP_TABLE',
    severity: 'error',
    message: 'DROP TABLE detected — data loss risk',
    fixHint: 'Use soft-delete (add deleted_at column) or ensure data is backed up first.',
  },
  {
    regex: /\bTRUNCATE\b/i,
    code: 'SQL_TRUNCATE',
    severity: 'error',
    message: 'TRUNCATE detected — deletes all rows without logging',
    fixHint: 'Use DELETE with WHERE clause instead of TRUNCATE.',
  },
  {
    regex: /\bALTER\s+TABLE\s+\w+\s+DROP\s+COLUMN\b/i,
    code: 'SQL_DROP_COLUMN',
    severity: 'warning',
    message: 'DROP COLUMN detected — may lose data',
    fixHint: 'Ensure column data is migrated or backed up before dropping.',
  },
  {
    regex: /\bGRANT\s+ALL\b/i,
    code: 'SQL_GRANT_ALL',
    severity: 'warning',
    message: 'GRANT ALL detected — overly broad permissions',
    fixHint: 'Use specific privileges (SELECT, INSERT, UPDATE, DELETE) instead of ALL.',
  },
  {
    regex: /\bGRANT\s+.*\bTO\s+public\b/i,
    code: 'SQL_GRANT_PUBLIC',
    severity: 'error',
    message: 'GRANT TO public detected — exposes to all roles',
    fixHint: 'Grant to specific roles (authenticated, anon, service_role) instead.',
  },
  {
    regex: /\bREVOKE\b/i,
    code: 'SQL_REVOKE',
    severity: 'warning',
    message: 'REVOKE detected — may break existing permissions',
    fixHint: 'Document why privileges are being revoked and test impact.',
  },
  {
    regex: /\bDELETE\s+FROM\s+\w+\s*;/i,
    code: 'SQL_RAW_DELETE',
    severity: 'warning',
    message: 'DELETE without WHERE clause — deletes all rows',
    fixHint: 'Add WHERE clause to limit deletion scope.',
  },
  {
    regex: /\bSECURITY\s+DEFINER\b/i,
    code: 'SQL_SECURITY_DEFINER',
    severity: 'info',
    message: 'SECURITY DEFINER function — runs with creator privileges',
    fixHint: 'Ensure function is narrowly scoped and does not leak data.',
  },
];

export function migrationLint(): MigrationLintReport {
  const root = getRepoRoot();
  const migrationsDir = join(root, 'supabase', 'migrations');

  let files: string[];
  try {
    files = readdirSync(migrationsDir).filter(f => f.endsWith('.sql')).sort();
  } catch {
    return {
      ok: false,
      totalFiles: 0,
      findings: [{
        severity: 'error',
        code: 'MIGRATION_DIR_NOT_FOUND',
        file: 'supabase/migrations/',
        message: 'Migrations directory not found',
        fixHint: 'Create supabase/migrations/ directory.',
      }],
    };
  }

  const findings: Finding[] = [];
  const seenNumbers = new Map<number, string>();

  // Check non-SQL files
  const allEntries = readdirSync(migrationsDir);
  for (const entry of allEntries) {
    if (!entry.endsWith('.sql') && !entry.startsWith('.')) {
      findings.push({
        severity: 'error',
        code: 'MIG_NOT_SQL',
        file: `supabase/migrations/${entry}`,
        message: `Non-SQL file in migrations directory: ${entry}`,
        fixHint: 'Remove or move non-SQL files out of migrations directory.',
      });
    }
  }

  for (const file of files) {
    const relPath = `supabase/migrations/${file}`;
    const match = file.match(FILENAME_PATTERN);

    if (!match) {
      findings.push({
        severity: 'error',
        code: 'MIG_FILENAME_FORMAT',
        file: relPath,
        message: `Filename does not match NNN_description.sql: ${file}`,
        fixHint: 'Rename to NNN_short_description.sql (e.g., 001_initial_schema.sql).',
      });
      continue;
    }

    const seqNum = parseInt(match[1], 10);

    // Check for duplicates
    if (seenNumbers.has(seqNum)) {
      findings.push({
        severity: 'error',
        code: 'MIG_SEQUENCE_DUPLICATE',
        file: relPath,
        message: `Duplicate sequence number ${match[1]} (also: ${seenNumbers.get(seqNum)})`,
        fixHint: 'Renumber one of the duplicate migrations.',
      });
    }
    seenNumbers.set(seqNum, file);

    // Scan for dangerous SQL
    let content: string;
    try {
      content = readFileSync(join(migrationsDir, file), 'utf-8');
    } catch {
      continue;
    }

    const lines = content.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      // Skip comment lines
      if (line.trim().startsWith('--')) continue;

      for (const pattern of DANGEROUS_SQL) {
        pattern.regex.lastIndex = 0;
        if (pattern.regex.test(line)) {
          findings.push({
            severity: pattern.severity,
            code: pattern.code,
            file: relPath,
            line: i + 1,
            message: pattern.message,
            fixHint: pattern.fixHint,
          });
        }
      }
    }
  }

  // Check for sequence gaps
  const sortedNums = [...seenNumbers.keys()].sort((a, b) => a - b);
  for (let i = 1; i < sortedNums.length; i++) {
    if (sortedNums[i] - sortedNums[i - 1] > 1) {
      findings.push({
        severity: 'warning',
        code: 'MIG_SEQUENCE_GAP',
        file: `supabase/migrations/`,
        message: `Gap in sequence: ${String(sortedNums[i - 1]).padStart(3, '0')} -> ${String(sortedNums[i]).padStart(3, '0')}`,
        fixHint: 'Add missing migration or renumber for contiguous sequence.',
      });
    }
  }

  const hasErrors = findings.some(f => f.severity === 'error');
  return {
    ok: !hasErrors,
    totalFiles: files.length,
    findings,
  };
}
