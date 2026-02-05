/**
 * V2 Parser - Extended Notion content parsing
 * Supports child pages, databases, and recursive crawling
 */

import { ExtendedRecordMap, Block, Collection } from 'notion-types';
import {
  parseRichText,
  extractTextContent,
  extractImages,
  extractLinks,
  getAllBlocks,
  normalizePageId,
  getNotionPageUrl,
} from './core';

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

/**
 * Extract page title from recordMap
 */
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

/**
 * Extract page icon (emoji or image URL)
 */
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

/**
 * Extract child pages from recordMap
 */
export function extractChildPages(recordMap: ExtendedRecordMap): PageInfo[] {
  const blocks = Object.values(recordMap.block);
  const childPages: PageInfo[] = [];
  const seenIds = new Set<string>();

  for (const blockData of blocks) {
    const block = blockData?.value as Block;
    if (!block) continue;

    // Page blocks that are children of another block
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
        url: getNotionPageUrl(block.id),
      });
    }
  }

  return childPages;
}

/**
 * Extract databases (collections) and their items
 */
export function extractDatabases(recordMap: ExtendedRecordMap): DatabaseInfo[] {
  const databases: DatabaseInfo[] = [];

  if (!recordMap.collection) return databases;

  // Iterate all collections
  for (const [collectionId, collectionData] of Object.entries(recordMap.collection)) {
    const collection = collectionData?.value as Collection;
    if (!collection) continue;

    const dbTitle = collection.name?.[0]?.[0] || 'Untitled Database';
    const items: DatabaseItem[] = [];
    const seenItemIds = new Set<string>();

    // Get page IDs from collection_query
    if (recordMap.collection_query) {
      const queries = recordMap.collection_query[collectionId];
      if (queries) {
        for (const queryData of Object.values(queries)) {
          const blockIds = (queryData as any)?.collection_group_results?.blockIds || [];

          for (const blockId of blockIds) {
            if (seenItemIds.has(blockId)) continue;

            const blockData = recordMap.block[blockId];
            const block = blockData?.value as Block;

            if (block) {
              seenItemIds.add(blockId);
              const title = block.properties?.title
                ? parseRichText(block.properties.title)
                : 'Untitled';

              const format = (block as any).format;

              items.push({
                id: block.id,
                title: title,
                icon: format?.page_icon,
                properties: block.properties || {},
              });
            }
          }
        }
      }
    }

    // Also check blocks directly parented by collection
    for (const [blockId, blockData] of Object.entries(recordMap.block)) {
      const block = blockData?.value as Block;
      if (!block || seenItemIds.has(block.id)) continue;

      if (block.parent_id === collectionId || (block as any).parent_table === 'collection') {
        if (block.type === 'page') {
          seenItemIds.add(block.id);
          const title = block.properties?.title
            ? parseRichText(block.properties.title)
            : 'Untitled';

          const format = (block as any).format;

          items.push({
            id: block.id,
            title: title,
            icon: format?.page_icon,
            properties: block.properties || {},
          });
        }
      }
    }

    if (items.length > 0) {
      databases.push({
        id: collectionId,
        title: dbTitle,
        items: items,
      });
    }
  }

  return databases;
}

/**
 * Extract all page IDs for recursive crawling
 */
export function extractAllPageIds(recordMap: ExtendedRecordMap): string[] {
  const pageIds: string[] = [];
  const seenIds = new Set<string>();

  // Child pages
  const childPages = extractChildPages(recordMap);
  for (const page of childPages) {
    if (!seenIds.has(page.id)) {
      seenIds.add(page.id);
      pageIds.push(page.id);
    }
  }

  // Database items
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

/**
 * Parse all content from a Notion page (extended version)
 */
export function parseAllContent(recordMap: ExtendedRecordMap): ParsedContent {
  return {
    title: extractTitle(recordMap),
    icon: extractIcon(recordMap),
    texts: extractTextContent(recordMap),
    images: extractImages(recordMap),
    links: extractLinks(recordMap),
    childPages: extractChildPages(recordMap),
    databases: extractDatabases(recordMap),
    rawBlocks: getAllBlocks(recordMap),
  };
}
