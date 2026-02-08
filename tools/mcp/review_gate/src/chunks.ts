import { safeExec } from '../../_shared/src/exec.js';
import type { DiffChunksResult, FileChunk } from '../../_shared/src/types.js';

/** Get diff chunked by file with byte budget */
export async function diffChunks(base?: string, maxBytes?: number): Promise<DiffChunksResult> {
  const baseBranch = base ?? 'main';
  const budget = maxBytes ?? 100_000;

  // Get file list with status
  const nameStatusResult = await safeExec('git', ['diff', '--name-status', `${baseBranch}...HEAD`], { maxOutputChars: 50000 });

  const fileEntries: { path: string; status: string }[] = [];
  for (const line of nameStatusResult.stdout.trim().split('\n')) {
    if (!line) continue;
    const parts = line.split('\t');
    if (parts.length >= 2) {
      const statusChar = parts[0].charAt(0);
      const statusMap: Record<string, string> = {
        'A': 'added', 'M': 'modified', 'D': 'deleted', 'R': 'renamed',
      };
      fileEntries.push({
        status: statusMap[statusChar] ?? 'modified',
        path: parts[parts.length - 1],
      });
    }
  }

  const chunks: FileChunk[] = [];
  let usedBytes = 0;
  let truncated = false;

  for (const entry of fileEntries) {
    if (usedBytes >= budget) {
      truncated = true;
      break;
    }

    // Get per-file diff
    const fileDiffResult = await safeExec(
      'git',
      ['diff', `${baseBranch}...HEAD`, '--', entry.path],
      { maxOutputChars: 50000 }
    );

    // Parse numstat for this file
    const numstatResult = await safeExec(
      'git',
      ['diff', '--numstat', `${baseBranch}...HEAD`, '--', entry.path],
      { maxOutputChars: 1000 }
    );

    let insertions = 0;
    let deletions = 0;
    const numLine = numstatResult.stdout.trim();
    if (numLine) {
      const parts = numLine.split('\t');
      if (parts.length >= 2) {
        const ins = parseInt(parts[0], 10);
        const del = parseInt(parts[1], 10);
        if (!isNaN(ins)) insertions = ins;
        if (!isNaN(del)) deletions = del;
      }
    }

    let diff = fileDiffResult.stdout;
    const diffBytes = Buffer.byteLength(diff, 'utf-8');
    const remainingBudget = budget - usedBytes;
    let truncatedAt: number | undefined;

    if (diffBytes > remainingBudget) {
      diff = diff.slice(0, remainingBudget);
      truncatedAt = remainingBudget;
      truncated = true;
    }

    usedBytes += Buffer.byteLength(diff, 'utf-8');

    chunks.push({
      path: entry.path,
      status: entry.status,
      insertions,
      deletions,
      diff,
      truncatedAt,
    });
  }

  return {
    base: baseBranch,
    totalFiles: fileEntries.length,
    includedFiles: chunks.length,
    truncated,
    chunks,
  };
}
