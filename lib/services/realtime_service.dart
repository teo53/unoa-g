import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';

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
      opts: const RealtimeChannelConfig(
        key: null,
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
      channel.onPresenceSync((payload) {
        final presences = <String, UserPresence>{};

        for (final presence in payload.currentPresences) {
          final userId = presence.payload['user_id'] as String?;
          if (userId != null) {
            presences[userId] = UserPresence(
              userId: userId,
              isOnline: true,
              lastSeen: DateTime.now(),
              status: presence.payload['status'] as String?,
            );
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
          final typingTimerKey = '$channelId:${event.userId}';

          if (event.userId == _currentUserId) return; // Ignore own typing

          if (event.isTyping) {
            typingUsers[event.userId] = event;

            // Set timer to remove typing indicator
            _typingTimers[typingTimerKey]?.cancel();
            _typingTimers[typingTimerKey] = Timer(typingTimeout, () {
              typingUsers.remove(event.userId);
              _typingTimers.remove(typingTimerKey);
              onTypingChange(typingUsers.values.toList());
            });
          } else {
            typingUsers.remove(event.userId);
            _typingTimers[typingTimerKey]?.cancel();
            _typingTimers.remove(typingTimerKey);
          }

          onTypingChange(typingUsers.values.toList());
        },
      );
    }

    // Subscribe
    await channel.subscribe((status, error) {
      debugPrint('Channel $channelName status: $status');
      if (error != null) {
        debugPrint('Channel error: $error');
      }
    });

    _channels[channelId] = channel;

    // Track user presence
    await _trackPresence(channel);
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
      debugPrint('Error tracking presence: $e');
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
      debugPrint('Error sending typing indicator: $e');
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
      debugPrint('Error updating status: $e');
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

    await channel.subscribe();

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

    await channel.subscribe();

    return channel;
  }

  /// Check if channel is subscribed
  bool isSubscribed(String channelId) {
    return _channels.containsKey(channelId);
  }

  /// Get subscribed channel IDs
  List<String> get subscribedChannels => _channels.keys.toList();
}

/// Singleton instance
final realtimeService = RealtimeService();
