import type { PatternDef } from '../../_shared/src/types.js';

/** Secret detection patterns — ordered by severity */
export const SECRET_PATTERNS: PatternDef[] = [
  {
    code: 'SECRET_ANTHROPIC_KEY',
    severity: 'critical',
    regex: /sk-ant-[a-zA-Z0-9_-]{20,}/,
    description: 'Anthropic API key',
    fixHint: 'Move to Supabase Edge Function env variable. Never include in client code.',
  },
  {
    code: 'SECRET_OPENAI_KEY',
    severity: 'critical',
    regex: /sk-[a-zA-Z0-9]{20,}/,
    description: 'OpenAI API key',
    fixHint: 'Move to server-side env variable. Never include in client code.',
  },
  {
    code: 'SECRET_AWS_KEY',
    severity: 'critical',
    regex: /AKIA[0-9A-Z]{16}/,
    description: 'AWS Access Key ID',
    fixHint: 'Remove from source. Use IAM roles or environment variables.',
  },
  {
    code: 'SECRET_PRIVATE_KEY',
    severity: 'critical',
    regex: /-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----/,
    description: 'Private key material',
    fixHint: 'Never commit private keys. Use secret management service.',
  },
  {
    code: 'SECRET_FIREBASE_SA',
    severity: 'critical',
    regex: /"type"\s*:\s*"service_account"/,
    description: 'Firebase service account JSON',
    fixHint: 'Never embed service account JSON in source. Use environment variable.',
  },
  {
    code: 'SECRET_PAYMENT_KEY',
    severity: 'critical',
    regex: /(?:test_sk_|live_sk_|imp_)[a-zA-Z0-9]{10,}/,
    description: 'Payment service secret key (Toss/PortOne)',
    fixHint: 'Payment secrets must only exist in Edge Functions. Remove from client.',
  },
  {
    code: 'SECRET_SUPABASE_SERVICE_ROLE',
    severity: 'critical',
    regex: /service_role['":\s]+eyJ[a-zA-Z0-9_-]{30,}/,
    description: 'Supabase service_role key in client code',
    fixHint: 'service_role keys must only exist in Edge Functions. Remove from client code.',
  },
  {
    code: 'SECRET_JWT_HARDCODED',
    severity: 'high',
    regex: /['"]eyJ[a-zA-Z0-9_-]{30,}\.[a-zA-Z0-9_-]{30,}\.[a-zA-Z0-9_-]{20,}['"]/,
    description: 'Hardcoded JWT token',
    fixHint: 'Remove hardcoded JWT. Use runtime auth token from Supabase client.',
  },
  {
    code: 'SECRET_GENERIC_API_KEY',
    severity: 'high',
    regex: /(?:api[_-]?key|apikey)\s*[:=]\s*['"][a-zA-Z0-9_-]{16,}['"]/i,
    description: 'Hardcoded API key assignment',
    fixHint: 'Use environment variable or --dart-define injection.',
  },
  {
    code: 'SECRET_PASSWORD_URL',
    severity: 'high',
    regex: /(?:postgresql|mysql|mongodb|redis):\/\/[^:]+:[^@\s]{8,}@/,
    description: 'Password in database connection string',
    fixHint: 'Use environment variable for connection string.',
  },
  {
    code: 'SECRET_SENTRY_AUTH',
    severity: 'high',
    regex: /sntrys_[a-zA-Z0-9]{20,}/,
    description: 'Sentry auth token',
    fixHint: 'Move to CI/CD secrets.',
  },
  {
    code: 'SECRET_RESEND_KEY',
    severity: 'high',
    regex: /re_[a-zA-Z0-9]{20,}/,
    description: 'Resend API key',
    fixHint: 'Move to server-side environment variable.',
  },
  {
    code: 'SECRET_PASSWORD_ASSIGN',
    severity: 'medium',
    regex: /(?:password|passwd|pwd)\s*[:=]\s*['"][^'"]{8,}['"]/i,
    description: 'Hardcoded password assignment',
    fixHint: 'Use environment variable or secret manager.',
  },
];

/** Patterns that detect env variable exposure/logging */
export const ENV_LEAK_PATTERNS: PatternDef[] = [
  {
    code: 'LEAK_PRINT_KEY',
    severity: 'high',
    regex: /(?:print|debugPrint|log|console\.log|console\.error)\s*\([^)]*(?:api[_-]?key|secret|token|password|anthropic|service_role)/i,
    description: 'Logging statement may expose sensitive value',
    fixHint: 'Remove sensitive values from log output. Use redaction.',
  },
  {
    code: 'LEAK_RESPONSE_KEY',
    severity: 'critical',
    regex: /(?:Response|jsonEncode|json|body)\s*[.(][^;]*(?:api[_-]?key|secret|service_role)/i,
    description: 'Sensitive value may appear in HTTP response',
    fixHint: 'Never include secrets in API responses.',
  },
  {
    code: 'LEAK_URL_PARAM',
    severity: 'medium',
    regex: /[?&](?:api[_-]?key|token|secret)=[^&\s'"]+/i,
    description: 'Secret in URL query parameter',
    fixHint: 'Pass secrets via headers, not URL parameters.',
  },
  {
    code: 'LEAK_HEADER_HARDCODE',
    severity: 'high',
    regex: /['"](?:x-api-key|authorization|api-key)['"]\s*:\s*['"][a-zA-Z0-9_-]{10,}['"]/i,
    description: 'Hardcoded API key in HTTP header',
    fixHint: 'Use environment variable for API keys in headers.',
  },
];

/** File extensions to scan */
export const SCANNABLE_EXTENSIONS = new Set([
  '.dart', '.ts', '.js', '.tsx', '.jsx',
  '.json', '.yaml', '.yml', '.toml',
  '.env', '.sh', '.bat', '.ps1',
  '.html', '.xml', '.sql',
  '.py', '.rb', '.go',
]);

/** Paths/patterns to skip during scanning */
export const SCAN_EXCLUSIONS: string[] = [
  'node_modules',
  'build',
  'dist',
  '.dart_tool',
  '.pub-cache',
  '.pub',
  'stitch',
  '.firebase',
  '.git',
  '.env.example',
];
