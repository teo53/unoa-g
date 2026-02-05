/**
 * V1 Parser - Basic Notion content parsing
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
  parseAllContent,
  type ParsedContent,
} from './parser/v1';
