/**
 * Parser module exports
 * Re-exports all parsing functionality from core and v2
 */

// Core utilities (shared)
export {
  TEXT_BLOCK_TYPES,
  parseRichText,
  extractTextContent,
  extractImages,
  extractLinks,
  getAllBlocks,
  normalizePageId,
  formatPageId,
  getNotionPageUrl,
} from './core';

// V1 specific (basic parsing)
export {
  extractTitle as extractTitleV1,
  parseAllContent as parseAllContentV1,
  type ParsedContent as ParsedContentV1,
} from './v1';

// V2 specific (extended parsing with child pages and databases)
export {
  extractTitle,
  extractIcon,
  extractChildPages,
  extractDatabases,
  extractAllPageIds,
  parseAllContent,
  type ParsedContent,
  type PageInfo,
  type DatabaseInfo,
  type DatabaseItem,
} from './v2';
