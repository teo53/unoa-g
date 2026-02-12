import DOMPurify from 'isomorphic-dompurify'

/**
 * HTML Sanitizer — XSS 방어용
 *
 * 허용 태그 화이트리스트 기반으로 위험한 요소/속성을 제거합니다.
 * dangerouslySetInnerHTML 사용 전 반드시 이 함수를 거쳐야 합니다.
 */

const ALLOWED_TAGS = [
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'p', 'br', 'hr',
  'ul', 'ol', 'li',
  'strong', 'b', 'em', 'i', 'u', 's', 'del',
  'a', 'img',
  'table', 'thead', 'tbody', 'tr', 'th', 'td',
  'blockquote', 'pre', 'code',
  'div', 'span',
  'figure', 'figcaption',
]

const ALLOWED_ATTR = [
  'href', 'target', 'rel',
  'src', 'alt', 'width', 'height',
  'class', 'id',
]

export function sanitizeHtml(dirty: string | null | undefined): string {
  if (!dirty) return ''
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS,
    ALLOWED_ATTR,
    ALLOW_DATA_ATTR: false,
    ADD_ATTR: ['target'],
    // a 태그에 rel="noopener noreferrer" 자동 추가
    FORBID_ATTR: ['style', 'onerror', 'onload', 'onclick', 'onmouseover'],
  })
}
