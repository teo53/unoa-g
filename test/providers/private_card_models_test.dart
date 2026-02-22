// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/data/models/fan_filter.dart';
import 'package:uno_a_flutter/data/models/private_card.dart';
import 'package:uno_a_flutter/providers/private_card_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

FanSummary _makeFan({
  String userId = 'user-1',
  String displayName = 'Test Fan',
  String? avatarUrl,
  String tier = 'BASIC',
  int daysSubscribed = 10,
  bool isFavorite = false,
  int? totalDonation,
  int? replyCount,
}) {
  return FanSummary(
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    tier: tier,
    daysSubscribed: daysSubscribed,
    isFavorite: isFavorite,
    totalDonation: totalDonation,
    replyCount: replyCount,
  );
}

PrivateCard _makeCard({
  String id = 'card-1',
  String channelId = 'channel-1',
  String artistId = 'artist-1',
  DateTime? createdAt,
}) {
  return PrivateCard(
    id: id,
    channelId: channelId,
    artistId: artistId,
    cardTemplateId: 'template-1',
    createdAt: createdAt ?? DateTime(2025, 1, 1),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ==========================================================================
  // PrivateCardComposeState
  // ==========================================================================

  group('PrivateCardComposeState construction', () {
    test('default constructor sets all expected defaults', () {
      const state = PrivateCardComposeState();

      expect(state.currentStep, 0);
      expect(state.cardText, '');
      expect(state.selectedTemplateId, isNull);
      expect(state.selectedTemplateImageUrl, isNull);
      expect(state.attachedMediaUrls, isEmpty);
      expect(state.selectedFilter, isNull);
      expect(state.matchedFans, isEmpty);
      expect(state.selectedFanIds, isEmpty);
      expect(state.favoriteFans, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isSending, isFalse);
      expect(state.isSent, isFalse);
      expect(state.error, isNull);
    });

    test('explicit values are stored correctly', () {
      final fans = [_makeFan(userId: 'u1'), _makeFan(userId: 'u2')];
      final state = PrivateCardComposeState(
        currentStep: 2,
        cardText: '안녕하세요',
        selectedTemplateId: 'tmpl-hearts',
        selectedTemplateImageUrl: 'https://example.com/img.png',
        attachedMediaUrls: const ['https://example.com/media.jpg'],
        selectedFilter: FanFilterType.vipSubscribers,
        matchedFans: fans,
        selectedFanIds: const {'u1', 'u2'},
        favoriteFans: [fans.first],
        isLoading: false,
        isSending: true,
        isSent: false,
        error: null,
      );

      expect(state.currentStep, 2);
      expect(state.cardText, '안녕하세요');
      expect(state.selectedTemplateId, 'tmpl-hearts');
      expect(state.selectedTemplateImageUrl, 'https://example.com/img.png');
      expect(state.attachedMediaUrls, hasLength(1));
      expect(state.selectedFilter, FanFilterType.vipSubscribers);
      expect(state.matchedFans, hasLength(2));
      expect(state.selectedFanIds, containsAll(['u1', 'u2']));
      expect(state.favoriteFans, hasLength(1));
      expect(state.isSending, isTrue);
    });
  });

  group('PrivateCardComposeState.copyWith', () {
    test('returns new instance — does not mutate original', () {
      const original = PrivateCardComposeState(currentStep: 0);
      final copy = original.copyWith(currentStep: 1);

      expect(original.currentStep, 0);
      expect(copy.currentStep, 1);
    });

    test('preserves all unchanged fields', () {
      final fans = [_makeFan(userId: 'u1')];
      final state = PrivateCardComposeState(
        currentStep: 1,
        cardText: 'hello',
        selectedTemplateId: 'tmpl-1',
        matchedFans: fans,
        selectedFanIds: const {'u1'},
        isLoading: true,
      );

      final copy = state.copyWith(currentStep: 2);

      expect(copy.cardText, 'hello');
      expect(copy.selectedTemplateId, 'tmpl-1');
      expect(copy.matchedFans, same(fans));
      expect(copy.selectedFanIds, containsAll(['u1']));
      expect(copy.isLoading, isTrue);
    });

    test('error is always replaced by copyWith (never preserved implicitly)',
        () {
      const withError = PrivateCardComposeState(error: 'something went wrong');

      // copyWith with no error argument should set error to null (source uses: error: error)
      final copy = withError.copyWith(cardText: 'new text');
      expect(copy.error, isNull);
    });

    test('error can be set explicitly via copyWith', () {
      const original = PrivateCardComposeState();
      final copy = original.copyWith(error: 'network error');
      expect(copy.error, 'network error');
    });

    test('can update multiple fields at once', () {
      const original = PrivateCardComposeState();
      final copy = original.copyWith(
        currentStep: 2,
        cardText: '수정된 텍스트',
        isLoading: true,
        isSent: true,
      );

      expect(copy.currentStep, 2);
      expect(copy.cardText, '수정된 텍스트');
      expect(copy.isLoading, isTrue);
      expect(copy.isSent, isTrue);
    });

    test('selectedFanIds can be cleared', () {
      final state = PrivateCardComposeState(
        selectedFanIds: const {'u1', 'u2', 'u3'},
      );
      final copy = state.copyWith(selectedFanIds: {});
      expect(copy.selectedFanIds, isEmpty);
    });
  });

  group('PrivateCardComposeState.isStep1Valid', () {
    test('false when both templateId and cardText are empty (default)', () {
      const state = PrivateCardComposeState();
      expect(state.isStep1Valid, isFalse);
    });

    test('false when templateId is null and cardText is non-empty', () {
      const state = PrivateCardComposeState(cardText: '메시지 내용');
      expect(state.isStep1Valid, isFalse);
    });

    test('false when templateId is set but cardText is empty', () {
      const state = PrivateCardComposeState(selectedTemplateId: 'tmpl-1');
      expect(state.isStep1Valid, isFalse);
    });

    test('false when templateId is set but cardText is whitespace only', () {
      const state = PrivateCardComposeState(
        selectedTemplateId: 'tmpl-1',
        cardText: '   ',
      );
      expect(state.isStep1Valid, isFalse);
    });

    test('true when templateId is set and cardText is non-empty', () {
      const state = PrivateCardComposeState(
        selectedTemplateId: 'tmpl-1',
        cardText: '안녕하세요!',
      );
      expect(state.isStep1Valid, isTrue);
    });

    test('true when templateId is set and cardText has only single char', () {
      const state = PrivateCardComposeState(
        selectedTemplateId: 'tmpl-hearts',
        cardText: 'A',
      );
      expect(state.isStep1Valid, isTrue);
    });
  });

  group('PrivateCardComposeState.isStep2Valid', () {
    test('false when selectedFanIds is empty (default)', () {
      const state = PrivateCardComposeState();
      expect(state.isStep2Valid, isFalse);
    });

    test('true when one fan is selected', () {
      const state = PrivateCardComposeState(selectedFanIds: {'u1'});
      expect(state.isStep2Valid, isTrue);
    });

    test('true when multiple fans are selected', () {
      const state = PrivateCardComposeState(
        selectedFanIds: {'u1', 'u2', 'u3'},
      );
      expect(state.isStep2Valid, isTrue);
    });

    test('false after clearing all selectedFanIds via copyWith', () {
      const original = PrivateCardComposeState(
        selectedFanIds: {'u1', 'u2'},
      );
      final cleared = original.copyWith(selectedFanIds: {});
      expect(cleared.isStep2Valid, isFalse);
    });
  });

  group('PrivateCardComposeState.selectedFanCount', () {
    test('returns 0 for default empty state', () {
      const state = PrivateCardComposeState();
      expect(state.selectedFanCount, 0);
    });

    test('returns 1 when exactly one fan is selected', () {
      const state = PrivateCardComposeState(selectedFanIds: {'u1'});
      expect(state.selectedFanCount, 1);
    });

    test('returns correct count for multiple selections', () {
      const state = PrivateCardComposeState(
        selectedFanIds: {'u1', 'u2', 'u3', 'u4', 'u5'},
      );
      expect(state.selectedFanCount, 5);
    });

    test('count updates correctly after copyWith adds fans', () {
      const original = PrivateCardComposeState(selectedFanIds: {'u1'});
      final updated = original.copyWith(selectedFanIds: {'u1', 'u2', 'u3'});
      expect(updated.selectedFanCount, 3);
    });

    test('count is 0 after deselectAll via copyWith', () {
      const original = PrivateCardComposeState(
        selectedFanIds: {'u1', 'u2', 'u3'},
      );
      final cleared = original.copyWith(selectedFanIds: {});
      expect(cleared.selectedFanCount, 0);
    });
  });

  // ==========================================================================
  // PrivateCardHistoryState
  // ==========================================================================

  group('PrivateCardHistoryState construction', () {
    test('default constructor uses correct defaults', () {
      const state = PrivateCardHistoryState();

      expect(state.sentCards, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('accepts explicit values', () {
      final cards = [_makeCard(), _makeCard(id: 'card-2')];
      final state = PrivateCardHistoryState(
        sentCards: cards,
        isLoading: true,
        error: 'failed to load',
      );

      expect(state.sentCards, hasLength(2));
      expect(state.isLoading, isTrue);
      expect(state.error, 'failed to load');
    });
  });

  group('PrivateCardHistoryState.copyWith', () {
    test('preserves unchanged fields', () {
      final cards = [_makeCard()];
      final original = PrivateCardHistoryState(
        sentCards: cards,
        isLoading: false,
      );

      final copy = original.copyWith(isLoading: true);

      expect(copy.sentCards, same(cards));
      expect(copy.isLoading, isTrue);
      expect(copy.error, isNull);
    });

    test('error is always replaced (never implicitly preserved)', () {
      final withError = PrivateCardHistoryState(error: 'old error');
      final copy = withError.copyWith(isLoading: true);
      expect(copy.error, isNull);
    });

    test('can set new sentCards list', () {
      const original = PrivateCardHistoryState();
      final cards = [_makeCard(), _makeCard(id: 'card-2')];
      final copy = original.copyWith(sentCards: cards);

      expect(copy.sentCards, hasLength(2));
    });
  });

  // ==========================================================================
  // FanFilterType enum
  // ==========================================================================

  group('FanFilterType.values', () {
    test('enum has exactly 10 values', () {
      expect(FanFilterType.values.length, 10);
    });

    test('all expected values are present', () {
      expect(
        FanFilterType.values,
        containsAll([
          FanFilterType.allFans,
          FanFilterType.birthdayToday,
          FanFilterType.topDonors30Days,
          FanFilterType.topRepliers30Days,
          FanFilterType.questionParticipants,
          FanFilterType.hundredDayMembers,
          FanFilterType.vipSubscribers,
          FanFilterType.longTermSub12m,
          FanFilterType.longTermSub24m,
          FanFilterType.favorites,
        ]),
      );
    });
  });

  group('FanFilterType.displayName', () {
    test('allFans returns correct Korean label', () {
      expect(FanFilterType.allFans.displayName, '내 채팅방의 모든 팬');
    });

    test('birthdayToday returns correct Korean label', () {
      expect(FanFilterType.birthdayToday.displayName, '오늘 생일인 팬');
    });

    test('topDonors30Days returns correct Korean label', () {
      expect(FanFilterType.topDonors30Days.displayName, '지난 30일 DT 후원 TOP 5');
    });

    test('topRepliers30Days returns correct Korean label', () {
      expect(
        FanFilterType.topRepliers30Days.displayName,
        '지난 30일 답글 많이 보낸 TOP 5',
      );
    });

    test('vipSubscribers returns correct Korean label', () {
      expect(FanFilterType.vipSubscribers.displayName, 'VIP 티어 구독자 전체');
    });

    test('longTermSub12m returns correct Korean label', () {
      expect(FanFilterType.longTermSub12m.displayName, '구독 12개월 이상 팬');
    });

    test('longTermSub24m returns correct Korean label', () {
      expect(FanFilterType.longTermSub24m.displayName, '구독 24개월 이상 팬');
    });

    test('favorites returns correct Korean label', () {
      expect(FanFilterType.favorites.displayName, '즐겨찾기 팬');
    });

    test('every value has a non-empty displayName', () {
      for (final filter in FanFilterType.values) {
        expect(
          filter.displayName.isNotEmpty,
          isTrue,
          reason: '${filter.name} should have a non-empty displayName',
        );
      }
    });
  });

  group('FanFilterType.description', () {
    test('allFans description is non-empty', () {
      expect(FanFilterType.allFans.description.isNotEmpty, isTrue);
    });

    test('birthdayToday description mentions 생일', () {
      expect(FanFilterType.birthdayToday.description, contains('생일'));
    });

    test('topDonors30Days description mentions DT', () {
      expect(FanFilterType.topDonors30Days.description, contains('DT'));
    });

    test('vipSubscribers description mentions VIP', () {
      expect(FanFilterType.vipSubscribers.description, contains('VIP'));
    });

    test('longTermSub12m description mentions 12개월', () {
      expect(FanFilterType.longTermSub12m.description, contains('12개월'));
    });

    test('every value has a non-empty description', () {
      for (final filter in FanFilterType.values) {
        expect(
          filter.description.isNotEmpty,
          isTrue,
          reason: '${filter.name} should have a non-empty description',
        );
      }
    });
  });

  // ==========================================================================
  // FanSummary
  // ==========================================================================

  group('FanSummary.fromJson / toJson round-trip', () {
    test('full JSON round-trip preserves all fields', () {
      final json = <String, dynamic>{
        'user_id': 'u-abc',
        'display_name': '하늘별',
        'avatar_url': 'https://example.com/avatar.png',
        'tier': 'VIP',
        'days_subscribed': 400,
        'is_favorite': true,
        'total_donation': 50000,
        'reply_count': 120,
      };

      final fan = FanSummary.fromJson(json);

      expect(fan.userId, 'u-abc');
      expect(fan.displayName, '하늘별');
      expect(fan.avatarUrl, 'https://example.com/avatar.png');
      expect(fan.tier, 'VIP');
      expect(fan.daysSubscribed, 400);
      expect(fan.isFavorite, isTrue);
      expect(fan.totalDonation, 50000);
      expect(fan.replyCount, 120);

      final back = fan.toJson();
      expect(back['user_id'], 'u-abc');
      expect(back['display_name'], '하늘별');
      expect(back['avatar_url'], 'https://example.com/avatar.png');
      expect(back['tier'], 'VIP');
      expect(back['days_subscribed'], 400);
      expect(back['is_favorite'], isTrue);
      expect(back['total_donation'], 50000);
      expect(back['reply_count'], 120);
    });

    test('partial JSON uses default values for missing fields', () {
      final json = <String, dynamic>{
        'user_id': 'u-minimal',
        'display_name': '팬이름',
      };

      final fan = FanSummary.fromJson(json);

      expect(fan.userId, 'u-minimal');
      expect(fan.displayName, '팬이름');
      expect(fan.avatarUrl, isNull);
      expect(fan.tier, 'BASIC');
      expect(fan.daysSubscribed, 0);
      expect(fan.isFavorite, isFalse);
      expect(fan.totalDonation, isNull);
      expect(fan.replyCount, isNull);
    });

    test('toJson includes null values for optional fields', () {
      final fan = FanSummary(
        userId: 'u-1',
        displayName: 'Fan',
        tier: 'STANDARD',
        daysSubscribed: 30,
      );

      final json = fan.toJson();

      expect(json.containsKey('avatar_url'), isTrue);
      expect(json['avatar_url'], isNull);
      expect(json.containsKey('total_donation'), isTrue);
      expect(json['total_donation'], isNull);
      expect(json.containsKey('reply_count'), isTrue);
      expect(json['reply_count'], isNull);
    });
  });

  group('FanSummary.tierBadge', () {
    test('VIP tier returns diamond badge', () {
      final fan = _makeFan(tier: 'VIP');
      expect(fan.tierBadge, '💎 VIP');
    });

    test('STANDARD tier returns star badge', () {
      final fan = _makeFan(tier: 'STANDARD');
      expect(fan.tierBadge, '⭐ STANDARD');
    });

    test('BASIC tier returns plain BASIC text', () {
      final fan = _makeFan(tier: 'BASIC');
      expect(fan.tierBadge, 'BASIC');
    });

    test('lowercase vip is treated as VIP (case-insensitive)', () {
      final fan = _makeFan(tier: 'vip');
      expect(fan.tierBadge, '💎 VIP');
    });

    test('lowercase standard is treated as STANDARD', () {
      final fan = _makeFan(tier: 'standard');
      expect(fan.tierBadge, '⭐ STANDARD');
    });

    test('unknown tier falls back to BASIC', () {
      final fan = _makeFan(tier: 'PLATINUM');
      expect(fan.tierBadge, 'BASIC');
    });
  });

  group('FanSummary.formattedDuration', () {
    test('less than 365 days returns Nd일째', () {
      final fan = _makeFan(daysSubscribed: 30);
      expect(fan.formattedDuration, '30일째');
    });

    test('exactly 365 days returns 1년째', () {
      final fan = _makeFan(daysSubscribed: 365);
      expect(fan.formattedDuration, '1년째');
    });

    test('730 days returns 2년째', () {
      final fan = _makeFan(daysSubscribed: 730);
      expect(fan.formattedDuration, '2년째');
    });

    test('1095 days returns 3년째', () {
      final fan = _makeFan(daysSubscribed: 1095);
      expect(fan.formattedDuration, '3년째');
    });

    test('364 days still returns Nd일째 (not yet 1 year)', () {
      final fan = _makeFan(daysSubscribed: 364);
      expect(fan.formattedDuration, '364일째');
    });

    test('0 days returns 0일째', () {
      final fan = _makeFan(daysSubscribed: 0);
      expect(fan.formattedDuration, '0일째');
    });

    test('1 day returns 1일째', () {
      final fan = _makeFan(daysSubscribed: 1);
      expect(fan.formattedDuration, '1일째');
    });
  });

  group('FanSummary.copyWith', () {
    test('preserves unchanged fields', () {
      final original = _makeFan(
        userId: 'u-orig',
        displayName: 'Original Fan',
        tier: 'VIP',
        daysSubscribed: 200,
        isFavorite: true,
        totalDonation: 30000,
        replyCount: 50,
      );

      final copy = original.copyWith(displayName: 'Updated Fan');

      expect(copy.userId, 'u-orig');
      expect(copy.displayName, 'Updated Fan');
      expect(copy.tier, 'VIP');
      expect(copy.daysSubscribed, 200);
      expect(copy.isFavorite, isTrue);
      expect(copy.totalDonation, 30000);
      expect(copy.replyCount, 50);
    });

    test('can toggle isFavorite', () {
      final fan = _makeFan(isFavorite: false);
      final toggled = fan.copyWith(isFavorite: true);
      expect(toggled.isFavorite, isTrue);
    });

    test('can update tier', () {
      final fan = _makeFan(tier: 'BASIC');
      final upgraded = fan.copyWith(tier: 'VIP');
      expect(upgraded.tier, 'VIP');
    });

    test('can update multiple fields at once', () {
      final fan = _makeFan(
        tier: 'BASIC',
        daysSubscribed: 10,
        isFavorite: false,
      );
      final updated = fan.copyWith(
        tier: 'STANDARD',
        daysSubscribed: 100,
        isFavorite: true,
      );

      expect(updated.tier, 'STANDARD');
      expect(updated.daysSubscribed, 100);
      expect(updated.isFavorite, isTrue);
    });

    test('original is not mutated', () {
      final original = _makeFan(daysSubscribed: 50);
      original.copyWith(daysSubscribed: 999);
      expect(original.daysSubscribed, 50);
    });
  });
}
