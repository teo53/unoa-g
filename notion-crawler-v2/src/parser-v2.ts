/**
 * V2 Parser - Extended Notion content parsing
 *
 * @deprecated Use './parser/index' for new code
 * This file is kept for backward compatibility
 */

// Re-export everything from the new module structure
export {
  parseRichText,
  extractTextContent,
  extractImages,
  extractLinks,
} from './parser/core';

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
} from './parser/v2';
