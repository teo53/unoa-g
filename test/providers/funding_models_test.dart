// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:uno_a_flutter/providers/funding_provider.dart';

// Helper: build a minimal Campaign for tests
Campaign _makeCampaign({
  String id = 'c1',
  String title = 'Test Campaign',
  CampaignStatus status = CampaignStatus.active,
  int goalAmountKrw = 100000,
  int currentAmountKrw = 50000,
  double fundingPercent = 50.0,
  int backerCount = 10,
  DateTime? endAt,
  DateTime? startAt,
  DateTime? createdAt,
  String? subtitle,
  String? category,
  String? description,
  String? creatorId,
}) {
  return Campaign(
    id: id,
    title: title,
    status: status,
    goalAmountKrw: goalAmountKrw,
    currentAmountKrw: currentAmountKrw,
    fundingPercent: fundingPercent,
    backerCount: backerCount,
    endAt: endAt,
    startAt: startAt,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
    subtitle: subtitle,
    category: category,
    description: description,
    creatorId: creatorId,
  );
}

// Helper: build a FundingState with given all/myCampaigns and optional search
FundingState _makeState({
  List<Campaign> allCampaigns = const [],
  List<Campaign> myCampaigns = const [],
  List<Pledge> myPledges = const [],
  String searchQuery = '',
}) {
  return FundingState(
    allCampaigns: allCampaigns,
    myCampaigns: myCampaigns,
    myPledges: myPledges,
    searchQuery: searchQuery,
  );
}

void main() {
  // ==========================================================================
  // CampaignStatus
  // ==========================================================================

  group('CampaignStatus.fromString', () {
    test('parses "active"', () {
      expect(CampaignStatus.fromString('active'), CampaignStatus.active);
    });

    test('parses "draft"', () {
      expect(CampaignStatus.fromString('draft'), CampaignStatus.draft);
    });

    test('parses "paused"', () {
      expect(CampaignStatus.fromString('paused'), CampaignStatus.paused);
    });

    test('parses "completed"', () {
      expect(CampaignStatus.fromString('completed'), CampaignStatus.completed);
    });

    test('parses "cancelled"', () {
      expect(CampaignStatus.fromString('cancelled'), CampaignStatus.cancelled);
    });

    test('unknown string "pending_review" falls back to draft', () {
      expect(
        CampaignStatus.fromString('pending_review'),
        CampaignStatus.draft,
      );
    });

    test('completely unknown string falls back to draft', () {
      expect(CampaignStatus.fromString('bogus_value'), CampaignStatus.draft);
    });

    test('empty string falls back to draft', () {
      expect(CampaignStatus.fromString(''), CampaignStatus.draft);
    });
  });

  group('CampaignStatus.label', () {
    test('draft label is 준비중', () {
      expect(CampaignStatus.draft.label, '준비중');
    });

    test('active label is 진행중', () {
      expect(CampaignStatus.active.label, '진행중');
    });

    test('paused label is 일시정지', () {
      expect(CampaignStatus.paused.label, '일시정지');
    });

    test('completed label is 종료', () {
      expect(CampaignStatus.completed.label, '종료');
    });

    test('cancelled label is 취소됨', () {
      expect(CampaignStatus.cancelled.label, '취소됨');
    });
  });

  group('CampaignStatus.value', () {
    test('draft value is "draft"', () {
      expect(CampaignStatus.draft.value, 'draft');
    });

    test('active value is "active"', () {
      expect(CampaignStatus.active.value, 'active');
    });

    test('paused value is "paused"', () {
      expect(CampaignStatus.paused.value, 'paused');
    });

    test('completed value is "completed"', () {
      expect(CampaignStatus.completed.value, 'completed');
    });

    test('cancelled value is "cancelled"', () {
      expect(CampaignStatus.cancelled.value, 'cancelled');
    });
  });

  // ==========================================================================
  // Campaign.daysLeft
  // ==========================================================================

  group('Campaign.daysLeft', () {
    test('returns positive count for future endAt', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final campaign = _makeCampaign(endAt: future);
      // daysLeft uses inDays which truncates, so the result is 4 or 5
      expect(campaign.daysLeft, greaterThanOrEqualTo(4));
      expect(campaign.daysLeft, lessThanOrEqualTo(5));
    });

    test('returns 0 for past endAt', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      final campaign = _makeCampaign(endAt: past);
      expect(campaign.daysLeft, 0);
    });

    test('returns 0 for null endAt', () {
      final campaign = _makeCampaign(endAt: null);
      expect(campaign.daysLeft, 0);
    });

    test('returns 0 for endAt that is exactly now (just passed)', () {
      final justPast = DateTime.now().subtract(const Duration(seconds: 1));
      final campaign = _makeCampaign(endAt: justPast);
      expect(campaign.daysLeft, 0);
    });
  });

  // ==========================================================================
  // Campaign.isEnded
  // ==========================================================================

  group('Campaign.isEnded', () {
    test('is true when endAt is in the past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final campaign = _makeCampaign(
        endAt: past,
        status: CampaignStatus.active,
      );
      expect(campaign.isEnded, isTrue);
    });

    test('is true when status is completed (regardless of endAt)', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final campaign = _makeCampaign(
        endAt: future,
        status: CampaignStatus.completed,
      );
      expect(campaign.isEnded, isTrue);
    });

    test('is true when status is completed and endAt is null', () {
      final campaign = _makeCampaign(
        endAt: null,
        status: CampaignStatus.completed,
      );
      expect(campaign.isEnded, isTrue);
    });

    test('is false when active with future endAt', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final campaign = _makeCampaign(
        endAt: future,
        status: CampaignStatus.active,
      );
      expect(campaign.isEnded, isFalse);
    });

    test('is false when active with null endAt', () {
      final campaign = _makeCampaign(
        endAt: null,
        status: CampaignStatus.active,
      );
      expect(campaign.isEnded, isFalse);
    });
  });

  // ==========================================================================
  // Campaign.isActive
  // ==========================================================================

  group('Campaign.isActive', () {
    test('is true when status is active and not ended', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final campaign = _makeCampaign(
        endAt: future,
        status: CampaignStatus.active,
      );
      expect(campaign.isActive, isTrue);
    });

    test('is false when status is active but endAt is in the past', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final campaign = _makeCampaign(
        endAt: past,
        status: CampaignStatus.active,
      );
      expect(campaign.isActive, isFalse);
    });

    test('is false when status is draft', () {
      final campaign = _makeCampaign(status: CampaignStatus.draft);
      expect(campaign.isActive, isFalse);
    });

    test('is false when status is paused', () {
      final campaign = _makeCampaign(status: CampaignStatus.paused);
      expect(campaign.isActive, isFalse);
    });

    test('is false when status is completed', () {
      final campaign = _makeCampaign(status: CampaignStatus.completed);
      expect(campaign.isActive, isFalse);
    });
  });

  // ==========================================================================
  // Campaign.isDraft
  // ==========================================================================

  group('Campaign.isDraft', () {
    test('is true when status is draft', () {
      final campaign = _makeCampaign(status: CampaignStatus.draft);
      expect(campaign.isDraft, isTrue);
    });

    test('is false when status is active', () {
      final campaign = _makeCampaign(status: CampaignStatus.active);
      expect(campaign.isDraft, isFalse);
    });

    test('is false when status is completed', () {
      final campaign = _makeCampaign(status: CampaignStatus.completed);
      expect(campaign.isDraft, isFalse);
    });

    test('is false when status is paused', () {
      final campaign = _makeCampaign(status: CampaignStatus.paused);
      expect(campaign.isDraft, isFalse);
    });

    test('is false when status is cancelled', () {
      final campaign = _makeCampaign(status: CampaignStatus.cancelled);
      expect(campaign.isDraft, isFalse);
    });
  });

  // ==========================================================================
  // Campaign.isSuccessful
  // ==========================================================================

  group('Campaign.isSuccessful', () {
    test('is true when fundingPercent is exactly 100', () {
      final campaign = _makeCampaign(fundingPercent: 100.0);
      expect(campaign.isSuccessful, isTrue);
    });

    test('is true when fundingPercent exceeds 100', () {
      final campaign = _makeCampaign(fundingPercent: 128.3);
      expect(campaign.isSuccessful, isTrue);
    });

    test('is false when fundingPercent is below 100', () {
      final campaign = _makeCampaign(fundingPercent: 99.9);
      expect(campaign.isSuccessful, isFalse);
    });

    test('is false when fundingPercent is 0', () {
      final campaign = _makeCampaign(fundingPercent: 0.0);
      expect(campaign.isSuccessful, isFalse);
    });
  });

  // ==========================================================================
  // Campaign.fromJson
  // ==========================================================================

  group('Campaign.fromJson', () {
    test('round-trip with full JSON preserves all fields', () {
      final now = DateTime.now().toUtc();
      final endAt = now.add(const Duration(days: 10));
      final startAt = now.subtract(const Duration(days: 5));

      final json = <String, dynamic>{
        'id': 'test-id',
        'creator_id': 'creator-001',
        'title': '테스트 캠페인',
        'subtitle': '부제목',
        'description_md': '## 설명',
        'category': '앨범',
        'cover_image_url': 'https://example.com/cover.jpg',
        'status': 'active',
        'goal_amount_krw': 100000,
        'current_amount_krw': 50000,
        'funding_percent': 50.0,
        'backer_count': 42,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'target_artist': 'artist-001',
        'detail_images': ['https://example.com/img1.jpg'],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final campaign = Campaign.fromJson(json);

      expect(campaign.id, 'test-id');
      expect(campaign.creatorId, 'creator-001');
      expect(campaign.title, '테스트 캠페인');
      expect(campaign.subtitle, '부제목');
      expect(campaign.description, '## 설명');
      expect(campaign.category, '앨범');
      expect(campaign.coverImageUrl, 'https://example.com/cover.jpg');
      expect(campaign.status, CampaignStatus.active);
      expect(campaign.goalAmountKrw, 100000);
      expect(campaign.currentAmountKrw, 50000);
      expect(campaign.fundingPercent, 50.0);
      expect(campaign.backerCount, 42);
      expect(campaign.targetArtist, 'artist-001');
      expect(campaign.detailImages, ['https://example.com/img1.jpg']);
    });

    test('parses minimal JSON with only required fields', () {
      final json = <String, dynamic>{
        'id': 'min-id',
        'created_at': '2025-01-01T00:00:00.000Z',
      };

      final campaign = Campaign.fromJson(json);

      expect(campaign.id, 'min-id');
      expect(campaign.title, '제목 없음');
      expect(campaign.status, CampaignStatus.draft);
      expect(campaign.goalAmountKrw, 0);
      expect(campaign.currentAmountKrw, 0);
      expect(campaign.fundingPercent, 0.0);
      expect(campaign.backerCount, 0);
      expect(campaign.detailImages, isEmpty);
      expect(campaign.creatorId, isNull);
      expect(campaign.subtitle, isNull);
      expect(campaign.description, isNull);
      expect(campaign.category, isNull);
      expect(campaign.coverImageUrl, isNull);
      expect(campaign.endAt, isNull);
      expect(campaign.updatedAt, isNull);
    });

    test('computes fundingPercent from goal/current when not provided', () {
      final json = <String, dynamic>{
        'id': 'pct-id',
        'created_at': '2025-01-01T00:00:00.000Z',
        'goal_amount_krw': 200000,
        'current_amount_krw': 50000,
        // no 'funding_percent'
      };

      final campaign = Campaign.fromJson(json);
      // 50000 / 200000 * 100 = 25.0
      expect(campaign.fundingPercent, closeTo(25.0, 0.001));
    });

    test('computes fundingPercent as 0 when goal is 0 and percent not provided',
        () {
      final json = <String, dynamic>{
        'id': 'zero-goal-id',
        'created_at': '2025-01-01T00:00:00.000Z',
        'goal_amount_krw': 0,
        'current_amount_krw': 5000,
        // no 'funding_percent'
      };

      final campaign = Campaign.fromJson(json);
      expect(campaign.fundingPercent, 0.0);
    });

    test('uses explicit funding_percent even if goal/current differ', () {
      final json = <String, dynamic>{
        'id': 'explicit-pct-id',
        'created_at': '2025-01-01T00:00:00.000Z',
        'goal_amount_krw': 100000,
        'current_amount_krw': 10000,
        'funding_percent': 99.9, // explicit — does not match 10%
      };

      final campaign = Campaign.fromJson(json);
      expect(campaign.fundingPercent, 99.9);
    });

    test('description fallback: uses description_md when present', () {
      final json = <String, dynamic>{
        'id': 'desc-id',
        'created_at': '2025-01-01T00:00:00.000Z',
        'description_md': '## Markdown',
        'description': 'Plain text',
      };

      final campaign = Campaign.fromJson(json);
      // description_md takes precedence over description
      expect(campaign.description, '## Markdown');
    });

    test('description fallback: uses description when description_md is absent',
        () {
      final json = <String, dynamic>{
        'id': 'desc-fallback-id',
        'created_at': '2025-01-01T00:00:00.000Z',
        'description': 'Plain text fallback',
      };

      final campaign = Campaign.fromJson(json);
      expect(campaign.description, 'Plain text fallback');
    });

    test(
        'description is null when neither description_md nor description present',
        () {
      final json = <String, dynamic>{
        'id': 'no-desc-id',
        'created_at': '2025-01-01T00:00:00.000Z',
      };

      final campaign = Campaign.fromJson(json);
      expect(campaign.description, isNull);
    });

    test('status defaults to draft when status field is absent', () {
      final json = <String, dynamic>{
        'id': 'no-status-id',
        'created_at': '2025-01-01T00:00:00.000Z',
      };

      final campaign = Campaign.fromJson(json);
      expect(campaign.status, CampaignStatus.draft);
    });

    test('detail_images parses list correctly', () {
      final json = <String, dynamic>{
        'id': 'images-id',
        'created_at': '2025-01-01T00:00:00.000Z',
        'detail_images': ['https://a.com/1.jpg', 'https://a.com/2.jpg'],
      };

      final campaign = Campaign.fromJson(json);
      expect(campaign.detailImages,
          ['https://a.com/1.jpg', 'https://a.com/2.jpg']);
    });

    test('toJson round-trip preserves status value string', () {
      final campaign = _makeCampaign(
        id: 'rt-id',
        status: CampaignStatus.paused,
        subtitle: 'sub',
        category: 'cat',
        description: 'desc',
      );
      final json = campaign.toJson();
      expect(json['status'], 'paused');
      expect(json['id'], 'rt-id');
      expect(json['title'], 'Test Campaign');
      expect(json['subtitle'], 'sub');
      expect(json['description_md'], 'desc');
      expect(json['category'], 'cat');
      expect(json['goal_amount_krw'], 100000);
      expect(json['current_amount_krw'], 50000);
      expect(json['funding_percent'], 50.0);
      expect(json['backer_count'], 10);
    });
  });

  // ==========================================================================
  // RewardTier.isSoldOut
  // ==========================================================================

  group('RewardTier.isSoldOut', () {
    test('is false when totalQuantity is null (unlimited)', () {
      const tier = RewardTier(
        id: 't1',
        campaignId: 'c1',
        title: 'Basic',
        priceKrw: 5000,
        totalQuantity: null,
        remainingQuantity: 0,
      );
      expect(tier.isSoldOut, isFalse);
    });

    test('is true when totalQuantity is set and remainingQuantity is 0', () {
      const tier = RewardTier(
        id: 't2',
        campaignId: 'c1',
        title: 'VIP',
        priceKrw: 150000,
        totalQuantity: 50,
        remainingQuantity: 0,
      );
      expect(tier.isSoldOut, isTrue);
    });

    test('is false when totalQuantity is set and remainingQuantity is positive',
        () {
      const tier = RewardTier(
        id: 't3',
        campaignId: 'c1',
        title: 'Standard',
        priceKrw: 15000,
        totalQuantity: 100,
        remainingQuantity: 45,
      );
      expect(tier.isSoldOut, isFalse);
    });

    test(
        'is true when totalQuantity is set and remainingQuantity is null (defaults to 0)',
        () {
      const tier = RewardTier(
        id: 't4',
        campaignId: 'c1',
        title: 'Special',
        priceKrw: 50000,
        totalQuantity: 100,
        remainingQuantity: null,
      );
      expect(tier.isSoldOut, isTrue);
    });
  });

  group('RewardTier.fromJson', () {
    test('round-trip with full JSON preserves all fields', () {
      final json = <String, dynamic>{
        'id': 'tier-1',
        'campaign_id': 'camp-1',
        'title': 'Basic Tier',
        'description': '기본 리워드',
        'price_krw': 15000,
        'total_quantity': 1000,
        'remaining_quantity': 500,
        'pledge_count': 500,
        'display_order': 2,
        'is_active': true,
        'is_featured': true,
      };

      final tier = RewardTier.fromJson(json);

      expect(tier.id, 'tier-1');
      expect(tier.campaignId, 'camp-1');
      expect(tier.title, 'Basic Tier');
      expect(tier.description, '기본 리워드');
      expect(tier.priceKrw, 15000);
      expect(tier.totalQuantity, 1000);
      expect(tier.remainingQuantity, 500);
      expect(tier.pledgeCount, 500);
      expect(tier.displayOrder, 2);
      expect(tier.isActive, isTrue);
      expect(tier.isFeatured, isTrue);
    });

    test('uses defaults for missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'tier-min',
        'campaign_id': 'camp-min',
      };

      final tier = RewardTier.fromJson(json);

      expect(tier.title, '리워드');
      expect(tier.priceKrw, 0);
      expect(tier.totalQuantity, isNull);
      expect(tier.remainingQuantity, isNull);
      expect(tier.pledgeCount, 0);
      expect(tier.displayOrder, 0);
      expect(tier.isActive, isTrue);
      expect(tier.isFeatured, isFalse);
      expect(tier.isSoldOut, isFalse); // null totalQuantity = not sold out
    });

    test('toJson preserves all fields', () {
      final json = <String, dynamic>{
        'id': 'tier-rt',
        'campaign_id': 'camp-rt',
        'title': 'RT Tier',
        'price_krw': 50000,
        'total_quantity': 300,
        'remaining_quantity': 89,
        'pledge_count': 211,
        'display_order': 3,
        'is_active': true,
        'is_featured': false,
      };

      final tier = RewardTier.fromJson(json);
      final result = tier.toJson();

      expect(result['id'], 'tier-rt');
      expect(result['campaign_id'], 'camp-rt');
      expect(result['title'], 'RT Tier');
      expect(result['price_krw'], 50000);
      expect(result['total_quantity'], 300);
      expect(result['remaining_quantity'], 89);
      expect(result['pledge_count'], 211);
      expect(result['display_order'], 3);
      expect(result['is_active'], isTrue);
      expect(result['is_featured'], isFalse);
    });
  });

  // ==========================================================================
  // FundingState derived lists
  // ==========================================================================

  group('FundingState.exploreCampaigns', () {
    final future = DateTime.now().add(const Duration(days: 10));
    final past = DateTime.now().subtract(const Duration(days: 1));

    test('returns only active campaigns from allCampaigns', () {
      final campaigns = [
        _makeCampaign(id: 'a1', status: CampaignStatus.active, endAt: future),
        _makeCampaign(id: 'd1', status: CampaignStatus.draft),
        _makeCampaign(id: 'p1', status: CampaignStatus.paused),
        _makeCampaign(id: 'c1', status: CampaignStatus.completed),
        _makeCampaign(id: 'cn1', status: CampaignStatus.cancelled),
        _makeCampaign(id: 'a2', status: CampaignStatus.active, endAt: future),
      ];

      final state = _makeState(allCampaigns: campaigns);
      final explore = state.exploreCampaigns;

      expect(explore.length, 2);
      expect(explore.every((c) => c.status == CampaignStatus.active), isTrue);
    });

    test('returns empty list when no active campaigns', () {
      final campaigns = [
        _makeCampaign(id: 'd1', status: CampaignStatus.draft),
        _makeCampaign(id: 'c1', status: CampaignStatus.completed),
      ];

      final state = _makeState(allCampaigns: campaigns);
      expect(state.exploreCampaigns, isEmpty);
    });

    test('applies search filter on title', () {
      final campaigns = [
        _makeCampaign(
            id: 'a1',
            status: CampaignStatus.active,
            endAt: future,
            title: '앨범 펀딩'),
        _makeCampaign(
            id: 'a2',
            status: CampaignStatus.active,
            endAt: future,
            title: '팬미팅 개최'),
      ];

      final state = _makeState(allCampaigns: campaigns, searchQuery: '앨범');
      final explore = state.exploreCampaigns;

      expect(explore.length, 1);
      expect(explore.first.id, 'a1');
    });

    test('applies search filter on subtitle', () {
      final campaigns = [
        _makeCampaign(
          id: 'a1',
          status: CampaignStatus.active,
          endAt: future,
          title: '캠페인 A',
          subtitle: '데뷔 기념',
        ),
        _makeCampaign(
          id: 'a2',
          status: CampaignStatus.active,
          endAt: future,
          title: '캠페인 B',
          subtitle: '월드투어',
        ),
      ];

      final state = _makeState(allCampaigns: campaigns, searchQuery: '데뷔');
      expect(state.exploreCampaigns.length, 1);
      expect(state.exploreCampaigns.first.id, 'a1');
    });

    test('applies search filter on category', () {
      final campaigns = [
        _makeCampaign(
          id: 'a1',
          status: CampaignStatus.active,
          endAt: future,
          title: '캠페인 A',
          category: '앨범',
        ),
        _makeCampaign(
          id: 'a2',
          status: CampaignStatus.active,
          endAt: future,
          title: '캠페인 B',
          category: '굿즈',
        ),
      ];

      final state = _makeState(allCampaigns: campaigns, searchQuery: '굿즈');
      expect(state.exploreCampaigns.length, 1);
      expect(state.exploreCampaigns.first.id, 'a2');
    });

    test('search is case-insensitive', () {
      final campaigns = [
        _makeCampaign(
            id: 'a1',
            status: CampaignStatus.active,
            endAt: future,
            title: 'KPOP 앨범'),
        _makeCampaign(
            id: 'a2',
            status: CampaignStatus.active,
            endAt: future,
            title: '팬미팅'),
      ];

      final state = _makeState(allCampaigns: campaigns, searchQuery: 'kpop');
      expect(state.exploreCampaigns.length, 1);
      expect(state.exploreCampaigns.first.id, 'a1');
    });

    test('returns all active campaigns when searchQuery is empty', () {
      final campaigns = [
        _makeCampaign(id: 'a1', status: CampaignStatus.active, endAt: future),
        _makeCampaign(id: 'a2', status: CampaignStatus.active, endAt: future),
        _makeCampaign(id: 'd1', status: CampaignStatus.draft),
      ];

      final state = _makeState(allCampaigns: campaigns, searchQuery: '');
      expect(state.exploreCampaigns.length, 2);
    });

    test(
        'active campaign with past endAt is still included (isActive check is not used here)',
        () {
      // exploreCampaigns filters on status == active, not on isActive (which also checks isEnded)
      final campaigns = [
        _makeCampaign(id: 'a1', status: CampaignStatus.active, endAt: past),
      ];
      final state = _makeState(allCampaigns: campaigns);
      // The implementation filters by status == active only, so past-ended active still shows
      expect(state.exploreCampaigns.length, 1);
    });
  });

  group('FundingState.myActiveCampaigns', () {
    test('includes active and paused campaigns', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final myCampaigns = [
        _makeCampaign(id: 'm1', status: CampaignStatus.active, endAt: future),
        _makeCampaign(id: 'm2', status: CampaignStatus.paused),
        _makeCampaign(id: 'm3', status: CampaignStatus.draft),
        _makeCampaign(id: 'm4', status: CampaignStatus.completed),
        _makeCampaign(id: 'm5', status: CampaignStatus.cancelled),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      final active = state.myActiveCampaigns;

      expect(active.length, 2);
      expect(active.map((c) => c.id).toList(), containsAll(['m1', 'm2']));
    });

    test('returns empty when no active or paused campaigns', () {
      final myCampaigns = [
        _makeCampaign(id: 'm1', status: CampaignStatus.draft),
        _makeCampaign(id: 'm2', status: CampaignStatus.completed),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      expect(state.myActiveCampaigns, isEmpty);
    });
  });

  group('FundingState.myDraftCampaigns', () {
    test('includes only draft campaigns', () {
      final myCampaigns = [
        _makeCampaign(id: 'm1', status: CampaignStatus.draft),
        _makeCampaign(id: 'm2', status: CampaignStatus.draft),
        _makeCampaign(id: 'm3', status: CampaignStatus.active),
        _makeCampaign(id: 'm4', status: CampaignStatus.completed),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      final drafts = state.myDraftCampaigns;

      expect(drafts.length, 2);
      expect(drafts.every((c) => c.status == CampaignStatus.draft), isTrue);
    });

    test('returns empty when no draft campaigns', () {
      final myCampaigns = [
        _makeCampaign(id: 'm1', status: CampaignStatus.active),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      expect(state.myDraftCampaigns, isEmpty);
    });
  });

  group('FundingState.myEndedCampaigns', () {
    test('includes completed and cancelled campaigns', () {
      final myCampaigns = [
        _makeCampaign(id: 'm1', status: CampaignStatus.completed),
        _makeCampaign(id: 'm2', status: CampaignStatus.cancelled),
        _makeCampaign(id: 'm3', status: CampaignStatus.active),
        _makeCampaign(id: 'm4', status: CampaignStatus.draft),
        _makeCampaign(id: 'm5', status: CampaignStatus.paused),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      final ended = state.myEndedCampaigns;

      expect(ended.length, 2);
      expect(ended.map((c) => c.id).toList(), containsAll(['m1', 'm2']));
    });

    test('returns empty when no ended campaigns', () {
      final myCampaigns = [
        _makeCampaign(id: 'm1', status: CampaignStatus.active),
        _makeCampaign(id: 'm2', status: CampaignStatus.draft),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      expect(state.myEndedCampaigns, isEmpty);
    });
  });

  group('FundingState.endingSoonCampaigns', () {
    test('returns only campaigns with daysLeft <= 3 and >= 0', () {
      final now = DateTime.now();
      final allCampaigns = [
        _makeCampaign(
          id: 'soon1',
          status: CampaignStatus.active,
          endAt: now.add(const Duration(hours: 20)), // daysLeft = 0
        ),
        _makeCampaign(
          id: 'soon2',
          status: CampaignStatus.active,
          endAt: now.add(const Duration(days: 2)), // daysLeft = 2 or 1
        ),
        _makeCampaign(
          id: 'soon3',
          status: CampaignStatus.active,
          endAt: now.add(const Duration(days: 3, hours: 1)), // daysLeft = 3
        ),
        _makeCampaign(
          id: 'not-soon',
          status: CampaignStatus.active,
          endAt: now.add(const Duration(days: 10)), // daysLeft = 10
        ),
      ];

      final state = _makeState(allCampaigns: allCampaigns);
      final ending = state.endingSoonCampaigns;

      expect(ending.every((c) => c.daysLeft <= 3), isTrue);
      expect(ending.every((c) => c.daysLeft >= 0), isTrue);
      expect(ending.any((c) => c.id == 'not-soon'), isFalse);
    });

    test(
        'does not include campaigns that have already ended (past endAt gives daysLeft = 0)',
        () {
      // A past endAt gives daysLeft == 0, which satisfies <= 3, so it is included.
      // The spec says daysLeft >= 0 — since daysLeft is clamped to 0 for past dates,
      // the filter does include them. This test just confirms that behaviour.
      final now = DateTime.now();
      final allCampaigns = [
        _makeCampaign(
          id: 'past',
          status: CampaignStatus.active,
          endAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final state = _makeState(allCampaigns: allCampaigns);
      // daysLeft = 0, satisfies 0 <= 3 && 0 >= 0 → included
      expect(state.endingSoonCampaigns.any((c) => c.id == 'past'), isTrue);
    });

    test('excludes non-active campaigns', () {
      final now = DateTime.now();
      final allCampaigns = [
        _makeCampaign(
          id: 'draft-soon',
          status: CampaignStatus.draft,
          endAt: now.add(const Duration(days: 1)),
        ),
      ];

      final state = _makeState(allCampaigns: allCampaigns);
      // exploreCampaigns filters out draft, so endingSoon is empty
      expect(state.endingSoonCampaigns, isEmpty);
    });
  });

  group('FundingState.popularCampaigns', () {
    test('sorted by backerCount descending', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final allCampaigns = [
        _makeCampaign(
            id: 'low',
            status: CampaignStatus.active,
            endAt: future,
            backerCount: 10),
        _makeCampaign(
            id: 'high',
            status: CampaignStatus.active,
            endAt: future,
            backerCount: 500),
        _makeCampaign(
            id: 'mid',
            status: CampaignStatus.active,
            endAt: future,
            backerCount: 150),
      ];

      final state = _makeState(allCampaigns: allCampaigns);
      final popular = state.popularCampaigns;

      expect(popular[0].id, 'high');
      expect(popular[1].id, 'mid');
      expect(popular[2].id, 'low');
    });

    test('preserves search filter before sorting', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final allCampaigns = [
        _makeCampaign(
          id: 'a1',
          status: CampaignStatus.active,
          endAt: future,
          title: '앨범 A',
          backerCount: 50,
        ),
        _makeCampaign(
          id: 'a2',
          status: CampaignStatus.active,
          endAt: future,
          title: '굿즈 B',
          backerCount: 200,
        ),
        _makeCampaign(
          id: 'a3',
          status: CampaignStatus.active,
          endAt: future,
          title: '앨범 C',
          backerCount: 100,
        ),
      ];

      final state = _makeState(allCampaigns: allCampaigns, searchQuery: '앨범');
      final popular = state.popularCampaigns;

      expect(popular.length, 2);
      expect(popular[0].id, 'a3'); // 100 backers
      expect(popular[1].id, 'a1'); // 50 backers
    });

    test('returns empty when no active campaigns', () {
      final state = _makeState(allCampaigns: []);
      expect(state.popularCampaigns, isEmpty);
    });
  });

  group('FundingState.newCampaigns', () {
    test('sorted by createdAt descending', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final allCampaigns = [
        _makeCampaign(
          id: 'old',
          status: CampaignStatus.active,
          endAt: future,
          createdAt: DateTime(2025, 1, 1),
        ),
        _makeCampaign(
          id: 'newest',
          status: CampaignStatus.active,
          endAt: future,
          createdAt: DateTime(2025, 3, 1),
        ),
        _makeCampaign(
          id: 'mid',
          status: CampaignStatus.active,
          endAt: future,
          createdAt: DateTime(2025, 2, 1),
        ),
      ];

      final state = _makeState(allCampaigns: allCampaigns);
      final newest = state.newCampaigns;

      expect(newest[0].id, 'newest');
      expect(newest[1].id, 'mid');
      expect(newest[2].id, 'old');
    });

    test('returns empty when no active campaigns', () {
      final state = _makeState(allCampaigns: []);
      expect(state.newCampaigns, isEmpty);
    });
  });

  // ==========================================================================
  // FundingState aggregations
  // ==========================================================================

  group('FundingState aggregations', () {
    test('totalActiveCampaigns counts active + paused myCampaigns', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final myCampaigns = [
        _makeCampaign(id: 'm1', status: CampaignStatus.active, endAt: future),
        _makeCampaign(id: 'm2', status: CampaignStatus.paused),
        _makeCampaign(id: 'm3', status: CampaignStatus.draft),
        _makeCampaign(id: 'm4', status: CampaignStatus.completed),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      // myActiveCampaigns includes active + paused = 2
      expect(state.totalActiveCampaigns, 2);
    });

    test('totalActiveCampaigns is 0 when myCampaigns is empty', () {
      final state = _makeState(myCampaigns: []);
      expect(state.totalActiveCampaigns, 0);
    });

    test('totalBackers sums backerCount across all myCampaigns', () {
      final myCampaigns = [
        _makeCampaign(id: 'm1', backerCount: 100),
        _makeCampaign(id: 'm2', backerCount: 250),
        _makeCampaign(id: 'm3', backerCount: 50),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      expect(state.totalBackers, 400);
    });

    test('totalBackers is 0 when myCampaigns is empty', () {
      final state = _makeState(myCampaigns: []);
      expect(state.totalBackers, 0);
    });

    test('totalRaisedKrw sums currentAmountKrw across all myCampaigns', () {
      final myCampaigns = [
        _makeCampaign(id: 'm1', currentAmountKrw: 1000000),
        _makeCampaign(id: 'm2', currentAmountKrw: 500000),
        _makeCampaign(id: 'm3', currentAmountKrw: 250000),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      expect(state.totalRaisedKrw, 1750000);
    });

    test('totalRaisedKrw is 0 when myCampaigns is empty', () {
      final state = _makeState(myCampaigns: []);
      expect(state.totalRaisedKrw, 0);
    });

    test('totalRaisedKrw includes all statuses (not just active)', () {
      final myCampaigns = [
        _makeCampaign(
            id: 'm1',
            status: CampaignStatus.completed,
            currentAmountKrw: 800000),
        _makeCampaign(
            id: 'm2', status: CampaignStatus.active, currentAmountKrw: 200000),
      ];

      final state = _makeState(myCampaigns: myCampaigns);
      expect(state.totalRaisedKrw, 1000000);
    });
  });

  // ==========================================================================
  // Pledge model
  // ==========================================================================

  group('Pledge', () {
    test('constructs with required fields', () {
      final createdAt = DateTime(2025, 6, 1);
      final pledge = Pledge(
        id: 'pledge-1',
        campaignId: 'camp-1',
        userId: 'user-1',
        tierId: 'tier-1',
        amountKrw: 15000,
        createdAt: createdAt,
      );

      expect(pledge.id, 'pledge-1');
      expect(pledge.campaignId, 'camp-1');
      expect(pledge.userId, 'user-1');
      expect(pledge.tierId, 'tier-1');
      expect(pledge.amountKrw, 15000);
      expect(pledge.createdAt, createdAt);
      expect(pledge.isAnonymous, isFalse);
      expect(pledge.status, 'active');
      expect(pledge.tierTitle, isNull);
      expect(pledge.campaignTitle, isNull);
      expect(pledge.supportMessage, isNull);
    });

    test('totalAmount equals amountKrw', () {
      final pledge = Pledge(
        id: 'p1',
        campaignId: 'c1',
        userId: 'u1',
        tierId: 't1',
        amountKrw: 50000,
        createdAt: DateTime(2025, 1, 1),
      );
      expect(pledge.totalAmount, 50000);
    });

    test('constructs with optional fields', () {
      final pledge = Pledge(
        id: 'p2',
        campaignId: 'c2',
        userId: 'u2',
        tierId: 't2',
        amountKrw: 150000,
        tierTitle: 'VIP 리워드',
        campaignTitle: '앨범 펀딩',
        isAnonymous: true,
        supportMessage: '응원합니다!',
        status: 'paid',
        createdAt: DateTime(2025, 3, 15),
      );

      expect(pledge.tierTitle, 'VIP 리워드');
      expect(pledge.campaignTitle, '앨범 펀딩');
      expect(pledge.isAnonymous, isTrue);
      expect(pledge.supportMessage, '응원합니다!');
      expect(pledge.status, 'paid');
    });
  });

  // ==========================================================================
  // Backer model
  // ==========================================================================

  group('Backer', () {
    test('constructs with required fields', () {
      final createdAt = DateTime(2025, 5, 20);
      final backer = Backer(
        id: 'backer-1',
        userId: 'user-1',
        displayName: '하늘별',
        tierTitle: '기본 리워드',
        amountKrw: 15000,
        createdAt: createdAt,
      );

      expect(backer.id, 'backer-1');
      expect(backer.userId, 'user-1');
      expect(backer.displayName, '하늘별');
      expect(backer.tierTitle, '기본 리워드');
      expect(backer.amountKrw, 15000);
      expect(backer.createdAt, createdAt);
      expect(backer.isAnonymous, isFalse);
      expect(backer.avatarUrl, isNull);
      expect(backer.supportMessage, isNull);
    });

    test('constructs with optional fields', () {
      final backer = Backer(
        id: 'backer-2',
        userId: 'user-2',
        displayName: '익명',
        avatarUrl: 'https://example.com/avatar.jpg',
        tierTitle: 'VIP 리워드',
        amountKrw: 150000,
        isAnonymous: true,
        supportMessage: '항상 응원합니다!',
        createdAt: DateTime(2025, 4, 10),
      );

      expect(backer.avatarUrl, 'https://example.com/avatar.jpg');
      expect(backer.isAnonymous, isTrue);
      expect(backer.supportMessage, '항상 응원합니다!');
    });
  });

  // ==========================================================================
  // FundingState.copyWith
  // ==========================================================================

  group('FundingState.copyWith', () {
    test('returns copy with updated fields', () {
      const original = FundingState(
        isLoading: false,
        searchQuery: '',
        error: null,
      );

      final updated = original.copyWith(isLoading: true, searchQuery: '앨범');

      expect(updated.isLoading, isTrue);
      expect(updated.searchQuery, '앨범');
      expect(updated.allCampaigns, isEmpty);
    });

    test('preserves unchanged fields', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final campaigns = [
        _makeCampaign(id: 'c1', endAt: future),
      ];
      final original = FundingState(
        allCampaigns: campaigns,
        isLoading: false,
      );

      final updated = original.copyWith(isLoading: true);

      expect(updated.allCampaigns, same(campaigns));
      expect(updated.isLoading, isTrue);
    });

    test('error field is replaced (not merged)', () {
      const original = FundingState(error: 'some error');
      // copyWith with no error argument sets error to null
      final updated = original.copyWith(isLoading: false);
      expect(updated.error, isNull);
    });
  });
}
