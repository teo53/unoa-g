import { crawlRecursive, extractPageId, CrawlOptions } from './crawler-v2';
import { parseAllContent, extractAllPageIds, ParsedContent } from './parser-v2';
import * as fs from 'fs';

interface CrawlResult {
  id: string;
  url: string;
  depth: number;
  content: ParsedContent;
}

interface FullCrawlOutput {
  crawledAt: string;
  sourceUrl: string;
  rootPageId: string;
  totalPages: number;
  options: CrawlOptions;
  pages: CrawlResult[];
  hierarchy: HierarchyNode;
}

interface HierarchyNode {
  id: string;
  title: string;
  icon?: string;
  depth: number;
  children: HierarchyNode[];
}

async function main() {
  const targetUrls = [
    'https://fancim.notion.site/M-1243f48200694d3eaa43c5aa21e7cb1a?p=78e9896135d44cf8ad7718940e5f4863&pm=s',
    'https://fancim.notion.site/M-1243f48200694d3eaa43c5aa21e7cb1a?p=6038c5c05ede4238864f7ff6ebc2dce6&pm=c',
    'https://fancim.notion.site/M-1243f48200694d3eaa43c5aa21e7cb1a?p=304c25a3642849aca21822af27dfbc75&pm=c',
    'https://fancim.notion.site/M-1243f48200694d3eaa43c5aa21e7cb1a?p=255717c6e44880d3b3e3e766c878761e&pm=c',
    'https://fancim.notion.site/cb5921e58a524b1cbda7ff1b8b0e34de'
  ];

  console.log('==========================================');
  console.log('🚀 Notion Recursive Crawler v2 - Multi URL');
  console.log('==========================================\n');
  console.log('Target URLs:', targetUrls.length, '개');
  targetUrls.forEach((url, i) => console.log(`  ${i + 1}. ${url}`));

  const options: CrawlOptions = {
    recursive: true,
    maxDepth: 2,        // 2단계까지 크롤링
    delay: 500,         // 0.5초 딜레이
    includeRaw: true    // raw 데이터 포함 (파싱에 필요)
  };

  console.log('\nOptions:', JSON.stringify(options, null, 2));
  console.log('\n------------------------------------------\n');

  try {
    // 통합 결과 저장용 Map
    const allCrawledPages = new Map<string, any>();

    // 각 URL에 대해 크롤링 실행
    for (let i = 0; i < targetUrls.length; i++) {
      const targetUrl = targetUrls[i];
      console.log(`\n[${ i + 1}/${targetUrls.length}] 크롤링 시작: ${targetUrl}`);

      const rootPageId = extractPageId(targetUrl);
      console.log('  Root Page ID:', rootPageId);

      const crawledPages = await crawlRecursive(rootPageId, options);
      console.log(`  ✅ ${crawledPages.size}개 페이지 크롤링 완료`);

      // 결과 통합 (중복 제거)
      for (const [pageId, pageData] of crawledPages) {
        if (!allCrawledPages.has(pageId)) {
          allCrawledPages.set(pageId, pageData);
        }
      }

      // URL 간 딜레이
      if (i < targetUrls.length - 1) {
        console.log('  ⏳ 다음 URL 크롤링 대기...');
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }

    console.log(`\n✅ 전체 크롤링 완료! 총 ${allCrawledPages.size}개 고유 페이지\n`);

    const crawledPages = allCrawledPages;

    // 3. 결과 파싱
    const results: CrawlResult[] = [];
    const hierarchy: Map<string, HierarchyNode> = new Map();

    for (const [pageId, crawledPage] of crawledPages) {
      const content = parseAllContent(crawledPage.recordMap);
      
      results.push({
        id: pageId,
        url: crawledPage.url,
        depth: crawledPage.depth,
        content: {
          ...content,
          rawBlocks: [] // 용량 절약을 위해 제거
        }
      });

      // 계층 구조 빌드
      hierarchy.set(pageId, {
        id: pageId,
        title: content.title,
        icon: content.icon,
        depth: crawledPage.depth,
        children: []
      });
    }

    // 4. 결과 출력
    console.log('==========================================');
    console.log('📊 크롤링 결과 요약');
    console.log('==========================================');

    for (const result of results) {
      const indent = '  '.repeat(result.depth);
      console.log(`\n${indent}[Depth ${result.depth}] ${result.content.icon || '📄'} ${result.content.title}`);
      console.log(`${indent}  ID: ${result.id}`);
      console.log(`${indent}  텍스트: ${result.content.texts.length}개`);
      console.log(`${indent}  이미지: ${result.content.images.length}개`);
      console.log(`${indent}  하위페이지: ${result.content.childPages.length}개`);
      console.log(`${indent}  데이터베이스: ${result.content.databases.length}개`);
      
      // 데이터베이스 상세
      for (const db of result.content.databases) {
        console.log(`${indent}    📁 ${db.title}: ${db.items.length}개 항목`);
        for (const item of db.items.slice(0, 5)) {
          console.log(`${indent}      - ${item.icon || '📄'} ${item.title}`);
        }
        if (db.items.length > 5) {
          console.log(`${indent}      ... 외 ${db.items.length - 5}개`);
        }
      }
    }

    // 5. JSON 파일로 저장 (hierarchy 제외 - 순환 참조 방지)
    const output = {
      crawledAt: new Date().toISOString(),
      sourceUrls: targetUrls,
      rootPageIds: targetUrls.map(url => extractPageId(url)),
      totalPages: results.length,
      options: options,
      pages: results.map(r => ({
        id: r.id,
        url: r.url,
        depth: r.depth,
        content: {
          title: r.content.title,
          icon: r.content.icon,
          texts: r.content.texts,
          images: r.content.images,
          links: r.content.links,
          childPages: r.content.childPages,
          databases: r.content.databases
        }
      }))
    };

    fs.writeFileSync('crawl-result.json', JSON.stringify(output, null, 2));
    console.log('\n\n✅ 전체 데이터가 crawl-result.json에 저장되었습니다.');

    // 6. 요약 파일 생성
    const summary = {
      crawledAt: new Date().toISOString(),
      sourceUrls: targetUrls,
      totalPages: results.length,
      pages: results.map(r => ({
        id: r.id,
        depth: r.depth,
        title: r.content.title,
        icon: r.content.icon,
        textCount: r.content.texts.length,
        imageCount: r.content.images.length,
        childPageCount: r.content.childPages.length,
        databaseCount: r.content.databases.length,
        databases: r.content.databases.map(db => ({
          title: db.title,
          itemCount: db.items.length,
          items: db.items.map(item => ({
            id: item.id,
            title: item.title,
            icon: item.icon
          }))
        }))
      }))
    };

    fs.writeFileSync('crawl-summary.json', JSON.stringify(summary, null, 2));
    console.log('✅ 요약 데이터가 crawl-summary.json에 저장되었습니다.');

  } catch (error) {
    console.error('❌ 크롤링 실패:', error);
    process.exit(1);
  }
}

// 계층 구조 트리 빌드
function buildHierarchyTree(results: CrawlResult[], rootId: string): HierarchyNode {
  const nodeMap = new Map<string, HierarchyNode>();
  
  // 노드 생성
  for (const result of results) {
    nodeMap.set(result.id, {
      id: result.id,
      title: result.content.title,
      icon: result.content.icon,
      depth: result.depth,
      children: []
    });
  }

  // 부모-자식 관계 연결
  for (const result of results) {
    const node = nodeMap.get(result.id);
    if (!node) continue;

    // 하위 페이지 연결
    for (const childPage of result.content.childPages) {
      const childNode = nodeMap.get(childPage.id.replace(/-/g, ''));
      if (childNode) {
        node.children.push(childNode);
      }
    }

    // 데이터베이스 아이템 연결
    for (const db of result.content.databases) {
      for (const item of db.items) {
        const itemNode = nodeMap.get(item.id.replace(/-/g, ''));
        if (itemNode) {
          node.children.push(itemNode);
        }
      }
    }
  }

  return nodeMap.get(rootId.replace(/-/g, '')) || {
    id: rootId,
    title: 'Root',
    depth: 0,
    children: []
  };
}

main();
