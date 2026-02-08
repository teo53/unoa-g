import '../services/creator_pattern_service.dart';

/// Mock creator messages for demo mode pattern analysis.
///
/// Each channel has distinct speaking styles so the pattern learning
/// system produces different results per creator.
class MockCreatorMessages {
  MockCreatorMessages._();

  /// Returns mock messages for a specific channel.
  /// Different channels have different tones and styles.
  static List<CreatorMessage> forChannel(String channelId) {
    switch (channelId) {
      case 'channel_1':
        return _warmPoliteStyle;
      case 'channel_2':
        return _coolCasualStyle;
      case 'channel_3':
        return _detailedFormalStyle;
      default:
        return _warmPoliteStyle;
    }
  }

  /// 다정한 존댓말 스타일 — 이모지 많이 사용, 짧고 따뜻한 어투
  static final List<CreatorMessage> _warmPoliteStyle = [
    CreatorMessage(
      id: 'warm_01',
      content: '오늘 공연 와줘서 너무 고마워요~ 💕 여러분이 있어서 행복했어요!',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    CreatorMessage(
      id: 'warm_02',
      content: 'ㅋㅋㅋ 귀여워요~ 고마워요! 😊',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    CreatorMessage(
      id: 'warm_03',
      content: '여러분 덕분에 힘이 나요! 항상 응원해줘서 감사합니다 🙏✨',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CreatorMessage(
      id: 'warm_04',
      content: '다음 주 컴백 준비 열심히 하고 있어요 기대해주세요!! ✨🎵',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
    ),
    CreatorMessage(
      id: 'warm_05',
      content: '오늘 날씨가 너무 좋아서 산책했어요 🌸 여러분도 좋은 하루 보내세요~',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    CreatorMessage(
      id: 'warm_06',
      content: '사랑해요 여러분~ 💕💕 오늘도 수고했어요!',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    ),
    CreatorMessage(
      id: 'warm_07',
      content: '우와 진짜요?? 너무 감동이에요 😭💕 고마워요~',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    CreatorMessage(
      id: 'warm_08',
      content: '맞아요 맞아요~ 저도 그렇게 생각해요! ㅎㅎ',
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 6)),
    ),
    CreatorMessage(
      id: 'warm_09',
      content: '연습 끝나고 먹은 떡볶이가 세상에서 제일 맛있었어요 🤤',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    CreatorMessage(
      id: 'warm_10',
      content: '내일 봐요~ 오늘 푹 쉬세요! 🌙💤',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  /// 쿨한 반말 스타일 — 이모지 적음, 짧고 캐주얼한 어투
  static final List<CreatorMessage> _coolCasualStyle = [
    CreatorMessage(
      id: 'cool_01',
      content: 'ㅋㅋ 그건 비밀이지~',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    CreatorMessage(
      id: 'cool_02',
      content: '오 진짜? 나도 그거 좋아해',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    CreatorMessage(
      id: 'cool_03',
      content: '고마워~ 오늘 공연 재밌었지? ㅎㅎ',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CreatorMessage(
      id: 'cool_04',
      content: '아 배고파 뭐 먹을까',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
    ),
    CreatorMessage(
      id: 'cool_05',
      content: '오늘 연습 빡셌어 ㅋㅋ 근데 뿌듯하다',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    CreatorMessage(
      id: 'cool_06',
      content: '응 맞아 다음에 또 하자~',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    ),
    CreatorMessage(
      id: 'cool_07',
      content: 'ㅋㅋㅋ 진짜 웃기다',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    CreatorMessage(
      id: 'cool_08',
      content: '그건 나중에 알려줄게 기대해',
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 6)),
    ),
    CreatorMessage(
      id: 'cool_09',
      content: '잘 자~ 내일 봐',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    CreatorMessage(
      id: 'cool_10',
      content: '오 센스 좋은데? ㅋ',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  /// 정중한 존댓말 스타일 — 이모지 적음, 길고 정성스러운 어투
  static final List<CreatorMessage> _detailedFormalStyle = [
    CreatorMessage(
      id: 'formal_01',
      content: '오늘 공연에 와주신 모든 분들께 진심으로 감사드립니다. 여러분의 응원이 큰 힘이 됩니다.',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    CreatorMessage(
      id: 'formal_02',
      content: '그런 질문 해주셔서 감사합니다. 저도 그 부분에 대해 많이 생각하고 있어요. 좋은 소식을 곧 전해드리겠습니다.',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    CreatorMessage(
      id: 'formal_03',
      content: '항상 응원해주시는 것 잘 알고 있습니다. 더 좋은 무대로 보답하겠습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CreatorMessage(
      id: 'formal_04',
      content: '새 앨범 작업이 순조롭게 진행되고 있습니다. 기대해주셔도 좋습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
    ),
    CreatorMessage(
      id: 'formal_05',
      content: '오늘도 좋은 하루 보내시길 바랍니다. 건강 잘 챙기세요.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    CreatorMessage(
      id: 'formal_06',
      content: '맞습니다. 저도 같은 생각입니다. 좋은 의견 감사합니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    ),
    CreatorMessage(
      id: 'formal_07',
      content: '그 점에 대해서는 조금 더 준비한 후에 알려드리겠습니다. 조금만 기다려주세요.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    CreatorMessage(
      id: 'formal_08',
      content: '감사합니다. 여러분의 따뜻한 마음이 정말 감동적입니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 6)),
    ),
    CreatorMessage(
      id: 'formal_09',
      content: '연습 일정이 빡빡했지만 보람차게 마무리했습니다. 좋은 결과물을 보여드릴 수 있을 것 같습니다.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    CreatorMessage(
      id: 'formal_10',
      content: '편히 쉬시고 내일 또 만나요. 좋은 꿈 꾸세요.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}
