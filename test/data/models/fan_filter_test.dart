import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/fan_filter.dart';

void main() {
  group('FanFilterType', () {
    group('displayName', () {
      test('returns Korean display name for each filter type', () {
        expect(
          FanFilterType.allFans.displayName,
          equals('내 채팅방의 모든 팬'),
        );
        expect(
          FanFilterType.birthdayToday.displayName,
          equals('오늘 생일인 팬'),
        );
        expect(
          FanFilterType.vipSubscribers.displayName,
          equals('VIP 티어 구독자 전체'),
        );
        expect(
          FanFilterType.favorites.displayName,
          equals('즐겨찾기 팬'),
        );
      });
    });

    group('description', () {
      test('returns Korean description for each filter type', () {
        expect(
          FanFilterType.allFans.description,
          contains('모든 팬'),
        );
        expect(
          FanFilterType.topDonors30Days.description,
          contains('DT'),
        );
        expect(
          FanFilterType.longTermSub12m.description,
          contains('12개월'),
        );
      });
    });
  });

  group('FanSummary', () {
    Map<String, dynamic> _createFanSummaryJson({
      String userId = 'fan-1',
      String displayName = '하늘덕후',
      String? avatarUrl,
      String? tier,
      int daysSubscribed = 120,
      bool isFavorite = false,
      int? totalDonation,
      int? replyCount,
    }) {
      return {
        'user_id': userId,
        'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (tier != null) 'tier': tier,
        'days_subscribed': daysSubscribed,
        'is_favorite': isFavorite,
        if (totalDonation != null) 'total_donation': totalDonation,
        if (replyCount != null) 'reply_count': replyCount,
      };
    }

    group('fromJson / toJson', () {
      test('round-trips all fields correctly', () {
        final json = _createFanSummaryJson(
          tier: 'VIP',
          isFavorite: true,
          totalDonation: 50000,
          replyCount: 120,
        );
        final fan = FanSummary.fromJson(json);
        final restored = FanSummary.fromJson(fan.toJson());

        expect(restored.userId, equals('fan-1'));
        expect(restored.displayName, equals('하늘덕후'));
        expect(restored.tier, equals('VIP'));
        expect(restored.daysSubscribed, equals(120));
        expect(restored.isFavorite, isTrue);
        expect(restored.totalDonation, equals(50000));
        expect(restored.replyCount, equals(120));
      });

      test('defaults tier to BASIC when absent', () {
        final fan = FanSummary.fromJson(_createFanSummaryJson());
        expect(fan.tier, equals('BASIC'));
      });
    });

    group('tierBadge', () {
      test('returns diamond emoji for VIP', () {
        final fan = FanSummary.fromJson(_createFanSummaryJson(tier: 'VIP'));
        expect(fan.tierBadge, equals('💎 VIP'));
      });

      test('returns star emoji for STANDARD', () {
        final fan =
            FanSummary.fromJson(_createFanSummaryJson(tier: 'STANDARD'));
        expect(fan.tierBadge, equals('⭐ STANDARD'));
      });

      test('returns BASIC for unknown tier', () {
        final fan = FanSummary.fromJson(_createFanSummaryJson(tier: 'OTHER'));
        expect(fan.tierBadge, equals('BASIC'));
      });
    });

    group('formattedDuration', () {
      test('returns N일째 for less than 365 days', () {
        final fan =
            FanSummary.fromJson(_createFanSummaryJson(daysSubscribed: 120));
        expect(fan.formattedDuration, equals('120일째'));
      });

      test('returns N년째 for 365+ days', () {
        final fan =
            FanSummary.fromJson(_createFanSummaryJson(daysSubscribed: 730));
        expect(fan.formattedDuration, equals('2년째'));
      });

      test('returns 365일째 at boundary', () {
        final fan =
            FanSummary.fromJson(_createFanSummaryJson(daysSubscribed: 364));
        expect(fan.formattedDuration, equals('364일째'));
      });

      test('returns 1년째 at exactly 365', () {
        final fan =
            FanSummary.fromJson(_createFanSummaryJson(daysSubscribed: 365));
        expect(fan.formattedDuration, equals('1년째'));
      });
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final fan = FanSummary.fromJson(
          _createFanSummaryJson(tier: 'VIP', daysSubscribed: 200),
        );
        final copy = fan.copyWith(isFavorite: true);

        expect(copy.isFavorite, isTrue);
        expect(copy.tier, equals('VIP'));
        expect(copy.daysSubscribed, equals(200));
        expect(copy.userId, equals(fan.userId));
      });
    });
  });
}
