import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/daily_question_set.dart';
import '../data/repositories/question_cards_repository.dart';
import 'auth_provider.dart';

/// Provider for question cards repository
/// Uses isDemoModeProvider to determine mock vs real implementation
final questionCardsRepositoryProvider = Provider<IQuestionCardsRepository>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  if (isDemoMode) {
    return MockQuestionCardsRepository();
  }
  try {
    return SupabaseQuestionCardsRepository(Supabase.instance.client);
  } catch (_) {
    // Fallback to mock if Supabase is not initialized
    return MockQuestionCardsRepository();
  }
});

/// State for daily question set
sealed class DailyQuestionSetState {}

class DailyQuestionSetInitial extends DailyQuestionSetState {}

class DailyQuestionSetLoading extends DailyQuestionSetState {}

class DailyQuestionSetLoaded extends DailyQuestionSetState {
  final DailyQuestionSet set;
  DailyQuestionSetLoaded(this.set);
}

class DailyQuestionSetError extends DailyQuestionSetState {
  final String message;
  DailyQuestionSetError(this.message);
}

class DailyQuestionSetVoting extends DailyQuestionSetState {
  final DailyQuestionSet set;
  final String votingCardId;
  DailyQuestionSetVoting(this.set, this.votingCardId);
}

/// Notifier for daily question set
class DailyQuestionSetNotifier extends StateNotifier<DailyQuestionSetState> {
  final IQuestionCardsRepository _repository;
  final String channelId;

  DailyQuestionSetNotifier(this._repository, this.channelId)
      : super(DailyQuestionSetInitial());

  /// Load or create today's question set
  Future<void> load() async {
    if (state is DailyQuestionSetLoading) return; // Prevent double loading
    state = DailyQuestionSetLoading();

    try {
      final set = await _repository.getOrCreateDailySet(channelId);
      state = DailyQuestionSetLoaded(set);
    } catch (e) {
      debugPrint('[QuestionSet] Error loading for $channelId: $e');
      state = DailyQuestionSetError(e.toString());
    }
  }

  /// Vote for a card
  Future<bool> vote(String cardId) async {
    final currentState = state;
    if (currentState is! DailyQuestionSetLoaded) return false;

    // Already voted
    if (currentState.set.hasVoted) return false;

    // Show voting state
    state = DailyQuestionSetVoting(currentState.set, cardId);

    try {
      final response = await _repository.vote(currentState.set.setId, cardId);

      if (!response.success) {
        // Restore previous state
        state = DailyQuestionSetLoaded(currentState.set);
        return false;
      }

      // Update with new vote counts
      final updatedSet = currentState.set.updateVoteCounts(
        response.voteCounts,
        response.userVote,
        response.totalVotes,
      );

      state = DailyQuestionSetLoaded(updatedSet);
      return true;
    } catch (e) {
      // Restore previous state
      state = DailyQuestionSetLoaded(currentState.set);
      return false;
    }
  }

  /// Refresh the current set
  Future<void> refresh() async {
    await load();
  }

  /// Get current set if loaded
  DailyQuestionSet? get currentSet {
    final currentState = state;
    if (currentState is DailyQuestionSetLoaded) {
      return currentState.set;
    }
    if (currentState is DailyQuestionSetVoting) {
      return currentState.set;
    }
    return null;
  }
}

/// Provider for daily question set (per channel)
final dailyQuestionSetProvider = StateNotifierProvider.family<
    DailyQuestionSetNotifier, DailyQuestionSetState, String>(
  (ref, channelId) {
    final repository = ref.watch(questionCardsRepositoryProvider);
    return DailyQuestionSetNotifier(repository, channelId);
  },
);

/// State for creator's today question stats
sealed class TodaysQuestionStatsState {}

class TodaysQuestionStatsInitial extends TodaysQuestionStatsState {}

class TodaysQuestionStatsLoading extends TodaysQuestionStatsState {}

class TodaysQuestionStatsLoaded extends TodaysQuestionStatsState {
  final TodaysQuestionStats stats;
  TodaysQuestionStatsLoaded(this.stats);
}

class TodaysQuestionStatsError extends TodaysQuestionStatsState {
  final String message;
  TodaysQuestionStatsError(this.message);
}

/// Notifier for creator's today question stats
class TodaysQuestionStatsNotifier extends StateNotifier<TodaysQuestionStatsState> {
  final IQuestionCardsRepository _repository;
  final String channelId;

  TodaysQuestionStatsNotifier(this._repository, this.channelId)
      : super(TodaysQuestionStatsInitial());

  /// Load today's stats
  Future<void> load() async {
    state = TodaysQuestionStatsLoading();

    try {
      final stats = await _repository.getTodaysStats(channelId);
      state = TodaysQuestionStatsLoaded(stats);
    } catch (e) {
      state = TodaysQuestionStatsError(e.toString());
    }
  }

  /// Mark a question as answered
  Future<bool> markAnswered(String cardId, String messageId, {String? setId}) async {
    try {
      final success = await _repository.markAnswered(
        channelId: channelId,
        cardId: cardId,
        messageId: messageId,
        setId: setId,
      );

      if (success) {
        // Refresh stats
        await load();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Refresh stats
  Future<void> refresh() async {
    await load();
  }
}

/// Provider for creator's today question stats (per channel)
final todaysQuestionStatsProvider = StateNotifierProvider.family<
    TodaysQuestionStatsNotifier, TodaysQuestionStatsState, String>(
  (ref, channelId) {
    final repository = ref.watch(questionCardsRepositoryProvider);
    return TodaysQuestionStatsNotifier(repository, channelId);
  },
);

/// Provider for available question decks
final questionDecksProvider = FutureProvider<List<QuestionDeck>>((ref) async {
  final repository = ref.watch(questionCardsRepositoryProvider);
  return repository.getDecks();
});
