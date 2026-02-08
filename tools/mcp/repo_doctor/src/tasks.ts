export interface TaskDef {
  name: string;
  cmd: string;
  args: string[];
  timeoutMs: number;
  errorCode: string;
  description: string;
}

/** Allowlisted tasks — only these commands can be executed */
export const ALLOWED_TASKS: Record<string, TaskDef> = {
  analyze: {
    name: 'analyze',
    cmd: 'flutter',
    args: ['analyze'],
    timeoutMs: 120_000,
    errorCode: 'ANALYZE_FAIL',
    description: 'Static analysis of Dart code',
  },
  test: {
    name: 'test',
    cmd: 'flutter',
    args: ['test'],
    timeoutMs: 300_000,
    errorCode: 'TEST_FAIL',
    description: 'Run widget and unit tests',
  },
  build: {
    name: 'build',
    cmd: 'flutter',
    args: ['build', 'web', '--release'],
    timeoutMs: 300_000,
    errorCode: 'BUILD_FAIL',
    description: 'Production web build',
  },
  format: {
    name: 'format',
    cmd: 'dart',
    args: ['format', '.', '--set-exit-if-changed'],
    timeoutMs: 60_000,
    errorCode: 'FORMAT_FAIL',
    description: 'Check code formatting',
  },
};

/** Task execution order for run_all */
export const RUN_ALL_ORDER: string[] = ['analyze', 'test', 'build', 'format'];
