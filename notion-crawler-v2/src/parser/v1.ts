/**
 * V1 Parser - Basic Notion content parsing
 * For single page crawling without recursive traversal
 */

import { ExtendedRecordMap, Block } from 'notion-types';
import {
  parseRichText,
  extractTextContent,
  extractImages,
  extractLinks,
  getAllBlocks,
} from './core';

export interface ParsedContent {
  title: string;
  texts: string[];
  images: string[];
  links: string[];
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
 * Parse all content from a Notion page
 */
export function parseAllContent(recordMap: ExtendedRecordMap): ParsedContent {
  return {
    title: extractTitle(recordMap),
    texts: extractTextContent(recordMap),
    images: extractImages(recordMap),
    links: extractLinks(recordMap),
    rawBlocks: getAllBlocks(recordMap),
  };
}
