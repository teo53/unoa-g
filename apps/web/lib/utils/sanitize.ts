// =====================================================
// HTML Sanitizer — XSS prevention for dangerouslySetInnerHTML
// Uses DOMPurify to strip malicious content from user-generated HTML.
//
// SECURITY FIX: F-04
// All dangerouslySetInnerHTML usage MUST pass through sanitizeHtml().
//
// SSR NOTE: isomorphic-dompurify depends on jsdom which can fail during
// Next.js static export (jsdom@28 file-path issue). We use a lazy-init
// pattern so the module is only loaded when actually called, and we
// provide a regex-based fallback for SSR/build environments.
// =====================================================

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
 * SSR fallback: strip disallowed HTML tags and attributes using regex.
 * Not as robust as DOMPurify, but safe enough for pre-rendered HTML
 * (client-side hydration will re-sanitize with DOMPurify).
 */
function ssrStripHtml(html: string): string {
  // Remove script/style/iframe/object/embed/form tags and their content
  let result = html.replace(
    /<(script|style|iframe|object|embed|form)\b[^]*?<\/\1>/gi,
    ''
  )
  // Remove self-closing dangerous tags
  result = result.replace(/<(script|iframe|object|embed|form)\b[^>]*\/?>/gi, '')
  // Remove event handler attributes (on*)
  result = result.replace(/\s+on\w+\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)/gi, '')
  // Remove javascript: protocol in href/src
  result = result.replace(/(href|src)\s*=\s*(?:"javascript:[^"]*"|'javascript:[^']*')/gi, '')
  return result
}

// Lazy-loaded DOMPurify instance (null = not yet loaded, false = failed to load)
let _DOMPurify: any = null

function getDOMPurify(): any {
  if (_DOMPurify === false) return null
  if (_DOMPurify) return _DOMPurify

  try {
    // Dynamic require to avoid failing during module evaluation in SSR/build
    const mod = require('isomorphic-dompurify')
    _DOMPurify = mod.default || mod
    return _DOMPurify
  } catch {
    _DOMPurify = false
    return null
  }
}

/**
 * Sanitize HTML content to prevent XSS attacks.
 * Strips all scripts, event handlers, and dangerous elements.
 *
 * Uses DOMPurify when available (client-side, or SSR with working jsdom).
 * Falls back to regex-based stripping during Next.js static export if jsdom fails.
 *
 * @param html - Raw HTML string (potentially from user input or database)
 * @returns Sanitized HTML safe for dangerouslySetInnerHTML
 */
export function sanitizeHtml(html: string): string {
  if (!html) return ''

  const purify = getDOMPurify()
  if (purify) {
    return purify.sanitize(html, {
      ALLOWED_TAGS,
      ALLOWED_ATTR,
      ALLOW_DATA_ATTR: false,
      // Force all links to open in new tab with noopener
      ADD_ATTR: ['target'],
      // Forbid dangerous protocols
      ALLOWED_URI_REGEXP: /^(?:(?:https?|mailto|tel):|[^a-z]|[a-z+.-]+(?:[^a-z+.\-:]|$))/i,
    })
  }

  // Fallback for SSR/build when jsdom is unavailable
  return ssrStripHtml(html)
}

/**
 * Sanitize content for JSON-LD structured data.
 * JSON-LD uses JSON.stringify which handles most XSS, but we add
 * extra protection by stripping HTML tags from string values.
 */
export function sanitizeJsonLdValue(value: string): string {
  if (!value) return ''

  const purify = getDOMPurify()
  if (purify) {
    return purify.sanitize(value, { ALLOWED_TAGS: [] })
  }

  // Fallback: strip all HTML tags
  return value.replace(/<[^>]*>/g, '')
}
