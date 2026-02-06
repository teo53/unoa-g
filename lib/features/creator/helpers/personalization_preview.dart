import '../../../core/config/business_config.dart';

/// 미리보기용 팬 타입
/// 아티스트가 메시지를 보내기 전에 다양한 팬 유형의 관점에서
/// 어떻게 보이는지 미리볼 수 있도록 하는 열거형입니다.
enum PreviewFanType {
  /// VIP 장기 구독자 (300일 이상)
  vipLongTime,

  /// VIP 신규 구독자 (7일 이내)
  vipNew,

  /// STANDARD 중기 구독자 (100일)
  standardMid,

  /// BASIC 신규 구독자 (1일)
  basicNew,

  /// 커스텀 설정 (직접 지정)
  custom,
}

/// 미리보기용 팬 샘플 데이터
class PreviewFanSampleData {
  final String name;
  final String tier;
  final int subscriptionDays;
  final int characterLimit;

  const PreviewFanSampleData({
    required this.name,
    required this.tier,
    required this.subscriptionDays,
    required this.characterLimit,
  });
}

/// PreviewFanType 확장
extension PreviewFanTypeExtension on PreviewFanType {
  /// 해당 팬 타입의 샘플 데이터 반환
  PreviewFanSampleData get sampleData {
    switch (this) {
      case PreviewFanType.vipLongTime:
        return const PreviewFanSampleData(
          name: '오래된 VIP 팬',
          tier: 'VIP',
          subscriptionDays: 365,
          characterLimit: 300,
        );
      case PreviewFanType.vipNew:
        return const PreviewFanSampleData(
          name: '신규 VIP 팬',
          tier: 'VIP',
          subscriptionDays: 7,
          characterLimit: 50,
        );
      case PreviewFanType.standardMid:
        return const PreviewFanSampleData(
          name: '중기 STANDARD 팬',
          tier: 'STANDARD',
          subscriptionDays: 100,
          characterLimit: 100,
        );
      case PreviewFanType.basicNew:
        return const PreviewFanSampleData(
          name: '신규 BASIC 팬',
          tier: 'BASIC',
          subscriptionDays: 1,
          characterLimit: 50,
        );
      case PreviewFanType.custom:
        // 커스텀은 기본값으로 VIP 장기 구독자와 동일
        return const PreviewFanSampleData(
          name: '커스텀 팬',
          tier: 'VIP',
          subscriptionDays: 100,
          characterLimit: 100,
        );
    }
  }

  /// 해당 팬 타입의 설명
  String get description {
    switch (this) {
      case PreviewFanType.vipLongTime:
        return '1년 이상 구독한 VIP 팬';
      case PreviewFanType.vipNew:
        return '최근 가입한 VIP 팬';
      case PreviewFanType.standardMid:
        return '약 3개월 구독한 STANDARD 팬';
      case PreviewFanType.basicNew:
        return '방금 가입한 BASIC 팬';
      case PreviewFanType.custom:
        return '직접 설정';
    }
  }

  /// 해당 팬 타입의 아이콘
  String get iconName {
    switch (this) {
      case PreviewFanType.vipLongTime:
        return 'star';
      case PreviewFanType.vipNew:
        return 'star_border';
      case PreviewFanType.standardMid:
        return 'person';
      case PreviewFanType.basicNew:
        return 'person_outline';
      case PreviewFanType.custom:
        return 'tune';
    }
  }
}

/// 구독 일수에 따른 글자 수 제한 계산
int getCharacterLimitForDays(int days) {
  // BusinessConfig의 characterLimitsByDays 맵 사용
  final limits = BusinessConfig.characterLimitsByDays;

  // 내림차순으로 정렬된 키들을 순회하여 해당하는 제한 찾기
  final sortedKeys = limits.keys.toList()..sort((a, b) => b.compareTo(a));

  for (final threshold in sortedKeys) {
    if (days >= threshold) {
      return limits[threshold]!;
    }
  }

  // 기본값 (1일 미만 또는 예외 상황)
  return limits[1] ?? 50;
}
