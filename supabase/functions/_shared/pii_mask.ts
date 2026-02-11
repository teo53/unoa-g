/**
 * PII Masking Helper for LLM Content
 *
 * Masks personally identifiable information before sending content
 * to external AI providers (e.g., Anthropic Claude API).
 *
 * Targets Korean PII patterns:
 * - Phone numbers (010-XXXX-XXXX)
 * - Email addresses
 * - Resident registration numbers (주민등록번호)
 * - Credit card numbers
 * - Bank account numbers
 */

// Korean phone numbers: 010-1234-5678, 01012345678, 010.1234.5678
const PHONE_REGEX = /01[016789][-.\s]?\d{3,4}[-.\s]?\d{4}/g

// Email addresses
const EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g

// Korean resident registration number: 000000-0000000
const RRN_REGEX = /\d{6}[-\s]?\d{7}/g

// Credit card numbers: 1234-5678-9012-3456 or 16 consecutive digits
const CARD_REGEX = /\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}/g

// Bank account numbers: 10-14 digit sequences with dashes (e.g., 110-123-456789)
const ACCOUNT_REGEX = /\d{2,6}[-]\d{2,6}[-]\d{2,8}/g

/**
 * Mask PII patterns in text before sending to external LLM.
 * Returns the text with PII replaced by descriptive placeholders.
 */
export function maskPII(text: string): string {
  if (!text) return text

  return text
    // Order matters: RRN before phone (RRN is 13 digits, phone is 10-11)
    .replace(RRN_REGEX, '[주민번호]')
    .replace(CARD_REGEX, '[카드번호]')
    .replace(ACCOUNT_REGEX, '[계좌번호]')
    .replace(PHONE_REGEX, '[전화번호]')
    .replace(EMAIL_REGEX, '[이메일]')
}

/**
 * Check if text likely contains PII patterns.
 * Useful for logging/metrics without modifying the text.
 */
export function containsPII(text: string): boolean {
  if (!text) return false

  return (
    PHONE_REGEX.test(text) ||
    EMAIL_REGEX.test(text) ||
    RRN_REGEX.test(text) ||
    CARD_REGEX.test(text) ||
    ACCOUNT_REGEX.test(text)
  )
}
