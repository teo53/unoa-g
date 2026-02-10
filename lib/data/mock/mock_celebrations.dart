import '../models/celebration_event.dart';
import '../models/celebration_template.dart';
import '../models/fan_celebration.dart';

/// Mock celebration data for demo mode.
class MockCelebrations {
  MockCelebrations._();

  /// Sample fan celebrations (registered birthdays).
  static List<FanCelebration> get sampleFanCelebrations => [
        FanCelebration(
          id: 'fc_1',
          userId: 'fan_001',
          channelId: 'demo_channel_001',
          birthMonth: DateTime.now().month,
          birthDay: DateTime.now().day,
          birthdayVisible: true,
          visibilityConsentAt:
              DateTime.now().subtract(const Duration(days: 30)),
          subscriptionStartedAt:
              DateTime.now().subtract(const Duration(days: 100)),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
        FanCelebration(
          id: 'fc_2',
          userId: 'fan_002',
          channelId: 'demo_channel_001',
          birthMonth: DateTime.now().month,
          birthDay: DateTime.now().day,
          birthdayVisible: true,
          visibilityConsentAt:
              DateTime.now().subtract(const Duration(days: 60)),
          subscriptionStartedAt:
              DateTime.now().subtract(const Duration(days: 50)),
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now(),
        ),
      ];

  /// Sample celebration events for today.
  static List<CelebrationEvent> get todayEvents => [
        CelebrationEvent(
          id: 'evt_1',
          channelId: 'demo_channel_001',
          fanCelebrationId: 'fc_1',
          eventType: 'birthday',
          dueDate: DateTime.now(),
          status: 'pending',
          payload: const CelebrationPayload(
            nickname: '별빛소녀',
            userId: 'fan_001',
            tier: 'VIP',
          ),
          createdAt: DateTime.now(),
        ),
        CelebrationEvent(
          id: 'evt_2',
          channelId: 'demo_channel_001',
          fanCelebrationId: 'fc_2',
          eventType: 'milestone_50',
          dueDate: DateTime.now(),
          status: 'pending',
          payload: const CelebrationPayload(
            nickname: '달콤한하루',
            userId: 'fan_002',
            dayCount: 50,
            tier: 'STANDARD',
          ),
          createdAt: DateTime.now(),
        ),
        CelebrationEvent(
          id: 'evt_3',
          channelId: 'demo_channel_001',
          fanCelebrationId: 'fc_1',
          eventType: 'milestone_100',
          dueDate: DateTime.now(),
          status: 'pending',
          payload: const CelebrationPayload(
            nickname: '별빛소녀',
            userId: 'fan_001',
            dayCount: 100,
            tier: 'VIP',
          ),
          createdAt: DateTime.now(),
        ),
      ];

  /// System default templates.
  static List<CelebrationTemplate> get defaultTemplates => [
        CelebrationTemplate(
          id: 'tpl_1',
          eventType: 'birthday',
          templateText: '{nickname}님, 생일 축하해요! 🎂🎉 오늘 하루 행복하게 보내세요~',
          isDefault: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
        CelebrationTemplate(
          id: 'tpl_2',
          eventType: 'birthday',
          templateText: '생일 축하합니다 {nickname}! 🥳 항상 응원해줘서 고마워요 💕',
          isDefault: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),
        CelebrationTemplate(
          id: 'tpl_3',
          eventType: 'birthday',
          templateText: '{nickname}님~ 해피 버스데이! 🎁 앞으로도 함께해요!',
          isDefault: true,
          sortOrder: 3,
          createdAt: DateTime.now(),
        ),
        CelebrationTemplate(
          id: 'tpl_4',
          eventType: 'milestone_50',
          templateText: '{nickname}님, 벌써 {day_count}일! 함께해줘서 감사해요 💝',
          isDefault: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
        CelebrationTemplate(
          id: 'tpl_5',
          eventType: 'milestone_50',
          templateText: '{day_count}일째 함께하고 있어요 {nickname}! 앞으로도 잘 부탁해요 🙏',
          isDefault: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),
        CelebrationTemplate(
          id: 'tpl_6',
          eventType: 'milestone_100',
          templateText: '{nickname}님과 함께한 {day_count}일 🎊 100일 축하해요!',
          isDefault: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
        CelebrationTemplate(
          id: 'tpl_7',
          eventType: 'milestone_100',
          templateText:
              '100일이라니! {nickname}님 정말 감사해요 💖 {artist_name}이/가 항상 곁에 있을게요!',
          isDefault: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),
        CelebrationTemplate(
          id: 'tpl_8',
          eventType: 'milestone_365',
          templateText: '{nickname}님, 1년이나 함께해주셨어요! 🥰 정말 감사합니다!',
          isDefault: true,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
        CelebrationTemplate(
          id: 'tpl_9',
          eventType: 'milestone_365',
          templateText:
              '365일! {nickname}님과 함께한 1년은 정말 특별했어요 🌟 {artist_name} 드림 💕',
          isDefault: true,
          sortOrder: 2,
          createdAt: DateTime.now(),
        ),
      ];

  /// Get templates filtered by event type.
  static List<CelebrationTemplate> templatesForType(String eventType) {
    return defaultTemplates.where((t) => t.eventType == eventType).toList();
  }
}
