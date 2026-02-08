import { safeExec } from '../../_shared/src/exec.js';
import type { DiffSummary } from '../../_shared/src/types.js';

/** Categorize a file path */
function categorize(path: string): 'dart' | 'sql' | 'config' | 'typescript' | 'other' {
  if (path.endsWith('.dart')) return 'dart';
  if (path.endsWith('.sql')) return 'sql';
  if (path.endsWith('.ts') || path.endsWith('.tsx') || path.endsWith('.js') || path.endsWith('.jsx')) return 'typescript';
  if (path.endsWith('.yaml') || path.endsWith('.yml') || path.endsWith('.json') || path.endsWith('.toml') || path.endsWith('.lock')) return 'config';
  return 'other';
}

/** Detect risk flags from changed files */
function detectRiskFlags(files: string[]): string[] {
  const flags: string[] = [];
  if (files.some(f => f.includes('supabase/migrations/'))) flags.push('migration_changed');
  if (files.some(f => f.includes('rls') || f.includes('policy'))) flags.push('rls_policy_modified');
  if (files.some(f => f === 'pubspec.yaml' || f === 'pubspec.lock')) flags.push('pubspec_changed');
  if (files.some(f => f.includes('.mcp.json') || f.includes('firebase.json'))) flags.push('config_changed');
  if (files.some(f => f.includes('supabase/functions/'))) flags.push('edge_function_changed');
  if (files.some(f => f.includes('app_config.dart') || f.includes('business_config.dart'))) flags.push('core_config_changed');
  if (files.some(f => f.includes('app_router.dart'))) flags.push('routing_changed');
  if (files.some(f => f.includes('security') || f.includes('auth'))) flags.push('security_related');
  return flags;
}

/** Get diff summary between current branch and base */
export async function diffSummary(base?: string): Promise<DiffSummary> {
  const baseBranch = base ?? 'main';

  // Get file list with stats
  const statResult = await safeExec('git', ['diff', '--stat', `${baseBranch}...HEAD`], { maxOutputChars: 10000 });
  const nameResult = await safeExec('git', ['diff', '--name-only', `${baseBranch}...HEAD`], { maxOutputChars: 10000 });
  const numstatResult = await safeExec('git', ['diff', '--numstat', `${baseBranch}...HEAD`], { maxOutputChars: 10000 });

  // Parse changed files
  const files = nameResult.stdout.trim().split('\n').filter(Boolean);

  // Parse insertions/deletions
  let insertions = 0;
  let deletions = 0;
  for (const line of numstatResult.stdout.trim().split('\n')) {
    if (!line) continue;
    const parts = line.split('\t');
    if (parts.length >= 2) {
      const ins = parseInt(parts[0], 10);
      const del = parseInt(parts[1], 10);
      if (!isNaN(ins)) insertions += ins;
      if (!isNaN(del)) deletions += del;
    }
  }

  // Categorize files
  const filesByCategory: DiffSummary['filesByCategory'] = {
    dart: [], sql: [], config: [], typescript: [], other: [],
  };
  for (const file of files) {
    const cat = categorize(file);
    filesByCategory[cat].push(file);
  }

  const riskFlags = detectRiskFlags(files);

  const summary = `${files.length} file(s) changed (+${insertions}/-${deletions}) vs ${baseBranch}. ` +
    `Dart: ${filesByCategory.dart.length}, SQL: ${filesByCategory.sql.length}, ` +
    `TS: ${filesByCategory.typescript.length}, Config: ${filesByCategory.config.length}` +
    (riskFlags.length > 0 ? `. Risks: ${riskFlags.join(', ')}` : '');

  return {
    base: baseBranch,
    filesChanged: files.length,
    insertions,
    deletions,
    filesByCategory,
    riskFlags,
    summary,
  };
}
