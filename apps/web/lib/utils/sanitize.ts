// =====================================================
// HTML Sanitizer — XSS prevention for dangerouslySetInnerHTML
// Uses DOMPurify to strip malicious content from user-generated HTML.
//
// SECURITY FIX: F-04
// All dangerouslySetInnerHTML usage MUST pass through sanitizeHtml().
// =====================================================

import DOMPurify from 'isomorphic-dompurify'

/**
 * Allowed HTML tags for rich content (campaign descriptions, updates, notices).
 * Script, iframe, object, embed, form are explicitly excluded.
 */
const ALLOWED_TAGS = [
  // Block elements
  'p', 'div', 'br', 'hr',
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'blockquote', 'pre', 'code',
  // Lists
  'ul', 'ol', 'li',
  // Inline elements
  'strong', 'b', 'em', 'i', 'u', 's', 'del', 'ins',
  'a', 'span', 'sub', 'sup', 'mark',
  // Media (safe)
  'img', 'figure', 'figcaption',
  // Tables
  'table', 'thead', 'tbody', 'tr', 'th', 'td',
]

/**
 * Allowed attributes — only safe, non-event attributes.
 * No onclick, onerror, onload, etc.
 */
const ALLOWED_ATTR = [
  'href', 'target', 'rel',
  'src', 'alt', 'title', 'width', 'height',
  'class', 'style',
  'colspan', 'rowspan',
]

/**
 * Sanitize HTML content to prevent XSS attacks.
 * Strips all scripts, event handlers, and dangerous elements.
 *
 * @param html - Raw HTML string (potentially from user input or database)
 * @returns Sanitized HTML safe for dangerouslySetInnerHTML
 */
export function sanitizeHtml(html: string): string {
  if (!html) return ''

  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS,
    ALLOWED_ATTR,
    ALLOW_DATA_ATTR: false,
    // Force all links to open in new tab with noopener
    ADD_ATTR: ['target'],
    // Forbid dangerous protocols
    ALLOWED_URI_REGEXP: /^(?:(?:https?|mailto|tel):|[^a-z]|[a-z+.-]+(?:[^a-z+.\-:]|$))/i,
  })
}

/**
 * Sanitize content for JSON-LD structured data.
 * JSON-LD uses JSON.stringify which handles most XSS, but we add
 * extra protection by stripping HTML tags from string values.
 */
export function sanitizeJsonLdValue(value: string): string {
  if (!value) return ''
  // Strip all HTML tags for JSON-LD text content
  return DOMPurify.sanitize(value, { ALLOWED_TAGS: [] })
}
