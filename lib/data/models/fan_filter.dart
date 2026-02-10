import 'package:flutter/material.dart';

/// Fan filter types for selecting recipients of private cards
/// Customized for UNO A platform features (DT donations, reply tokens, questions, tiers)
enum FanFilterType {
  /// 내 채팅방의 모든 팬
  allFans,

  /// 오늘 생일인 팬
  birthdayToday,

  /// 지난 30일 DT 후원 TOP 5
  topDonors30Days,

  /// 지난 30일 답글 많이 보낸 TOP 5
  topRepliers30Days,

  /// 오늘의 질문에 참여한 모든 팬
  questionParticipants,

  /// 구독 100일째 팬
  hundredDayMembers,

  /// VIP 티어 구독자 전체
  vipSubscribers,

  /// 구독 12개월 이상 팬
  longTermSub12m,

  /// 구독 24개월 이상 팬
  longTermSub24m,

  /// 즐겨찾기 팬
  favorites,
}

/// Extension to provide display data for each filter type
extension FanFilterTypeExtension on FanFilterType {
  String get displayName {
    switch (this) {
      case FanFilterType.allFans:
        return '내 채팅방의 모든 팬';
      case FanFilterType.birthdayToday:
        return '오늘 생일인 팬';
      case FanFilterType.topDonors30Days:
        return '지난 30일 DT 후원 TOP 5';
      case FanFilterType.topRepliers30Days:
        return '지난 30일 답글 많이 보낸 TOP 5';
      case FanFilterType.questionParticipants:
        return '오늘의 질문에 참여한 모든 팬';
      case FanFilterType.hundredDayMembers:
        return '구독 100일째 팬';
      case FanFilterType.vipSubscribers:
        return 'VIP 티어 구독자 전체';
      case FanFilterType.longTermSub12m:
        return '구독 12개월 이상 팬';
      case FanFilterType.longTermSub24m:
        return '구독 24개월 이상 팬';
      case FanFilterType.favorites:
        return '즐겨찾기 팬';
    }
  }

  IconData get icon {
    switch (this) {
      case FanFilterType.allFans:
        return Icons.people_rounded;
      case FanFilterType.birthdayToday:
        return Icons.cake_rounded;
      case FanFilterType.topDonors30Days:
        return Icons.diamond_rounded;
      case FanFilterType.topRepliers30Days:
        return Icons.chat_rounded;
      case FanFilterType.questionParticipants:
        return Icons.quiz_rounded;
      case FanFilterType.hundredDayMembers:
        return Icons.event_rounded;
      case FanFilterType.vipSubscribers:
        return Icons.star_rounded;
      case FanFilterType.longTermSub12m:
        return Icons.loyalty_rounded;
      case FanFilterType.longTermSub24m:
        return Icons.workspace_premium_rounded;
      case FanFilterType.favorites:
        return Icons.favorite_rounded;
    }
  }

  String get description {
    switch (this) {
      case FanFilterType.allFans:
        return '구독 중인 모든 팬에게 전송합니다';
      case FanFilterType.birthdayToday:
        return '오늘이 생일인 팬에게 축하 카드를 보냅니다';
      case FanFilterType.topDonors30Days:
        return '최근 30일 동안 가장 많이 DT를 후원한 팬 5명';
      case FanFilterType.topRepliers30Days:
        return '최근 30일 동안 답글을 가장 많이 보낸 팬 5명';
      case FanFilterType.questionParticipants:
        return '오늘의 질문 카드에 참여한 모든 팬';
      case FanFilterType.hundredDayMembers:
        return '구독한지 100일이 된 팬에게 감사 카드를 보냅니다';
      case FanFilterType.vipSubscribers:
        return 'VIP 구독 티어를 사용 중인 모든 팬';
      case FanFilterType.longTermSub12m:
        return '12개월 이상 꾸준히 구독 중인 팬';
      case FanFilterType.longTermSub24m:
        return '24개월 이상 꾸준히 구독 중인 팬';
      case FanFilterType.favorites:
        return '즐겨찾기에 등록된 팬에게만 전송합니다';
    }
  }
}

/// Summary of a fan for selection UI
class FanSummary {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String tier;
  final int daysSubscribed;
  final bool isFavorite;
  final int? totalDonation;
  final int? replyCount;

  const FanSummary({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.tier,
    required this.daysSubscribed,
    this.isFavorite = false,
    this.totalDonation,
    this.replyCount,
  });

  FanSummary copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? tier,
    int? daysSubscribed,
    bool? isFavorite,
    int? totalDonation,
    int? replyCount,
  }) {
    return FanSummary(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tier: tier ?? this.tier,
      daysSubscribed: daysSubscribed ?? this.daysSubscribed,
      isFavorite: isFavorite ?? this.isFavorite,
      totalDonation: totalDonation ?? this.totalDonation,
      replyCount: replyCount ?? this.replyCount,
    );
  }

  /// Tier badge text
  String get tierBadge {
    switch (tier.toUpperCase()) {
      case 'VIP':
        return '💎 VIP';
      case 'STANDARD':
        return '⭐ STANDARD';
      default:
        return 'BASIC';
    }
  }

  /// Formatted subscription duration
  String get formattedDuration {
    if (daysSubscribed >= 365) {
      final years = daysSubscribed ~/ 365;
      return '$years년째';
    }
    return '$daysSubscribed일째';
  }

  factory FanSummary.fromJson(Map<String, dynamic> json) {
    return FanSummary(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      tier: json['tier'] as String? ?? 'BASIC',
      daysSubscribed: json['days_subscribed'] as int? ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      totalDonation: json['total_donation'] as int?,
      replyCount: json['reply_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'tier': tier,
        'days_subscribed': daysSubscribed,
        'is_favorite': isFavorite,
        'total_donation': totalDonation,
        'reply_count': replyCount,
      };
}
