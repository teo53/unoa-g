import type { PrecommitReport } from '../../_shared/src/types.js';
import { scanSecrets } from './secrets.js';
import { scanEnvLeaks } from './env_leaks.js';

/** Combined security gate — returns ok=false if any critical/high findings */
export function precommitGate(): PrecommitReport {
  const secretsScan = scanSecrets();
  const envLeaksScan = scanEnvLeaks();

  const criticalOrHigh = [
    ...secretsScan.findings,
    ...envLeaksScan.findings,
  ].filter(f => f.severity === 'critical' || f.severity === 'high');

  const ok = criticalOrHigh.length === 0;

  const totalFindings = secretsScan.findings.length + envLeaksScan.findings.length;
  let summary: string;
  if (ok && totalFindings === 0) {
    summary = 'No security issues found. Safe to commit.';
  } else if (ok) {
    summary = `${totalFindings} low/medium findings. Review recommended but not blocking.`;
  } else {
    summary = `BLOCKED: ${criticalOrHigh.length} critical/high security finding(s). Fix before committing.`;
  }

  return {
    ok,
    secretsScan,
    envLeaksScan,
    summary,
    blockReason: ok ? undefined : `${criticalOrHigh.length} critical/high finding(s): ${criticalOrHigh.map(f => f.code).join(', ')}`,
  };
}
