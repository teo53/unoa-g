import { safeExec } from '../../_shared/src/exec.js';
import type { RepoDoctorReport, StepResult } from '../../_shared/src/types.js';
import { ALLOWED_TASKS, RUN_ALL_ORDER } from './tasks.js';

/** Run a single allowlisted task */
async function executeTask(taskName: string): Promise<StepResult> {
  const task = ALLOWED_TASKS[taskName];
  if (!task) {
    return {
      name: taskName,
      cmd: 'unknown',
      exitCode: 1,
      durationMs: 0,
      stdoutTail: '',
      stderrTail: `Unknown task: ${taskName}. Allowed: ${Object.keys(ALLOWED_TASKS).join(', ')}`,
      ok: false,
    };
  }

  const result = await safeExec(task.cmd, task.args, {
    timeoutMs: task.timeoutMs,
  });

  const cmd = `${task.cmd} ${task.args.join(' ')}`;
  const exitCode = result.timedOut ? -1 : result.exitCode;

  return {
    name: task.name,
    cmd,
    exitCode,
    durationMs: result.durationMs,
    stdoutTail: result.stdout,
    stderrTail: result.stderr,
    ok: exitCode === 0,
  };
}

/** Generate next actions based on failures */
function getNextActions(steps: StepResult[]): string[] {
  const actions: string[] = [];
  for (const step of steps) {
    if (step.ok) continue;
    const task = ALLOWED_TASKS[step.name];
    if (!task) continue;

    switch (task.errorCode) {
      case 'ANALYZE_FAIL':
        actions.push('Fix flutter analyze issues. Run: flutter analyze');
        break;
      case 'TEST_FAIL':
        actions.push('Fix failing tests. Run: flutter test --reporter=expanded');
        break;
      case 'BUILD_FAIL':
        actions.push('Fix build errors. Run: flutter build web --release');
        break;
      case 'FORMAT_FAIL':
        actions.push('Auto-format code. Run: dart format .');
        break;
    }
  }
  return actions;
}

/** Run all quality checks sequentially */
export async function runAll(): Promise<RepoDoctorReport> {
  const totalStart = Date.now();
  const steps: StepResult[] = [];
  let firstError: string | undefined;

  for (const taskName of RUN_ALL_ORDER) {
    const step = await executeTask(taskName);
    steps.push(step);

    if (!step.ok && !firstError) {
      firstError = ALLOWED_TASKS[taskName]?.errorCode ?? 'UNKNOWN_FAIL';
    }
  }

  const totalDuration = Date.now() - totalStart;
  const ok = steps.every(s => s.ok);
  const passed = steps.filter(s => s.ok).length;
  const failed = steps.filter(s => !s.ok).length;

  return {
    ok,
    steps,
    summary: ok
      ? `All ${steps.length} checks passed in ${(totalDuration / 1000).toFixed(1)}s`
      : `${failed}/${steps.length} check(s) failed. First error: ${firstError}`,
    errorCode: firstError,
    nextActions: getNextActions(steps),
    durationMs: totalDuration,
  };
}

/** Run a single quality check */
export async function runSingle(taskName: string): Promise<RepoDoctorReport> {
  const totalStart = Date.now();

  if (!ALLOWED_TASKS[taskName]) {
    return {
      ok: false,
      steps: [],
      summary: `Unknown task: ${taskName}. Allowed: ${Object.keys(ALLOWED_TASKS).join(', ')}`,
      errorCode: 'UNKNOWN_TASK',
      nextActions: [`Use one of: ${Object.keys(ALLOWED_TASKS).join(', ')}`],
      durationMs: 0,
    };
  }

  const step = await executeTask(taskName);
  const totalDuration = Date.now() - totalStart;

  return {
    ok: step.ok,
    steps: [step],
    summary: step.ok
      ? `${taskName} passed in ${(step.durationMs / 1000).toFixed(1)}s`
      : `${taskName} failed (exit code ${step.exitCode})`,
    errorCode: step.ok ? undefined : ALLOWED_TASKS[taskName].errorCode,
    nextActions: getNextActions([step]),
    durationMs: totalDuration,
  };
}
