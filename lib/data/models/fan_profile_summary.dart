/// Fan Profile Summary Model
/// 크리에이터 CRM에서 사용하는 팬 프로필 요약 정보
library;

import 'fan_note.dart';
import 'fan_tag.dart';

class FanProfileSummary {
  final String fanId;
  final String displayName;
  final String? avatarUrl;
  final String tier;
  final int subscribedDays;
  final int totalDtSpent;
  final FanNote? note;
  final List<FanTag> tags;

  const FanProfileSummary({
    required this.fanId,
    required this.displayName,
    this.avatarUrl,
    this.tier = 'BASIC',
    this.subscribedDays = 0,
    this.totalDtSpent = 0,
    this.note,
    this.tags = const [],
  });

  factory FanProfileSummary.fromJson(Map<String, dynamic> json) {
    return FanProfileSummary(
      fanId: json['fan_id'] as String,
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      tier: json['tier'] as String? ?? 'BASIC',
      subscribedDays: json['subscribed_days'] as int? ?? 0,
      totalDtSpent: json['total_dt_spent'] as int? ?? 0,
      note: json['note'] != null
          ? FanNote.fromJson(json['note'] as Map<String, dynamic>)
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => FanTag.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fan_id': fanId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'tier': tier,
      'subscribed_days': subscribedDays,
      'total_dt_spent': totalDtSpent,
      'note': note?.toJson(),
      'tags': tags.map((t) => t.toJson()).toList(),
    };
  }

  FanProfileSummary copyWith({
    String? fanId,
    String? displayName,
    String? avatarUrl,
    String? tier,
    int? subscribedDays,
    int? totalDtSpent,
    FanNote? note,
    List<FanTag>? tags,
  }) {
    return FanProfileSummary(
      fanId: fanId ?? this.fanId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tier: tier ?? this.tier,
      subscribedDays: subscribedDays ?? this.subscribedDays,
      totalDtSpent: totalDtSpent ?? this.totalDtSpent,
      note: note ?? this.note,
      tags: tags ?? this.tags,
    );
  }

  /// 티어 표시 라벨
  String get tierLabel {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return 'VIP';
      case 'STANDARD':
        return 'Standard';
      case 'BASIC':
      default:
        return 'Basic';
    }
  }

  /// 구독 기간 표시 텍스트
  String get subscribedDaysText {
    if (subscribedDays <= 0) return '신규';
    if (subscribedDays < 30) return '$subscribedDays일';
    final months = subscribedDays ~/ 30;
    final remaining = subscribedDays % 30;
    if (remaining == 0) return '$months개월';
    return '$months개월 $remaining일';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FanProfileSummary &&
        other.fanId == fanId &&
        other.displayName == displayName &&
        other.tier == tier;
  }

  @override
  int get hashCode {
    return Object.hash(fanId, displayName, tier);
  }

  @override
  String toString() {
    return 'FanProfileSummary(fanId: $fanId, name: $displayName, tier: $tier, days: $subscribedDays)';
  }
}
