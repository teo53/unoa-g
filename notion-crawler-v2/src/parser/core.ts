/**
 * Core parsing utilities for Notion content
 * Shared between parser.ts and parser-v2.ts
 */

import { ExtendedRecordMap, Block } from 'notion-types';

// Block types that contain text content
export const TEXT_BLOCK_TYPES = [
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

/**
 * Parse rich text array into plain string
 */
export function parseRichText(richText: any[]): string {
  if (!richText || !Array.isArray(richText)) return '';

  return richText.map((segment: any) => {
    if (typeof segment[0] === 'string') {
      return segment[0];
    }
    return '';
  }).join('');
}

/**
 * Extract text content from all text blocks
 */
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

/**
 * Extract image URLs from image blocks
 */
export function extractImages(recordMap: ExtendedRecordMap): string[] {
  const blocks = Object.values(recordMap.block);
  const images: string[] = [];

  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (!block) continue;

    if (block.type === 'image') {
      // Source property
      const source = block.properties?.source?.[0]?.[0];
      if (source) {
        images.push(source);
      }

      // Alternative: format.display_source
      const format = (block as any).format;
      if (format?.display_source) {
        images.push(format.display_source);
      }
    }
  }

  // Remove duplicates
  return [...new Set(images)];
}

/**
 * Extract external links from rich text annotations
 */
export function extractLinks(recordMap: ExtendedRecordMap): string[] {
  const blocks = Object.values(recordMap.block);
  const links: string[] = [];

  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (!block?.properties?.title) continue;

    // Extract links from rich text annotations
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

/**
 * Get all blocks as an array
 */
export function getAllBlocks(recordMap: ExtendedRecordMap): Block[] {
  return Object.values(recordMap.block)
    .map(b => b?.value as Block)
    .filter(Boolean);
}

/**
 * Normalize Notion page ID (remove dashes)
 */
export function normalizePageId(id: string): string {
  return id.replace(/-/g, '');
}

/**
 * Format page ID with dashes
 */
export function formatPageId(id: string): string {
  const normalized = normalizePageId(id);
  if (normalized.length !== 32) return id;

  return [
    normalized.slice(0, 8),
    normalized.slice(8, 12),
    normalized.slice(12, 16),
    normalized.slice(16, 20),
    normalized.slice(20, 32),
  ].join('-');
}

/**
 * Generate Notion page URL
 */
export function getNotionPageUrl(pageId: string): string {
  return `https://notion.so/${normalizePageId(pageId)}`;
}
