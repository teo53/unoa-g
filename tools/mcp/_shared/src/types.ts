/** Common output types for all MCP stability gate servers */

export interface Finding {
  severity: 'critical' | 'error' | 'high' | 'warning' | 'medium' | 'low' | 'info';
  code: string;
  file: string;
  line?: number;
  message: string;
  fixHint: string;
  snippetRedacted?: string;
}

export interface StepResult {
  name: string;
  cmd: string;
  exitCode: number;
  durationMs: number;
  stdoutTail: string;
  stderrTail: string;
  ok: boolean;
}

export interface RepoDoctorReport {
  ok: boolean;
  steps: StepResult[];
  summary: string;
  errorCode?: string;
  nextActions: string[];
  durationMs: number;
}

export interface DiffSummary {
  base: string;
  filesChanged: number;
  insertions: number;
  deletions: number;
  filesByCategory: {
    dart: string[];
    sql: string[];
    config: string[];
    typescript: string[];
    other: string[];
  };
  riskFlags: string[];
  summary: string;
}

export interface FileChunk {
  path: string;
  status: string;
  insertions: number;
  deletions: number;
  diff: string;
  truncatedAt?: number;
}

export interface DiffChunksResult {
  base: string;
  totalFiles: number;
  includedFiles: number;
  truncated: boolean;
  chunks: FileChunk[];
}

export interface ChecklistItem {
  category: string;
  item: string;
  required: boolean;
  triggered_by: string;
}

export interface PrChecklistResult {
  base: string;
  checklist: ChecklistItem[];
  riskLevel: 'low' | 'medium' | 'high';
  summary: string;
}

export interface MigrationLintReport {
  ok: boolean;
  totalFiles: number;
  findings: Finding[];
}

export interface RlsAuditReport {
  ok: boolean;
  totalTables: number;
  tablesWithRls: number;
  tablesMissingRls: string[];
  findings: Finding[];
}

export interface EdgeFunctionReport {
  ok: boolean;
  totalFunctions: number;
  findings: Finding[];
}

export interface PrepushReport {
  ok: boolean;
  sections: {
    migrationLint: MigrationLintReport;
    rlsAudit: RlsAuditReport;
    edgeFunctions: EdgeFunctionReport;
  };
  summary: string;
}

export interface SecretScanReport {
  ok: boolean;
  scannedFiles: number;
  findings: Finding[];
}

export interface PrecommitReport {
  ok: boolean;
  secretsScan: SecretScanReport;
  envLeaksScan: SecretScanReport;
  summary: string;
  blockReason?: string;
}

export interface PatternDef {
  code: string;
  severity: Finding['severity'];
  regex: RegExp;
  description: string;
  fixHint: string;
}
