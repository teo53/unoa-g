import { NotionAPI } from 'notion-client';

const notion = new NotionAPI();

export async function crawlPublicPage(pageId: string) {
  const recordMap = await notion.getPage(pageId);
  return recordMap;
}

export function extractPageId(url: string): string {
  // URL 패턴 1: ?p=78e9896135d44cf8ad7718940e5f4863
  const pMatch = url.match(/[?&]p=([a-f0-9]{32})/i);
  if (pMatch) return pMatch[1];

  // URL 패턴 2: /PageName-78e9896135d44cf8ad7718940e5f4863
  const dashMatch = url.match(/([a-f0-9]{32})(?:\?|$|&)/i);
  if (dashMatch) return dashMatch[1];

  // URL 패턴 3: 하이픈 포함된 UUID 형식
  const uuidMatch = url.match(/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/i);
  if (uuidMatch) return uuidMatch[1].replace(/-/g, '');

  throw new Error('Invalid Notion URL - Cannot extract page ID');
}
