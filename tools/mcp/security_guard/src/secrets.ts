import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';
import { getRepoRoot, toRelative } from '../../_shared/src/paths.js';
import { redactLine } from '../../_shared/src/mask.js';
import type { Finding, SecretScanReport, PatternDef } from '../../_shared/src/types.js';
import { SECRET_PATTERNS, SCANNABLE_EXTENSIONS, SCAN_EXCLUSIONS } from './patterns.js';

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
    // Skip excluded directories/files
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

/** Scan files for secret patterns */
export function scanSecrets(scanPaths?: string[]): SecretScanReport {
  const root = getRepoRoot();
  const dirs = scanPaths?.map(p => join(root, p)) ?? [
    join(root, 'lib'),
    join(root, 'supabase'),
    join(root, 'web'),
    join(root, 'android'),
    join(root, 'ios'),
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
      for (const pattern of SECRET_PATTERNS) {
        // Reset regex state
        pattern.regex.lastIndex = 0;
        if (pattern.regex.test(line)) {
          // Skip if it's a const String.fromEnvironment or defaultValue pattern
          if (isEnvironmentDeclaration(line)) continue;
          // Skip if it's in a comment explaining the pattern
          if (isDocComment(line)) continue;

          findings.push({
            severity: pattern.severity,
            code: pattern.code,
            file: toRelative(file, root),
            line: i + 1,
            message: pattern.description,
            fixHint: pattern.fixHint,
            snippetRedacted: redactLine(line.trim()),
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

/** Check if the line is a String.fromEnvironment / --dart-define declaration (not a hardcoded secret) */
function isEnvironmentDeclaration(line: string): boolean {
  return line.includes('String.fromEnvironment') ||
    line.includes('bool.fromEnvironment') ||
    line.includes('int.fromEnvironment') ||
    line.includes('--dart-define');
}

/** Check if line is a doc comment or markdown */
function isDocComment(line: string): boolean {
  const trimmed = line.trim();
  return trimmed.startsWith('//') ||
    trimmed.startsWith('///') ||
    trimmed.startsWith('*') ||
    trimmed.startsWith('- ') ||
    trimmed.startsWith('#');
}
