import { resolve, sep, posix } from 'node:path';
import { execFileSync } from 'node:child_process';

let _repoRoot: string | undefined;

/** Detect repo root using git rev-parse. Cached after first call. */
export function getRepoRoot(): string {
  if (_repoRoot) return _repoRoot;
  try {
    const raw = execFileSync('git', ['rev-parse', '--show-toplevel'], {
      encoding: 'utf-8',
      timeout: 5000,
    }).trim();
    _repoRoot = resolve(raw);
  } catch {
    // Fallback: use cwd
    _repoRoot = resolve(process.cwd());
  }
  return _repoRoot;
}

/** Convert absolute path to repo-relative with forward slashes */
export function toRelative(absPath: string, root?: string): string {
  const r = root ?? getRepoRoot();
  const normalized = resolve(absPath);
  const normalizedRoot = resolve(r);
  const rel = normalized.startsWith(normalizedRoot)
    ? normalized.slice(normalizedRoot.length + 1)
    : normalized;
  return rel.split(sep).join(posix.sep);
}
