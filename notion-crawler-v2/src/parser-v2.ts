import { ExtendedRecordMap, Block, Collection } from 'notion-types';

// 블록 타입 정의
const TEXT_BLOCK_TYPES = [
  'text', 'header', 'sub_header', 'sub_sub_header',
  'bulleted_list', 'numbered_list', 'quote', 'callout', 'toggle', 'to_do'
];

export interface PageInfo {
  id: string;
  title: string;
  icon?: string;
  url?: string;
}

export interface DatabaseItem {
  id: string;
  title: string;
  icon?: string;
  properties: Record<string, any>;
}

export interface DatabaseInfo {
  id: string;
  title: string;
  items: DatabaseItem[];
}

export interface ParsedContent {
  title: string;
  icon?: string;
  texts: string[];
  images: string[];
  links: string[];
  childPages: PageInfo[];
  databases: DatabaseInfo[];
  rawBlocks: Block[];
}

// 페이지 제목 추출
export function extractTitle(recordMap: ExtendedRecordMap): string {
  const blocks = Object.values(recordMap.block);
  
  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (block?.type === 'page') {
      const title = block.properties?.title;
      if (title) {
        return parseRichText(title);
      }
    }
  }
  
  return 'Untitled';
}

// 페이지 아이콘 추출
export function extractIcon(recordMap: ExtendedRecordMap): string | undefined {
  const blocks = Object.values(recordMap.block);
  
  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (block?.type === 'page') {
      const format = (block as any).format;
      return format?.page_icon;
    }
  }
  
  return undefined;
}

// 텍스트 콘텐츠 추출
export function extractTextContent(recordMap: ExtendedRecordMap): string[] {
  const blocks = Object.values(recordMap.block);
  const texts: string[] = [];

  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (!block) continue;

    if (TEXT_BLOCK_TYPES.includes(block.type)) {
      const title = block.properties?.title;
      if (title) {
        const text = parseRichText(title);
        if (text.trim()) {
          texts.push(text);
        }
      }
    }
  }

  return texts;
}

// 이미지 URL 추출
export function extractImages(recordMap: ExtendedRecordMap): string[] {
  const blocks = Object.values(recordMap.block);
  const images: string[] = [];

  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (!block) continue;

    if (block.type === 'image') {
      const source = block.properties?.source?.[0]?.[0];
      if (source) images.push(source);
      
      const format = (block as any).format;
      if (format?.display_source) images.push(format.display_source);
    }
  }

  return [...new Set(images)];
}

// 링크 추출
export function extractLinks(recordMap: ExtendedRecordMap): string[] {
  const blocks = Object.values(recordMap.block);
  const links: string[] = [];

  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (!block?.properties?.title) continue;

    const title = block.properties.title;
    for (const segment of title) {
      if (segment[1]) {
        for (const annotation of segment[1]) {
          if (annotation[0] === 'a' && annotation[1]) {
            links.push(annotation[1]);
          }
        }
      }
    }
  }

  return [...new Set(links)];
}

// 하위 페이지 추출
export function extractChildPages(recordMap: ExtendedRecordMap): PageInfo[] {
  const blocks = Object.values(recordMap.block);
  const childPages: PageInfo[] = [];
  const seenIds = new Set<string>();

  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (!block) continue;

    // 페이지 블록 타입
    if (block.type === 'page' && block.parent_table === 'block') {
      if (seenIds.has(block.id)) continue;
      seenIds.add(block.id);

      const title = block.properties?.title 
        ? parseRichText(block.properties.title) 
        : 'Untitled';
      
      const format = (block as any).format;
      
      childPages.push({
        id: block.id,
        title: title,
        icon: format?.page_icon,
        url: `https://notion.so/${block.id.replace(/-/g, '')}`
      });
    }

    // collection_view 또는 collection_view_page 내의 페이지들
    if (block.type === 'collection_view' || block.type === 'collection_view_page') {
      const collectionId = (block as any).collection_id;
      if (collectionId && recordMap.collection) {
        // collection 내 페이지들은 별도 처리
      }
    }
  }

  return childPages;
}

// 데이터베이스(Collection) 추출
export function extractDatabases(recordMap: ExtendedRecordMap): DatabaseInfo[] {
  const databases: DatabaseInfo[] = [];

  if (!recordMap.collection) return databases;

  // 모든 collection 순회
  for (const [collectionId, collectionData] of Object.entries(recordMap.collection)) {
    const collection = collectionData?.value as Collection;
    if (!collection) continue;

    const dbTitle = collection.name?.[0]?.[0] || 'Untitled Database';
    const items: DatabaseItem[] = [];

    // collection_query에서 페이지 ID들 가져오기
    if (recordMap.collection_query) {
      const queries = recordMap.collection_query[collectionId];
      if (queries) {
        for (const queryData of Object.values(queries)) {
          const blockIds = (queryData as any)?.collection_group_results?.blockIds || [];
          
          for (const blockId of blockIds) {
            const blockData = recordMap.block[blockId];
            const block = blockData?.value as Block;
            
            if (block) {
              const title = block.properties?.title 
                ? parseRichText(block.properties.title) 
                : 'Untitled';
              
              const format = (block as any).format;
              
              items.push({
                id: block.id,
                title: title,
                icon: format?.page_icon,
                properties: block.properties || {}
              });
            }
          }
        }
      }
    }

    // block에서 직접 collection 아이템 찾기
    for (const [blockId, blockData] of Object.entries(recordMap.block)) {
      const block = blockData?.value as Block;
      if (!block) continue;
      
      if (block.parent_id === collectionId || (block as any).parent_table === 'collection') {
        const exists = items.some(item => item.id === block.id);
        if (!exists && block.type === 'page') {
          const title = block.properties?.title 
            ? parseRichText(block.properties.title) 
            : 'Untitled';
          
          const format = (block as any).format;
          
          items.push({
            id: block.id,
            title: title,
            icon: format?.page_icon,
            properties: block.properties || {}
          });
        }
      }
    }

    if (items.length > 0) {
      databases.push({
        id: collectionId,
        title: dbTitle,
        items: items
      });
    }
  }

  return databases;
}

// Rich Text 파싱
export function parseRichText(richText: any[]): string {
  if (!richText || !Array.isArray(richText)) return '';
  
  return richText.map((segment: any) => {
    if (typeof segment[0] === 'string') {
      return segment[0];
    }
    return '';
  }).join('');
}

// 전체 콘텐츠 파싱
export function parseAllContent(recordMap: ExtendedRecordMap): ParsedContent {
  const blocks = Object.values(recordMap.block)
    .map(b => b?.value as Block)
    .filter(Boolean);

  return {
    title: extractTitle(recordMap),
    icon: extractIcon(recordMap),
    texts: extractTextContent(recordMap),
    images: extractImages(recordMap),
    links: extractLinks(recordMap),
    childPages: extractChildPages(recordMap),
    databases: extractDatabases(recordMap),
    rawBlocks: blocks
  };
}

// 크롤링 대상 페이지 ID 목록 추출
export function extractAllPageIds(recordMap: ExtendedRecordMap): string[] {
  const pageIds: string[] = [];
  const seenIds = new Set<string>();

  // 하위 페이지들
  const childPages = extractChildPages(recordMap);
  for (const page of childPages) {
    if (!seenIds.has(page.id)) {
      seenIds.add(page.id);
      pageIds.push(page.id);
    }
  }

  // 데이터베이스 아이템들
  const databases = extractDatabases(recordMap);
  for (const db of databases) {
    for (const item of db.items) {
      if (!seenIds.has(item.id)) {
        seenIds.add(item.id);
        pageIds.push(item.id);
      }
    }
  }

  return pageIds;
}
