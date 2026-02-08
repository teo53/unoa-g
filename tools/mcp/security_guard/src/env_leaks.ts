import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';
import { getRepoRoot, toRelative } from '../../_shared/src/paths.js';
import { redactLine } from '../../_shared/src/mask.js';
import type { Finding, SecretScanReport } from '../../_shared/src/types.js';
import { ENV_LEAK_PATTERNS, SCANNABLE_EXTENSIONS, SCAN_EXCLUSIONS } from './patterns.js';

/** Recursively collect files to scan */
function collectFiles(dir: string): string[] {
  const results: string[] = [];
  let entries: string[];
  try {
    entries = readdirSync(dir);
  } catch {
    return results;
  }

  for (const entry of entries) {
    if (SCAN_EXCLUSIONS.some(ex => entry === ex || entry.startsWith(ex + '.'))) {
      continue;
    }
    const fullPath = join(dir, entry);
    let stat;
    try {
      stat = statSync(fullPath);
    } catch {
      continue;
    }

    if (stat.isDirectory()) {
      results.push(...collectFiles(fullPath));
    } else if (stat.isFile()) {
      const ext = extname(entry).toLowerCase();
      if (SCANNABLE_EXTENSIONS.has(ext)) {
        results.push(fullPath);
      }
    }
  }
  return results;
}

/** Scan files for env variable leak patterns */
export function scanEnvLeaks(scanPaths?: string[]): SecretScanReport {
  const root = getRepoRoot();
  const dirs = scanPaths?.map(p => join(root, p)) ?? [
    join(root, 'lib'),
    join(root, 'supabase'),
    join(root, 'tools'),
  ];

  const files: string[] = [];
  for (const dir of dirs) {
    files.push(...collectFiles(dir));
  }

  const findings: Finding[] = [];

  for (const file of files) {
    let content: string;
    try {
      content = readFileSync(file, 'utf-8');
    } catch {
      continue;
    }

    const lines = content.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      // Skip comment lines
      const trimmed = line.trim();
      if (trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('#')) {
        continue;
      }

      for (const pattern of ENV_LEAK_PATTERNS) {
        pattern.regex.lastIndex = 0;
        if (pattern.regex.test(line)) {
          findings.push({
            severity: pattern.severity,
            code: pattern.code,
            file: toRelative(file, root),
            line: i + 1,
            message: pattern.description,
            fixHint: pattern.fixHint,
            snippetRedacted: redactLine(trimmed),
          });
        }
      }
    }
  }

  return {
    ok: findings.length === 0,
    scannedFiles: files.length,
    findings,
  };
}
