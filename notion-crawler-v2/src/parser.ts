import { ExtendedRecordMap, Block } from 'notion-types';

// 텍스트 타입 블록 목록
const TEXT_BLOCK_TYPES = [
  'text',
  'header',
  'sub_header', 
  'sub_sub_header',
  'bulleted_list',
  'numbered_list',
  'quote',
  'callout',
  'toggle',
  'to_do'
];

export interface ParsedContent {
  title: string;
  texts: string[];
  images: string[];
  links: string[];
  rawBlocks: Block[];
}

export function extractTitle(recordMap: ExtendedRecordMap): string {
  const blocks = Object.values(recordMap.block);
  
  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (block?.type === 'page') {
      const title = block.properties?.title;
      if (title) {
        return title.map((t: any) => t[0]).join('');
      }
    }
  }
  
  return 'Untitled';
}

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

export function extractImages(recordMap: ExtendedRecordMap): string[] {
  const blocks = Object.values(recordMap.block);
  const images: string[] = [];

  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (!block) continue;

    if (block.type === 'image') {
      // source 속성에서 이미지 URL 추출
      const source = block.properties?.source?.[0]?.[0];
      if (source) {
        images.push(source);
      }
      
      // format에서 이미지 URL 추출 (대체 경로)
      const format = (block as any).format;
      if (format?.display_source) {
        images.push(format.display_source);
      }
    }
  }

  // 중복 제거
  return [...new Set(images)];
}

export function extractLinks(recordMap: ExtendedRecordMap): string[] {
  const blocks = Object.values(recordMap.block);
  const links: string[] = [];

  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (!block?.properties?.title) continue;

    // Rich text에서 링크 추출
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

export function parseRichText(richText: any[]): string {
  if (!richText || !Array.isArray(richText)) return '';
  
  return richText.map((segment: any) => {
    if (typeof segment[0] === 'string') {
      return segment[0];
    }
    return '';
  }).join('');
}

export function parseAllContent(recordMap: ExtendedRecordMap): ParsedContent {
  const blocks = Object.values(recordMap.block)
    .map(b => b?.value as Block)
    .filter(Boolean);

  return {
    title: extractTitle(recordMap),
    texts: extractTextContent(recordMap),
    images: extractImages(recordMap),
    links: extractLinks(recordMap),
    rawBlocks: blocks
  };
}
