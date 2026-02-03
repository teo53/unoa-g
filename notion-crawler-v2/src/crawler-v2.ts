import { NotionAPI } from 'notion-client';
import { ExtendedRecordMap } from 'notion-types';

const notion = new NotionAPI();

export interface CrawlOptions {
  recursive?: boolean;      // 하위 페이지 재귀 크롤링
  maxDepth?: number;        // 최대 깊이 (기본: 3)
  delay?: number;           // 요청 간 딜레이 ms (기본: 500)
  includeRaw?: boolean;     // raw recordMap 포함 여부
}

export interface CrawledPage {
  id: string;
  url: string;
  depth: number;
  recordMap: ExtendedRecordMap;
  crawledAt: string;
}

export async function crawlPublicPage(pageId: string): Promise<ExtendedRecordMap> {
  const normalizedId = normalizePageId(pageId);
  const recordMap = await notion.getPage(normalizedId);
  return recordMap;
}

export async function crawlRecursive(
  pageId: string,
  options: CrawlOptions = {}
): Promise<Map<string, CrawledPage>> {
  const {
    recursive = true,
    maxDepth = 3,
    delay = 500,
    includeRaw = true
  } = options;

  const results = new Map<string, CrawledPage>();
  const queue: { id: string; depth: number }[] = [{ id: pageId, depth: 0 }];
  const visited = new Set<string>();

  while (queue.length > 0) {
    const current = queue.shift()!;
    const normalizedId = normalizePageId(current.id);

    if (visited.has(normalizedId)) continue;
    if (current.depth > maxDepth) continue;

    visited.add(normalizedId);

    try {
      console.log(`[Depth ${current.depth}] 크롤링: ${normalizedId}`);
      
      const recordMap = await notion.getPage(normalizedId);
      
      results.set(normalizedId, {
        id: normalizedId,
        url: `https://notion.so/${normalizedId}`,
        depth: current.depth,
        recordMap: includeRaw ? recordMap : {} as ExtendedRecordMap,
        crawledAt: new Date().toISOString()
      });

      // 재귀 크롤링이 활성화된 경우 하위 페이지 추가
      if (recursive && current.depth < maxDepth) {
        const childPageIds = extractChildPageIds(recordMap);
        
        for (const childId of childPageIds) {
          if (!visited.has(normalizePageId(childId))) {
            queue.push({ id: childId, depth: current.depth + 1 });
          }
        }
      }

      // Rate limiting
      if (queue.length > 0 && delay > 0) {
        await sleep(delay);
      }

    } catch (error) {
      console.error(`[Error] ${normalizedId} 크롤링 실패:`, error);
    }
  }

  return results;
}

// 하위 페이지 ID 추출
function extractChildPageIds(recordMap: ExtendedRecordMap): string[] {
  const pageIds: string[] = [];
  const seenIds = new Set<string>();

  // 블록에서 페이지 타입 찾기
  for (const [blockId, blockData] of Object.entries(recordMap.block)) {
    const block = blockData?.value;
    if (!block) continue;

    // 하위 페이지 블록
    if (block.type === 'page' && block.parent_table === 'block') {
      if (!seenIds.has(block.id)) {
        seenIds.add(block.id);
        pageIds.push(block.id);
      }
    }

    // collection_view 내 페이지들
    if (block.type === 'collection_view' || block.type === 'collection_view_page') {
      // collection_query에서 페이지 ID들 추출
    }
  }

  // collection_query에서 데이터베이스 아이템들 추출
  if (recordMap.collection_query) {
    for (const collectionQueries of Object.values(recordMap.collection_query)) {
      for (const queryData of Object.values(collectionQueries as any)) {
        const blockIds = (queryData as any)?.collection_group_results?.blockIds || [];
        for (const id of blockIds) {
          if (!seenIds.has(id)) {
            seenIds.add(id);
            pageIds.push(id);
          }
        }
      }
    }
  }

  // collection 내 페이지들 (parent_table === 'collection')
  for (const [blockId, blockData] of Object.entries(recordMap.block)) {
    const block = blockData?.value;
    if (!block) continue;

    if ((block as any).parent_table === 'collection' && block.type === 'page') {
      if (!seenIds.has(block.id)) {
        seenIds.add(block.id);
        pageIds.push(block.id);
      }
    }
  }

  return pageIds;
}

// Page ID 정규화 (하이픈 제거)
export function normalizePageId(pageId: string): string {
  return pageId.replace(/-/g, '');
}

// URL에서 Page ID 추출
export function extractPageId(url: string): string {
  // 패턴 1: ?p=78e9896135d44cf8ad7718940e5f4863
  const pMatch = url.match(/[?&]p=([a-f0-9]{32})/i);
  if (pMatch) return pMatch[1];

  // 패턴 2: /PageName-78e9896135d44cf8ad7718940e5f4863
  const dashMatch = url.match(/([a-f0-9]{32})(?:\?|$|&)/i);
  if (dashMatch) return dashMatch[1];

  // 패턴 3: 하이픈 포함 UUID
  const uuidMatch = url.match(/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/i);
  if (uuidMatch) return uuidMatch[1].replace(/-/g, '');

  throw new Error('Invalid Notion URL - Cannot extract page ID');
}

// 유틸리티: sleep
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
