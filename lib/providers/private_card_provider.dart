import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/demo_config.dart';
import '../core/utils/app_logger.dart';
import '../data/models/fan_filter.dart';
import '../data/models/private_card.dart';
import 'auth_provider.dart';

/// State for the private card compose flow
class PrivateCardComposeState {
  final int currentStep; // 0, 1, 2
  final String cardText;
  final String? selectedTemplateId;
  final String? selectedTemplateImageUrl;
  final List<String> attachedMediaUrls;
  final FanFilterType? selectedFilter;
  final List<FanSummary> matchedFans;
  final Set<String> selectedFanIds;
  final List<FanSummary> favoriteFans;
  final bool isLoading;
  final bool isSending;
  final bool isSent;
  final String? error;

  const PrivateCardComposeState({
    this.currentStep = 0,
    this.cardText = '',
    this.selectedTemplateId,
    this.selectedTemplateImageUrl,
    this.attachedMediaUrls = const [],
    this.selectedFilter,
    this.matchedFans = const [],
    this.selectedFanIds = const {},
    this.favoriteFans = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isSent = false,
    this.error,
  });

  PrivateCardComposeState copyWith({
    int? currentStep,
    String? cardText,
    String? selectedTemplateId,
    String? selectedTemplateImageUrl,
    List<String>? attachedMediaUrls,
    FanFilterType? selectedFilter,
    List<FanSummary>? matchedFans,
    Set<String>? selectedFanIds,
    List<FanSummary>? favoriteFans,
    bool? isLoading,
    bool? isSending,
    bool? isSent,
    String? error,
  }) {
    return PrivateCardComposeState(
      currentStep: currentStep ?? this.currentStep,
      cardText: cardText ?? this.cardText,
      selectedTemplateId: selectedTemplateId ?? this.selectedTemplateId,
      selectedTemplateImageUrl:
          selectedTemplateImageUrl ?? this.selectedTemplateImageUrl,
      attachedMediaUrls: attachedMediaUrls ?? this.attachedMediaUrls,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      matchedFans: matchedFans ?? this.matchedFans,
      selectedFanIds: selectedFanIds ?? this.selectedFanIds,
      favoriteFans: favoriteFans ?? this.favoriteFans,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isSent: isSent ?? this.isSent,
      error: error,
    );
  }

  /// Whether step 1 (card editor) is valid
  bool get isStep1Valid =>
      selectedTemplateId != null && cardText.trim().isNotEmpty;

  /// Whether step 2 (fan selection) is valid
  bool get isStep2Valid => selectedFanIds.isNotEmpty;

  /// Total selected fan count
  int get selectedFanCount => selectedFanIds.length;
}

/// State for sent card history
class PrivateCardHistoryState {
  final List<PrivateCard> sentCards;
  final bool isLoading;
  final String? error;

  const PrivateCardHistoryState({
    this.sentCards = const [],
    this.isLoading = false,
    this.error,
  });

  PrivateCardHistoryState copyWith({
    List<PrivateCard>? sentCards,
    bool? isLoading,
    String? error,
  }) {
    return PrivateCardHistoryState(
      sentCards: sentCards ?? this.sentCards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for private card compose flow
class PrivateCardComposeNotifier
    extends StateNotifier<PrivateCardComposeState> {
  final Ref _ref;

  PrivateCardComposeNotifier(this._ref)
      : super(const PrivateCardComposeState()) {
    _loadFavorites();
  }

  // ============================================================
  // Step Navigation
  // ============================================================

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Reset compose state for a fresh start
  void resetState() {
    state = const PrivateCardComposeState();
    _loadFavorites();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  // ============================================================
  // Step 1: Card Editor
  // ============================================================

  void updateCardText(String text) {
    state = state.copyWith(cardText: text);
  }

  void selectTemplate(String templateId, String imageUrl) {
    state = state.copyWith(
      selectedTemplateId: templateId,
      selectedTemplateImageUrl: imageUrl,
    );
  }

  void addMedia(String url) {
    final urls = List<String>.from(state.attachedMediaUrls)..add(url);
    state = state.copyWith(attachedMediaUrls: urls);
  }

  void removeMedia(int index) {
    final urls = List<String>.from(state.attachedMediaUrls)..removeAt(index);
    state = state.copyWith(attachedMediaUrls: urls);
  }

  // ============================================================
  // Step 2: Fan Selection
  // ============================================================

  void selectFilter(FanFilterType filter) {
    state = state.copyWith(
      selectedFilter: filter,
      isLoading: true,
    );
    _loadFansForFilter(filter);
  }

  void clearFilter() {
    state = state.copyWith(
      selectedFilter: null,
      matchedFans: [],
      selectedFanIds: {},
    );
  }

  void toggleFanSelection(String userId) {
    final ids = Set<String>.from(state.selectedFanIds);
    if (ids.contains(userId)) {
      ids.remove(userId);
    } else {
      ids.add(userId);
    }
    state = state.copyWith(selectedFanIds: ids);
  }

  void selectAllMatchedFans() {
    final ids = state.matchedFans.map((f) => f.userId).toSet();
    state = state.copyWith(selectedFanIds: ids);
  }

  void deselectAllFans() {
    state = state.copyWith(selectedFanIds: {});
  }

  void toggleFavorite(String userId) {
    final authState = _ref.read(authProvider);
    final isDemoMode = authState is AuthDemoMode;

    // 로컬 UI 즉시 업데이트
    _toggleDemoFavorite(userId);

    if (!isDemoMode) {
      // Supabase에 즐겨찾기 상태 동기화
      _syncFavoriteToSupabase(userId);
    }
  }

  Future<void> _syncFavoriteToSupabase(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final isFavorite = state.matchedFans
              .where((f) => f.userId == userId)
              .firstOrNull
              ?.isFavorite ??
          false;

      if (isFavorite) {
        await supabase.from('fan_favorites').upsert({
          'creator_id': currentUserId,
          'fan_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await supabase
            .from('fan_favorites')
            .delete()
            .eq('creator_id', currentUserId)
            .eq('fan_id', userId);
      }
    } catch (e) {
      AppLogger.error(e, tag: 'PrivateCard', message: 'Favorite sync failed');
    }
  }

  // ============================================================
  // Step 3: Send Card
  // ============================================================

  Future<void> sendCard() async {
    if (!state.isStep1Valid || !state.isStep2Valid) return;

    state = state.copyWith(isSending: true, error: null);

    try {
      final authState = _ref.read(authProvider);
      if (authState is AuthDemoMode) {
        await _sendDemoCard();
      } else {
        await _sendSupabaseCard();
      }

      state = state.copyWith(isSending: false, isSent: true);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: '카드 전송에 실패했습니다: $e',
      );
    }
  }

  // ============================================================
  // Demo Mode Methods
  // ============================================================

  void _loadFavorites() {
    final fans = _getDemoFanList();
    final favorites = fans.where((f) => f.isFavorite).toList();
    state = state.copyWith(favoriteFans: favorites);
  }

  void _loadFansForFilter(FanFilterType filter) {
    final allFans = _getDemoFanList();
    List<FanSummary> filtered;

    switch (filter) {
      case FanFilterType.allFans:
        filtered = allFans;
        break;
      case FanFilterType.birthdayToday:
        // Demo: show 2 random fans as birthday
        filtered = allFans.take(2).toList();
        break;
      case FanFilterType.topDonors30Days:
        filtered = List<FanSummary>.from(allFans)
          ..sort(
              (a, b) => (b.totalDonation ?? 0).compareTo(a.totalDonation ?? 0));
        filtered = filtered.take(5).toList();
        break;
      case FanFilterType.topRepliers30Days:
        filtered = List<FanSummary>.from(allFans)
          ..sort((a, b) => (b.replyCount ?? 0).compareTo(a.replyCount ?? 0));
        filtered = filtered.take(5).toList();
        break;
      case FanFilterType.questionParticipants:
        // Demo: show fans with 50+ replies
        filtered = allFans.where((f) => (f.replyCount ?? 0) > 50).toList();
        break;
      case FanFilterType.hundredDayMembers:
        filtered = allFans
            .where((f) => f.daysSubscribed >= 95 && f.daysSubscribed <= 105)
            .toList();
        // If none match exactly, show fans near 100 days
        if (filtered.isEmpty) {
          filtered = allFans
              .where((f) => f.daysSubscribed >= 90 && f.daysSubscribed <= 110)
              .toList();
        }
        break;
      case FanFilterType.vipSubscribers:
        filtered = allFans.where((f) => f.tier == 'VIP').toList();
        break;
      case FanFilterType.longTermSub12m:
        filtered = allFans.where((f) => f.daysSubscribed >= 365).toList();
        break;
      case FanFilterType.longTermSub24m:
        filtered = allFans.where((f) => f.daysSubscribed >= 730).toList();
        break;
      case FanFilterType.favorites:
        filtered = allFans.where((f) => f.isFavorite).toList();
        break;
    }

    // Auto-select all matched fans
    final selectedIds = filtered.map((f) => f.userId).toSet();

    state = state.copyWith(
      matchedFans: filtered,
      selectedFanIds: selectedIds,
      isLoading: false,
    );
  }

  void _toggleDemoFavorite(String userId) {
    // Toggle in matched fans
    final matchedFans = state.matchedFans.map((f) {
      if (f.userId == userId) {
        return f.copyWith(isFavorite: !f.isFavorite);
      }
      return f;
    }).toList();

    // Recalculate all favorites from both matched and unmatched fans
    final allFans = _getDemoFanList();
    final updatedFavorites = <FanSummary>[];

    for (final fan in allFans) {
      final matchedVersion =
          matchedFans.where((m) => m.userId == fan.userId).firstOrNull;
      if (matchedVersion != null) {
        if (matchedVersion.isFavorite) updatedFavorites.add(matchedVersion);
      } else {
        if (fan.isFavorite) updatedFavorites.add(fan);
      }
    }

    state = state.copyWith(
      matchedFans: matchedFans,
      favoriteFans: updatedFavorites,
    );
  }

  Future<void> _sendDemoCard() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    AppLogger.debug('Demo: Private card sent to ${state.selectedFanCount} fans', tag: 'PrivateCard');
  }

  Future<void> _sendSupabaseCard() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('인증이 필요합니다');

    final response = await supabase.functions.invoke(
      'send-private-card',
      body: {
        'creatorId': userId,
        'templateId': state.selectedTemplateId,
        'cardText': state.cardText,
        'attachedMediaUrls': state.attachedMediaUrls,
        'recipientIds': state.selectedFanIds.toList(),
        'filterUsed': state.selectedFilter?.name,
      },
    );

    final data = response.data as Map<String, dynamic>?;
    if (data?['success'] != true) {
      throw Exception(data?['message'] ?? '카드 전송에 실패했습니다');
    }
  }

  List<FanSummary> _getDemoFanList() {
    return DemoConfig.demoFans.map((data) {
      return FanSummary(
        userId: data['id'] as String,
        displayName: data['name'] as String,
        avatarUrl: DemoConfig.avatarUrl(data['seed'] as String),
        tier: data['tier'] as String,
        daysSubscribed: data['days'] as int,
        isFavorite: data['isFavorite'] as bool,
        totalDonation: data['donation'] as int?,
        replyCount: data['replies'] as int?,
      );
    }).toList();
  }
}

/// Notifier for sent card history
class PrivateCardHistoryNotifier
    extends StateNotifier<PrivateCardHistoryState> {
  final Ref _ref;

  PrivateCardHistoryNotifier(this._ref)
      : super(const PrivateCardHistoryState()) {
    _loadHistory();
  }

  void _loadHistory() {
    state = state.copyWith(isLoading: true);

    final authState = _ref.read(authProvider);
    if (authState is AuthDemoMode) {
      _loadDemoHistory();
    } else {
      _loadSupabaseHistory();
    }
  }

  Future<void> _loadSupabaseHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('private_cards')
          .select()
          .eq('artist_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final cards = (response as List).map((data) {
        return PrivateCard(
          id: data['id'] as String,
          channelId: data['channel_id'] as String,
          artistId: data['artist_id'] as String,
          templateContent: data['template_content'] as String? ?? '',
          cardTemplateId: (data['card_template_id'] as String?) ?? '',
          cardImageUrl: data['card_image_url'] as String?,
          recipientCount: data['recipient_count'] as int? ?? 0,
          filterUsed: (data['filter_used'] as String?) ?? '',
          status: PrivateCardStatus.values.firstWhere(
            (s) => s.name == (data['status'] as String? ?? 'sent'),
            orElse: () => PrivateCardStatus.sent,
          ),
          createdAt: DateTime.parse(data['created_at'] as String),
          sentAt: data['sent_at'] != null
              ? DateTime.parse(data['sent_at'] as String)
              : null,
        );
      }).toList();

      state = state.copyWith(sentCards: cards, isLoading: false);
    } catch (e) {
      AppLogger.error(e, tag: 'PrivateCard', message: 'Load private card history failed');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _loadDemoHistory() {
    final now = DateTime.now();
    final demoCards = [
      PrivateCard(
        id: 'card_001',
        channelId: DemoConfig.demoChannelId,
        artistId: DemoConfig.demoCreatorId,
        templateContent: '{fanName}님, 항상 응원해주셔서 감사합니다! 덕분에 오늘도 힘내고 있어요 💕',
        cardTemplateId: 'template_hearts',
        cardImageUrl: DemoConfig.cardTemplateUrl('card-hearts'),
        recipientCount: 5,
        filterUsed: 'topDonors30Days',
        status: PrivateCardStatus.sent,
        createdAt: now.subtract(const Duration(days: 3)),
        sentAt: now.subtract(const Duration(days: 3)),
      ),
      PrivateCard(
        id: 'card_002',
        channelId: DemoConfig.demoChannelId,
        artistId: DemoConfig.demoCreatorId,
        templateContent: '{fanName}님, 생일 진심으로 축하합니다! 오늘 하루도 행복하게 보내세요 🎂',
        cardTemplateId: 'template_birthday',
        cardImageUrl: DemoConfig.cardTemplateUrl('card-birthday'),
        recipientCount: 2,
        filterUsed: 'birthdayToday',
        status: PrivateCardStatus.sent,
        createdAt: now.subtract(const Duration(days: 7)),
        sentAt: now.subtract(const Duration(days: 7)),
      ),
    ];

    state = state.copyWith(
      sentCards: demoCards,
      isLoading: false,
    );
  }

  void addSentCard(PrivateCard card) {
    state = state.copyWith(
      sentCards: [card, ...state.sentCards],
    );
  }
}

// ============================================================
// Providers
// ============================================================

final privateCardComposeProvider = StateNotifierProvider.autoDispose<
    PrivateCardComposeNotifier, PrivateCardComposeState>(
  (ref) => PrivateCardComposeNotifier(ref),
);

final privateCardHistoryProvider =
    StateNotifierProvider<PrivateCardHistoryNotifier, PrivateCardHistoryState>(
  (ref) => PrivateCardHistoryNotifier(ref),
);

/// Provider for card templates
final cardTemplatesProvider = Provider<List<PrivateCardTemplate>>((ref) {
  return DemoConfig.demoCardTemplates.map((data) {
    return PrivateCardTemplate(
      id: data['id']!,
      name: data['name']!,
      category: data['category']!,
      thumbnailUrl:
          DemoConfig.cardTemplateUrl(data['seed']!, width: 200, height: 300),
      fullImageUrl: DemoConfig.cardTemplateUrl(data['seed']!),
    );
  }).toList();
});
