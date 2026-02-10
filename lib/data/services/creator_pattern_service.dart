/// 크리에이터의 채팅 패턴을 분석하고 학습하는 서비스
///
/// 크리에이터의 과거 답변 메시지들에서 톤/스타일/길이/자주 사용하는 표현 등을
/// 추출하여 AI 답글 초안 생성 시 반영합니다.
class CreatorPatternService {
  CreatorPatternService._();
  static final instance = CreatorPatternService._();

  /// 캐시된 패턴 분석 결과 (creatorId -> PatternAnalysis)
  final Map<String, PatternAnalysis> _cache = {};

  /// 캐시 유효 시간 (30분)
  static const _cacheDuration = Duration(minutes: 30);

  /// 마지막 분석 시간
  final Map<String, DateTime> _lastAnalyzed = {};

  /// 크리에이터의 과거 메시지를 기반으로 패턴 분석 반환
  ///
  /// [messages] - 크리에이터가 보낸 최근 메시지 목록
  /// [creatorId] - 크리에이터 ID (캐시 키)
  PatternAnalysis analyzePatterns({
    required String creatorId,
    required List<CreatorMessage> messages,
  }) {
    // 캐시가 유효하면 반환
    final lastTime = _lastAnalyzed[creatorId];
    if (lastTime != null &&
        DateTime.now().difference(lastTime) < _cacheDuration &&
        _cache.containsKey(creatorId)) {
      return _cache[creatorId]!;
    }

    if (messages.isEmpty) {
      return PatternAnalysis.empty();
    }

    // 1. 평균 메시지 길이 분석
    final lengths = messages.map((m) => m.content.length).toList();
    final avgLength = lengths.reduce((a, b) => a + b) / lengths.length;

    // 2. 톤 분석 (이모지 사용률, 존댓말/반말 비율)
    int emojiCount = 0;
    int formalCount = 0;
    int casualCount = 0;
    int questionCount = 0;
    int exclamationCount = 0;

    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}'
      r'\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}'
      r'\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}]',
      unicode: true,
    );

    // 존댓말 패턴
    final formalPatterns = RegExp(r'(요|입니다|습니다|세요|겠습|니다|드려|드릴게)');
    // 반말 패턴 — 줄 끝뿐 아니라 구두점/이모지 앞도 감지
    final casualPatterns = RegExp(
      r'(해|야|지|어|아|ㅋ|ㅎ|~|ㅠ|ㅜ)(?:$|[!?\s]|[^\w가-힣])',
      multiLine: true,
    );

    final frequentPhrases = <String, int>{};

    for (final msg in messages) {
      final content = msg.content;

      // 이모지 카운트
      emojiCount += emojiRegex.allMatches(content).length;

      // 존댓말/반말 판단
      if (formalPatterns.hasMatch(content)) {
        formalCount++;
      }
      if (casualPatterns.hasMatch(content)) {
        casualCount++;
      }

      // 물음표/느낌표
      if (content.contains('?') || content.contains('？')) questionCount++;
      if (content.contains('!') || content.contains('！')) exclamationCount++;

      // 자주 사용하는 구문 추출 (2-4글자 단위)
      _extractPhrases(content, frequentPhrases);
    }

    // 3. 가장 자주 쓰는 구문 Top 10
    final sortedPhrases = frequentPhrases.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topPhrases = sortedPhrases
        .where((e) => e.value >= 2) // 최소 2번 이상 사용
        .take(10)
        .map((e) => e.key)
        .toList();

    // 4. 톤 결정
    final totalMessages = messages.length;
    final emojiRate = emojiCount / totalMessages;
    final formalRate = formalCount / totalMessages;
    final casualRate = casualCount / totalMessages;

    String dominantTone;
    if (formalRate > 0.6) {
      dominantTone = emojiRate > 1.5 ? '다정한 존댓말' : '정중한 존댓말';
    } else if (casualRate > 0.6) {
      dominantTone = emojiRate > 1.5 ? '친근한 반말' : '쿨한 반말';
    } else {
      dominantTone = '자연스러운 혼합체';
    }

    // 5. 스타일 키워드
    final styleKeywords = <String>[];
    if (emojiRate > 2.0) styleKeywords.add('이모지 많이 사용');
    if (emojiRate < 0.3) styleKeywords.add('이모지 거의 안 씀');
    if (questionCount / totalMessages > 0.3) styleKeywords.add('질문형 응답 많음');
    if (exclamationCount / totalMessages > 0.5) styleKeywords.add('감탄사 자주 사용');
    if (avgLength < 30) styleKeywords.add('짧고 간결한 스타일');
    if (avgLength > 80) styleKeywords.add('상세하게 답변하는 스타일');

    // 6. 예시 메시지 (가장 최근 + 다양한 스타일)
    final exampleMessages = _selectDiverseExamples(messages, maxCount: 5);

    final analysis = PatternAnalysis(
      averageLength: avgLength.round(),
      dominantTone: dominantTone,
      emojiRate: emojiRate,
      formalRate: formalRate,
      topPhrases: topPhrases,
      styleKeywords: styleKeywords,
      exampleMessages: exampleMessages,
      totalMessagesAnalyzed: totalMessages,
    );

    // 캐시에 저장
    _cache[creatorId] = analysis;
    _lastAnalyzed[creatorId] = DateTime.now();

    return analysis;
  }

  /// 패턴 분석 결과를 프롬프트 컨텍스트로 변환
  String buildPatternContext(PatternAnalysis analysis) {
    if (analysis.totalMessagesAnalyzed == 0) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln(
        '[크리에이터 답변 패턴 분석 (${analysis.totalMessagesAnalyzed}개 메시지 기반)]');
    buffer.writeln('- 주요 톤: ${analysis.dominantTone}');
    buffer.writeln('- 평균 답변 길이: 약 ${analysis.averageLength}자');

    if (analysis.styleKeywords.isNotEmpty) {
      buffer.writeln('- 스타일 특징: ${analysis.styleKeywords.join(', ')}');
    }

    if (analysis.topPhrases.isNotEmpty) {
      buffer.writeln('- 자주 사용하는 표현: ${analysis.topPhrases.take(5).join(', ')}');
    }

    if (analysis.exampleMessages.isNotEmpty) {
      buffer.writeln('\n[최근 답변 예시 (톤/스타일 참조용)]');
      for (final example in analysis.exampleMessages) {
        buffer.writeln('- "${example.content}"');
      }
    }

    buffer.writeln('\n⚠️ 위 패턴을 참조하여 크리에이터의 실제 답변 스타일과 유사하게 초안을 작성하세요.');

    return buffer.toString();
  }

  /// 텍스트에서 자주 사용하는 구문 추출 (단어 + 바이그램)
  void _extractPhrases(String text, Map<String, int> phrases) {
    // 이모지 및 특수문자 제거 후 구문 추출
    final cleaned = text.replaceAll(RegExp(r'[^\w가-힣\s]'), '');
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();

    // 단어 단위 추출
    for (int i = 0; i < words.length; i++) {
      final word = words[i].trim();
      if (word.length >= 2) {
        phrases[word] = (phrases[word] ?? 0) + 1;
      }
    }

    // 바이그램 추출 (2단어 조합 빈도 분석)
    for (int i = 0; i < words.length - 1; i++) {
      final bigram = '${words[i]} ${words[i + 1]}';
      if (bigram.length >= 4) {
        phrases[bigram] = (phrases[bigram] ?? 0) + 1;
      }
    }
  }

  /// 다양한 스타일의 예시 메시지 선택
  List<CreatorMessage> _selectDiverseExamples(
    List<CreatorMessage> messages, {
    int maxCount = 5,
  }) {
    if (messages.length <= maxCount) return List.from(messages);

    final selected = <CreatorMessage>[];

    // 최근 메시지 2개
    selected.addAll(messages.take(2));

    // 나머지는 길이 다양성을 고려하여 선택
    final remaining = messages.skip(2).toList();
    remaining.sort((a, b) => a.content.length.compareTo(b.content.length));

    // 가장 짧은 것, 중간, 가장 긴 것
    if (remaining.isNotEmpty) selected.add(remaining.first);
    if (remaining.length > 2) selected.add(remaining[remaining.length ~/ 2]);
    if (remaining.length > 1) selected.add(remaining.last);

    return selected.take(maxCount).toList();
  }

  /// 캐시 초기화
  void clearCache([String? creatorId]) {
    if (creatorId != null) {
      _cache.remove(creatorId);
      _lastAnalyzed.remove(creatorId);
    } else {
      _cache.clear();
      _lastAnalyzed.clear();
    }
  }
}

/// 패턴 분석 결과
class PatternAnalysis {
  final int averageLength;
  final String dominantTone;
  final double emojiRate;
  final double formalRate;
  final List<String> topPhrases;
  final List<String> styleKeywords;
  final List<CreatorMessage> exampleMessages;
  final int totalMessagesAnalyzed;

  const PatternAnalysis({
    required this.averageLength,
    required this.dominantTone,
    required this.emojiRate,
    required this.formalRate,
    required this.topPhrases,
    required this.styleKeywords,
    required this.exampleMessages,
    required this.totalMessagesAnalyzed,
  });

  factory PatternAnalysis.empty() => const PatternAnalysis(
        averageLength: 0,
        dominantTone: '알 수 없음',
        emojiRate: 0,
        formalRate: 0,
        topPhrases: [],
        styleKeywords: [],
        exampleMessages: [],
        totalMessagesAnalyzed: 0,
      );

  bool get hasData => totalMessagesAnalyzed > 0;
}

/// 크리에이터 메시지 (패턴 분석용 경량 모델)
class CreatorMessage {
  final String id;
  final String content;
  final DateTime createdAt;

  const CreatorMessage({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  factory CreatorMessage.fromJson(Map<String, dynamic> json) {
    return CreatorMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
