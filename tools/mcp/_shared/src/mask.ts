/** Mask sensitive values in output strings */

const MASK_PATTERNS: RegExp[] = [
  // Anthropic keys
  /sk-ant-[a-zA-Z0-9_-]{10,}/g,
  // OpenAI keys
  /sk-[a-zA-Z0-9]{20,}/g,
  // AWS keys
  /AKIA[0-9A-Z]{16}/g,
  // Generic long tokens (JWT-like)
  /eyJ[a-zA-Z0-9_-]{30,}\.[a-zA-Z0-9_-]{30,}\.[a-zA-Z0-9_-]{20,}/g,
  // Supabase service role pattern
  /(service_role['":\s]*)(eyJ[a-zA-Z0-9_-]{20,})/g,
  // Payment keys
  /(?:test_sk_|live_sk_|imp_)[a-zA-Z0-9]{10,}/g,
  // Private keys
  /(-----BEGIN [A-Z ]*PRIVATE KEY-----)([\s\S]*?)(-----END [A-Z ]*PRIVATE KEY-----)/g,
  // Sentry auth
  /sntrys_[a-zA-Z0-9]{20,}/g,
  // Resend
  /re_[a-zA-Z0-9]{20,}/g,
  // Generic password in connection strings
  /((?:postgresql|mysql|mongodb|redis):\/\/[^:]+:)([^@\s]{4,})(@)/g,
];

/** Replace any detected secrets in a string with ****REDACTED**** */
export function maskSecrets(input: string): string {
  let result = input;
  for (const pattern of MASK_PATTERNS) {
    // Reset lastIndex for global patterns
    pattern.lastIndex = 0;
    result = result.replace(pattern, (match, ...groups) => {
      // For patterns with capture groups (like connection strings), preserve structure
      if (groups.length >= 3 && typeof groups[0] === 'string' && typeof groups[2] === 'string') {
        return `${groups[0]}****REDACTED****${groups[2]}`;
      }
      return '****REDACTED****';
    });
  }
  return result;
}

/** Redact a single line for snippet display — show context but mask the secret value */
export function redactLine(line: string): string {
  return maskSecrets(line);
}
