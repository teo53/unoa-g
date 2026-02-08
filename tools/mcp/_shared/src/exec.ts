import { execFile } from 'node:child_process';
import { platform } from 'node:os';
import { getRepoRoot } from './paths.js';
import { maskSecrets } from './mask.js';

/** Commands allowed to be executed */
const ALLOWED_COMMANDS = new Set(['flutter', 'dart', 'git']);

/** Characters that are never allowed in arguments */
const DANGEROUS_CHARS = /[;|&`$><]/;

export interface ExecResult {
  exitCode: number;
  stdout: string;
  stderr: string;
  durationMs: number;
  timedOut: boolean;
}

/**
 * Safely execute a command from the allowlist.
 * - Only allowed commands (flutter, dart, git) can be run
 * - Arguments are validated for shell metacharacters
 * - Output is truncated and secret-masked
 * - Uses execFile (not exec) to avoid shell injection
 */
export async function safeExec(
  cmd: string,
  args: string[],
  options?: { timeoutMs?: number; cwd?: string; maxOutputChars?: number }
): Promise<ExecResult> {
  if (!ALLOWED_COMMANDS.has(cmd)) {
    throw new Error(`Command not allowed: ${cmd}. Allowlist: ${[...ALLOWED_COMMANDS].join(', ')}`);
  }

  for (const arg of args) {
    if (DANGEROUS_CHARS.test(arg)) {
      throw new Error(`Dangerous characters in argument: ${arg}`);
    }
  }

  const timeoutMs = options?.timeoutMs ?? 120_000;
  const cwd = options?.cwd ?? getRepoRoot();
  const maxChars = options?.maxOutputChars ?? 2000;
  const isWindows = platform() === 'win32';

  const start = Date.now();

  return new Promise<ExecResult>((resolve) => {
    const child = execFile(
      cmd,
      args,
      {
        cwd,
        timeout: timeoutMs,
        maxBuffer: 10 * 1024 * 1024, // 10MB
        encoding: 'utf-8',
        // On Windows, flutter/dart are .bat files requiring shell
        shell: isWindows,
        windowsHide: true,
      },
      (error, stdout, stderr) => {
        const durationMs = Date.now() - start;
        const timedOut = error?.killed === true ||
          (error as NodeJS.ErrnoException)?.code === 'ETIMEDOUT';

        const exitCode = timedOut
          ? -1
          : (error as any)?.code === 'ENOENT'
            ? 127
            : typeof (error as any)?.code === 'number'
              ? (error as any).code
              : error
                ? (error as any).status ?? 1
                : 0;

        resolve({
          exitCode,
          stdout: maskSecrets(tail(stdout ?? '', maxChars)),
          stderr: maskSecrets(tail(stderr ?? '', maxChars)),
          durationMs,
          timedOut,
        });
      }
    );
  });
}

/** Return the last N characters of a string */
function tail(str: string, maxChars: number): string {
  if (str.length <= maxChars) return str;
  return '...(truncated)...\n' + str.slice(-maxChars);
}
