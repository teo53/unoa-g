import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../core/utils/app_logger.dart';

/// Typing indicator event
class TypingEvent {
  final String channelId;
  final String userId;
  final String? userName;
  final bool isTyping;
  final DateTime timestamp;

  const TypingEvent({
    required this.channelId,
    required this.userId,
    this.userName,
    required this.isTyping,
    required this.timestamp,
  });

  factory TypingEvent.fromPayload(Map<String, dynamic> payload) {
    return TypingEvent(
      channelId: payload['channel_id'] as String,
      userId: payload['user_id'] as String,
      userName: payload['user_name'] as String?,
      isTyping: payload['is_typing'] as bool,
      timestamp: DateTime.now(),
    );
  }
}

/// User presence info
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? status;

  const UserPresence({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
    this.status,
  });
}

/// Online status changed callback
typedef OnlineStatusCallback = void Function(Map<String, UserPresence> users);

/// Typing indicator callback
typedef TypingCallback = void Function(List<TypingEvent> typingUsers);

/// New message callback
typedef MessageCallback = void Function(Map<String, dynamic> message);

/// Service for managing Supabase Realtime connections
class RealtimeService {
  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, Timer> _typingTimers = {};

  // Typing indicator timeout (stop showing after 3 seconds of no activity)
  static const Duration typingTimeout = Duration(seconds: 3);

  // Presence heartbeat interval
  static const Duration heartbeatInterval = Duration(seconds: 30);

  RealtimeService({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseConfig.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  /// Subscribe to a chat channel for real-time updates
  Future<void> subscribeToChannel(
    String channelId, {
    MessageCallback? onNewMessage,
    MessageCallback? onMessageUpdated,
    MessageCallback? onMessageDeleted,
    OnlineStatusCallback? onPresenceChange,
    TypingCallback? onTypingChange,
  }) async {
    final channelName = 'chat:$channelId';

    // Close existing subscription if any
    await unsubscribeFromChannel(channelId);

    // Create new channel
    final channel = _supabase.channel(
      channelName,
      opts: RealtimeChannelConfig(
        key: _currentUserId,
        ack: false,
      ),
    );

    // Subscribe to message changes
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: channelId,
          ),
          callback: (payload) {
            onNewMessage?.call(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: channelId,
          ),
          callback: (payload) {
            onMessageUpdated?.call(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: channelId,
          ),
          callback: (payload) {
            onMessageDeleted?.call(payload.oldRecord);
          },
        );

    // Subscribe to presence (online status)
    if (onPresenceChange != null) {
      channel.onPresenceSync((_) {
        // Get current state from the channel's presenceState()
        final presenceState = channel.presenceState();
        final presences = <String, UserPresence>{};

        // Iterate through SinglePresenceState list
        for (final singleState in presenceState) {
          // Each singleState has a list of Presence objects
          for (final presence in singleState.presences) {
            final presenceUserId = presence.payload['user_id'] as String?;
            if (presenceUserId != null) {
              presences[presenceUserId] = UserPresence(
                userId: presenceUserId,
                isOnline: true,
                lastSeen: DateTime.now(),
                status: presence.payload['status'] as String?,
              );
            }
          }
        }

        onPresenceChange(presences);
      });
    }

    // Subscribe to typing indicators via broadcast
    if (onTypingChange != null) {
      final typingUsers = <String, TypingEvent>{};

      channel.onBroadcast(
        event: 'typing',
        callback: (payload) {
          final event = TypingEvent.fromPayload(payload);

          if (event.userId == _currentUserId) return; // Ignore own typing

          // Use composite key so unsubscribeFromChannel can find timers
          final timerKey = '$channelId:${event.userId}';

          if (event.isTyping) {
            typingUsers[event.userId] = event;

            // Set timer to remove typing indicator
            _typingTimers[timerKey]?.cancel();
            _typingTimers[timerKey] = Timer(typingTimeout, () {
              typingUsers.remove(event.userId);
              _typingTimers.remove(timerKey);
              onTypingChange(typingUsers.values.toList());
            });
          } else {
            typingUsers.remove(event.userId);
            _typingTimers[timerKey]?.cancel();
            _typingTimers.remove(timerKey);
          }

          onTypingChange(typingUsers.values.toList());
        },
      );
    }

    // Subscribe (no await - returns RealtimeChannel, not Future)
    channel.subscribe((status, error) {
      AppLogger.debug('Channel $channelName status: $status', tag: 'Realtime');
      if (error != null) {
        AppLogger.warning('Channel $channelName error: $error',
            tag: 'Realtime');
      }
    });

    _channels[channelId] = channel;

    // Track user presence
    _trackPresence(channel);
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribeFromChannel(String channelId) async {
    final channel = _channels.remove(channelId);
    if (channel != null) {
      await channel.unsubscribe();
    }

    // Clear typing timers for this channel
    _typingTimers.entries
        .where((e) => e.key.startsWith('$channelId:'))
        .toList()
        .forEach((e) {
      e.value.cancel();
      _typingTimers.remove(e.key);
    });
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    for (final channelId in _channels.keys.toList()) {
      await unsubscribeFromChannel(channelId);
    }

    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
  }

  /// Track user presence in a channel
  Future<void> _trackPresence(RealtimeChannel channel) async {
    try {
      await channel.track({
        'user_id': _currentUserId,
        'online_at': DateTime.now().toIso8601String(),
        'status': 'online',
      });
    } catch (e) {
      AppLogger.debug('Error tracking presence: $e', tag: 'Realtime');
    }
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(
    String channelId, {
    required bool isTyping,
    String? userName,
  }) async {
    final channel = _channels[channelId];
    if (channel == null) return;

    try {
      await channel.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'channel_id': channelId,
          'user_id': _currentUserId,
          'user_name': userName,
          'is_typing': isTyping,
        },
      );
    } catch (e) {
      AppLogger.debug('Error sending typing indicator: $e', tag: 'Realtime');
    }
  }

  /// Update user status
  Future<void> updateStatus(String channelId, String status) async {
    final channel = _channels[channelId];
    if (channel == null) return;

    try {
      await channel.track({
        'user_id': _currentUserId,
        'online_at': DateTime.now().toIso8601String(),
        'status': status,
      });
    } catch (e) {
      AppLogger.debug('Error updating status: $e', tag: 'Realtime');
    }
  }

  /// Subscribe to user's notifications across all channels
  Future<RealtimeChannel> subscribeToNotifications({
    required String userId,
    MessageCallback? onNewNotification,
  }) async {
    final channelName = 'notifications:$userId';

    final channel = _supabase.channel(channelName);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        onNewNotification?.call(payload.newRecord);
      },
    );

    channel.subscribe();

    return channel;
  }

  /// Subscribe to wallet balance changes
  Future<RealtimeChannel> subscribeToWallet({
    required String userId,
    void Function(int newBalance)? onBalanceChange,
  }) async {
    final channelName = 'wallet:$userId';

    final channel = _supabase.channel(channelName);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'wallets',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        final newBalance = payload.newRecord['balance_dt'] as int?;
        if (newBalance != null) {
          onBalanceChange?.call(newBalance);
        }
      },
    );

    channel.subscribe();

    return channel;
  }

  /// Check if channel is subscribed
  bool isSubscribed(String channelId) {
    return _channels.containsKey(channelId);
  }

  /// Get subscribed channel IDs
  List<String> get subscribedChannels => _channels.keys.toList();

  /// Dispose all resources
  Future<void> dispose() async {
    await unsubscribeAll();
  }
}

/// Singleton instance (optional - prefer using Provider for better lifecycle management)
final realtimeService = RealtimeService();
