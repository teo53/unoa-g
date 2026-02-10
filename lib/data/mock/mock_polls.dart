import '../models/poll_draft.dart';

/// Mock poll data for demo mode.
class MockPolls {
  MockPolls._();

  static List<PollDraft> get sampleDrafts => [
        PollDraft(
          id: 'draft_1',
          channelId: 'demo_channel_001',
          category: 'preference_vs',
          question: '여름 vs 겨울 어느 쪽이 더 좋아요?',
          options: const [
            PollOption(id: 'opt_a', text: '여름! ☀️'),
            PollOption(id: 'opt_b', text: '겨울! ❄️'),
          ],
          createdAt: DateTime.now(),
        ),
        PollDraft(
          id: 'draft_2',
          channelId: 'demo_channel_001',
          category: 'content_choice',
          question: '다음 커버곡 뭐가 좋을까요?',
          options: const [
            PollOption(id: 'opt_a', text: '발라드 🎤'),
            PollOption(id: 'opt_b', text: '댄스곡 💃'),
            PollOption(id: 'opt_c', text: '어쿠스틱 🎸'),
          ],
          createdAt: DateTime.now(),
        ),
        PollDraft(
          id: 'draft_3',
          channelId: 'demo_channel_001',
          category: 'light_tmi',
          question: '오늘 아침에 뭐 먹었게요? 맞춰보세요!',
          options: const [
            PollOption(id: 'opt_a', text: '빵 🍞'),
            PollOption(id: 'opt_b', text: '밥 🍚'),
            PollOption(id: 'opt_c', text: '안 먹었어 😅'),
            PollOption(id: 'opt_d', text: '시리얼 🥣'),
          ],
          createdAt: DateTime.now(),
        ),
        PollDraft(
          id: 'draft_4',
          channelId: 'demo_channel_001',
          category: 'schedule_choice',
          question: '라이브 방송 어느 시간대가 좋아요?',
          options: const [
            PollOption(id: 'opt_a', text: '오후 2시 ☀️'),
            PollOption(id: 'opt_b', text: '저녁 8시 🌙'),
            PollOption(id: 'opt_c', text: '밤 11시 ✨'),
          ],
          createdAt: DateTime.now(),
        ),
        PollDraft(
          id: 'draft_5',
          channelId: 'demo_channel_001',
          category: 'mini_mission',
          question: '오늘의 미션! 하나 골라주세요~',
          options: const [
            PollOption(id: 'opt_a', text: '셀카 찍기 📸'),
            PollOption(id: 'opt_b', text: '좋아하는 노래 1절 부르기 🎵'),
          ],
          createdAt: DateTime.now(),
        ),
      ];
}
