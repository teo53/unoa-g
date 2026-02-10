import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/demo_config.dart';
import '../services/realtime_service.dart';
import 'auth_provider.dart';

/// Realtime connection state
sealed class RealtimeState {
  const RealtimeState();
}

/// Initial state before any connection
class RealtimeInitial extends RealtimeState {
  const RealtimeInitial();
}

/// Connecting to realtime channels
class RealtimeConnecting extends RealtimeState {
  const RealtimeConnecting();
}

/// Successfully connected to realtime channels
class RealtimeConnected extends RealtimeState {
  final Set<String> subscribedChannels;
  final Map<String, Map<String, bool>> onlineUsers; // channelId -> userId -> isOnline
  final Map<String, Set<String>> typingUsers; // channelId -> Set<userId>

  const RealtimeConnected({
    this.subscribedChannels = const {},
    this.onlineUsers = const {},
    this.typingUsers = const {},
  });

  RealtimeConnected copyWith({
    Set<String>? subscribedChannels,
    Map<String, Map<String, bool>>? onlineUsers,
    Map<String, Set<String>>? typingUsers,
  }) {
    return RealtimeConnected(
      subscribedChannels: subscribedChannels ?? this.subscribedChannels,
      onlineUsers: onlineUsers ?? this.onlineUsers,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}

/// Error state
class RealtimeError extends RealtimeState {
  final String message;
  final Object? error;

  const RealtimeError(this.message, [this.error]);
}

/// Realtime state notifier
class RealtimeNotifier extends StateNotifier<RealtimeState> {
  final Ref _ref;
  RealtimeService? _service;
  Timer? _demoTypingTimer;

  RealtimeNotifier(this._ref) : super(const RealtimeInitial()) {
    _initialize();
  }

  void _initialize() {
    // Listen to auth state changes
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        _initializeRealService();
      } else if (next is AuthDemoMode) {
        _initializeDemoMode();
      } else {
        _cleanup();
      }
    });

    // Check initial state
    final authState = _ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      _initializeRealService();
    } else if (authState is AuthDemoMode) {
      _initializeDemoMode();
    }
  }

  /// Initialize real Supabase realtime service
  void _initializeRealService() {
    state = const RealtimeConnecting();

    try {
      final client = _ref.read(supabaseClientProvider);
      _service = RealtimeService(supabase: client);
      state = const RealtimeConnected();
    } catch (e) {
      state = RealtimeError('Failed to initialize realtime service', e);
      if (kDebugMode) {
        debugPrint('[RealtimeNotifier] Init error: $e');
      }
    }
  }

  /// Initialize demo mode with simulated data
  void _initializeDemoMode() {
    state = RealtimeConnected(
      subscribedChannels: {DemoConfig.demoChannelId},
      onlineUsers: {
        DemoConfig.demoChannelId: {
          DemoConfig.demoCreatorId: true, // Creator is "online"
        },
      },
      typingUsers: const {},
    );
  }

  /// Cleanup resources
  void _cleanup() {
    _demoTypingTimer?.cancel();
    _demoTypingTimer = null;
    _service?.dispose();
    _service = null;
    state = const RealtimeInitial();
  }

  /// Subscribe to a chat channel
  Future<void> subscribeToChannel(
    String channelId, {
    MessageCallback? onNewMessage,
    MessageCallback? onMessageUpdated,
    MessageCallback? onMessageDeleted,
  }) async {
    // Demo mode - just add to subscribed channels
    if (_service == null) {
      if (state is RealtimeConnected) {
        final current = state as RealtimeConnected;
        state = current.copyWith(
          subscribedChannels: {...current.subscribedChannels, channelId},
          onlineUsers: {
            ...current.onlineUsers,
            channelId: {DemoConfig.demoCreatorId: true},
          },
        );
      }
      return;
    }

    // Real mode
    try {
      await _service!.subscribeToChannel(
        channelId,
        onNewMessage: onNewMessage,
        onMessageUpdated: onMessageUpdated,
        onMessageDeleted: onMessageDeleted,
        onPresenceChange: (presences) {
          _updateOnlineUsers(channelId, presences);
        },
        onTypingChange: (typingEvents) {
          _updateTypingUsers(channelId, typingEvents);
        },
      );

      if (state is RealtimeConnected) {
        final current = state as RealtimeConnected;
        state = current.copyWith(
          subscribedChannels: {...current.subscribedChannels, channelId},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RealtimeNotifier] Subscribe error: $e');
      }
    }
  }

  /// Unsubscribe from a chat channel
  Future<void> unsubscribeFromChannel(String channelId) async {
    if (_service != null) {
      await _service!.unsubscribeFromChannel(channelId);
    }

    if (state is RealtimeConnected) {
      final current = state as RealtimeConnected;
      final newChannels = {...current.subscribedChannels}..remove(channelId);
      final newOnlineUsers = {...current.onlineUsers}..remove(channelId);
      final newTypingUsers = {...current.typingUsers}..remove(channelId);

      state = current.copyWith(
        subscribedChannels: newChannels,
        onlineUsers: newOnlineUsers,
        typingUsers: newTypingUsers,
      );
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(
    String channelId, {
    required bool isTyping,
    String? userName,
  }) async {
    if (_service != null) {
      await _service!.sendTypingIndicator(
        channelId,
        isTyping: isTyping,
        userName: userName,
      );
    }
  }

  /// Simulate typing indicator in demo mode
  void simulateDemoTyping(String channelId, String userId) {
    if (state is! RealtimeConnected) return;

    final current = state as RealtimeConnected;
    final channelTyping = {...(current.typingUsers[channelId] ?? <String>{})};
    channelTyping.add(userId);

    state = current.copyWith(
      typingUsers: {...current.typingUsers, channelId: channelTyping},
    );

    // Auto-remove after timeout
    _demoTypingTimer?.cancel();
    _demoTypingTimer = Timer(const Duration(seconds: 3), () {
      if (state is RealtimeConnected) {
        final s = state as RealtimeConnected;
        final updated = {...(s.typingUsers[channelId] ?? <String>{})};
        updated.remove(userId);
        state = s.copyWith(
          typingUsers: {...s.typingUsers, channelId: updated},
        );
      }
    });
  }

  /// Update online users for a channel
  void _updateOnlineUsers(String channelId, Map<String, UserPresence> presences) {
    if (state is! RealtimeConnected) return;

    final current = state as RealtimeConnected;
    final onlineMap = <String, bool>{};

    for (final entry in presences.entries) {
      onlineMap[entry.key] = entry.value.isOnline;
    }

    state = current.copyWith(
      onlineUsers: {...current.onlineUsers, channelId: onlineMap},
    );
  }

  /// Update typing users for a channel
  void _updateTypingUsers(String channelId, List<TypingEvent> typingEvents) {
    if (state is! RealtimeConnected) return;

    final current = state as RealtimeConnected;
    final typingSet = <String>{};

    for (final event in typingEvents) {
      if (event.isTyping) {
        typingSet.add(event.userId);
      }
    }

    state = current.copyWith(
      typingUsers: {...current.typingUsers, channelId: typingSet},
    );
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Main realtime provider
final realtimeProvider = StateNotifierProvider<RealtimeNotifier, RealtimeState>(
  (ref) => RealtimeNotifier(ref),
);

/// Online users for a specific channel
final channelOnlineUsersProvider = Provider.family<Map<String, bool>, String>(
  (ref, channelId) {
    final state = ref.watch(realtimeProvider);
    if (state is RealtimeConnected) {
      return state.onlineUsers[channelId] ?? {};
    }
    return {};
  },
);

/// Typing users for a specific channel
final channelTypingUsersProvider = Provider.family<Set<String>, String>(
  (ref, channelId) {
    final state = ref.watch(realtimeProvider);
    if (state is RealtimeConnected) {
      return state.typingUsers[channelId] ?? {};
    }
    return {};
  },
);

/// Check if a specific user is online in a channel
final isUserOnlineProvider = Provider.family<bool, ({String channelId, String userId})>(
  (ref, params) {
    final onlineUsers = ref.watch(channelOnlineUsersProvider(params.channelId));
    return onlineUsers[params.userId] ?? false;
  },
);

/// Check if realtime is connected
final isRealtimeConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(realtimeProvider);
  return state is RealtimeConnected;
});

/// Get realtime subscribed channel IDs
final realtimeSubscribedChannelsProvider = Provider<Set<String>>((ref) {
  final state = ref.watch(realtimeProvider);
  if (state is RealtimeConnected) {
    return state.subscribedChannels;
  }
  return {};
});
