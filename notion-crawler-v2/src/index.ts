import { crawlPublicPage, extractPageId } from './crawler';
import { parseAllContent } from './parser';
import * as fs from 'fs';

async function main() {
  const targetUrl = 'https://fancim.notion.site/M-1243f48200694d3eaa43c5aa21e7cb1a?p=78e9896135d44cf8ad7718940e5f4863&pm=s';
  
  console.log('==========================================');
  console.log('🚀 Notion Public Page Crawler');
  console.log('==========================================\n');
  console.log('Target URL:', targetUrl);

  try {
    // 1. Page ID 추출
    const pageId = extractPageId(targetUrl);
    console.log('Extracted Page ID:', pageId);
    console.log('\n------------------------------------------\n');

    // 2. 페이지 크롤링
    console.log('⏳ 크롤링 중...');
    const recordMap = await crawlPublicPage(pageId);
    console.log('✅ 크롤링 완료!\n');

    // 3. 콘텐츠 파싱
    const content = parseAllContent(recordMap);

    // 4. 결과 출력
    console.log('==========================================');
    console.log('📄 페이지 제목');
    console.log('==========================================');
    console.log(content.title);

    console.log('\n==========================================');
    console.log('📝 텍스트 콘텐츠 (' + content.texts.length + '개)');
    console.log('==========================================');
    content.texts.forEach((text, i) => {
      console.log(`[${i + 1}] ${text}`);
    });

    console.log('\n==========================================');
    console.log('🖼️  이미지 URLs (' + content.images.length + '개)');
    console.log('==========================================');
    content.images.forEach((img, i) => {
      console.log(`[${i + 1}] ${img}`);
    });

    console.log('\n==========================================');
    console.log('🔗 링크 (' + content.links.length + '개)');
    console.log('==========================================');
    content.links.forEach((link, i) => {
      console.log(`[${i + 1}] ${link}`);
    });

    // 5. JSON 파일로 저장
    const output = {
      crawledAt: new Date().toISOString(),
      sourceUrl: targetUrl,
      pageId: pageId,
      content: content,
      rawRecordMap: recordMap
    };

    fs.writeFileSync('output.json', JSON.stringify(output, null, 2));
    console.log('\n✅ 전체 데이터가 output.json에 저장되었습니다.');

    // 요약 정보만 별도 저장
    const summary = {
      crawledAt: new Date().toISOString(),
      sourceUrl: targetUrl,
      pageId: pageId,
      title: content.title,
      textCount: content.texts.length,
      imageCount: content.images.length,
      linkCount: content.links.length,
      texts: content.texts,
      images: content.images,
      links: content.links
    };

    fs.writeFileSync('summary.json', JSON.stringify(summary, null, 2));
    console.log('✅ 요약 데이터가 summary.json에 저장되었습니다.');

  } catch (error) {
    console.error('❌ 크롤링 실패:', error);
    process.exit(1);
  }
}

main();
