/// Notification service for handling push notifications and in-app notifications
///
/// Manages notification preferences, channels, and display logic.
class NotificationService {
  /// Notification channels
  static const String channelChat = 'chat';
  static const String channelDonation = 'donation';
  static const String channelPromotion = 'promotion';
  static const String channelSystem = 'system';

  /// Default notification settings
  static Map<String, bool> get defaultSettings => {
        channelChat: true,
        channelDonation: true,
        channelPromotion: true,
        channelSystem: true,
      };

  /// Build notification title based on type
  String buildNotificationTitle(NotificationType type, String senderName) {
    switch (type) {
      case NotificationType.newMessage:
        return '$senderName님의 새 메시지';
      case NotificationType.newBroadcast:
        return '$senderName님의 새 소식';
      case NotificationType.donationReceived:
        return '후원을 받았습니다';
      case NotificationType.donationSent:
        return '후원을 보냈습니다';
      case NotificationType.subscriptionRenewal:
        return '구독 갱신 알림';
      case NotificationType.subscriptionExpiring:
        return '구독 만료 예정';
      case NotificationType.quotaRefreshed:
        return '답장 횟수가 초기화되었습니다';
      case NotificationType.systemAnnouncement:
        return 'UNO A 알림';
    }
  }

  /// Build notification body based on type
  String buildNotificationBody(
    NotificationType type, {
    String? content,
    String? senderName,
    int? amount,
    DateTime? expiryDate,
  }) {
    switch (type) {
      case NotificationType.newMessage:
      case NotificationType.newBroadcast:
        return content ?? '';
      case NotificationType.donationReceived:
        return '$senderName님이 ${amount ?? 0} DT를 후원했습니다';
      case NotificationType.donationSent:
        return '${amount ?? 0} DT를 후원했습니다';
      case NotificationType.subscriptionRenewal:
        return '$senderName 채널 구독이 갱신되었습니다';
      case NotificationType.subscriptionExpiring:
        final days = expiryDate?.difference(DateTime.now()).inDays ?? 0;
        return '$senderName 채널 구독이 ${days}일 후 만료됩니다';
      case NotificationType.quotaRefreshed:
        return '오늘의 답장 횟수가 초기화되었습니다';
      case NotificationType.systemAnnouncement:
        return content ?? '';
    }
  }

  /// Get channel for notification type
  String getChannelForType(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
      case NotificationType.newBroadcast:
        return channelChat;
      case NotificationType.donationReceived:
      case NotificationType.donationSent:
        return channelDonation;
      case NotificationType.subscriptionRenewal:
      case NotificationType.subscriptionExpiring:
      case NotificationType.quotaRefreshed:
        return channelPromotion;
      case NotificationType.systemAnnouncement:
        return channelSystem;
    }
  }

  /// Check if notification should be shown based on user settings
  bool shouldShowNotification(
    NotificationType type,
    Map<String, bool> userSettings,
  ) {
    final channel = getChannelForType(type);
    return userSettings[channel] ?? true;
  }

  /// Get notification priority
  NotificationPriority getPriority(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
      case NotificationType.donationReceived:
        return NotificationPriority.high;
      case NotificationType.newBroadcast:
      case NotificationType.systemAnnouncement:
        return NotificationPriority.normal;
      case NotificationType.subscriptionExpiring:
      case NotificationType.subscriptionRenewal:
      case NotificationType.donationSent:
      case NotificationType.quotaRefreshed:
        return NotificationPriority.low;
    }
  }

  /// Format notification for display
  NotificationDisplay formatNotification({
    required NotificationType type,
    required String senderName,
    String? content,
    int? amount,
    DateTime? expiryDate,
    String? avatarUrl,
  }) {
    return NotificationDisplay(
      title: buildNotificationTitle(type, senderName),
      body: buildNotificationBody(
        type,
        content: content,
        senderName: senderName,
        amount: amount,
        expiryDate: expiryDate,
      ),
      channel: getChannelForType(type),
      priority: getPriority(type),
      avatarUrl: avatarUrl,
      type: type,
    );
  }
}

/// Types of notifications
enum NotificationType {
  newMessage,
  newBroadcast,
  donationReceived,
  donationSent,
  subscriptionRenewal,
  subscriptionExpiring,
  quotaRefreshed,
  systemAnnouncement,
}

/// Notification priority levels
enum NotificationPriority {
  high,
  normal,
  low,
}

/// Formatted notification for display
class NotificationDisplay {
  final String title;
  final String body;
  final String channel;
  final NotificationPriority priority;
  final String? avatarUrl;
  final NotificationType type;

  const NotificationDisplay({
    required this.title,
    required this.body,
    required this.channel,
    required this.priority,
    this.avatarUrl,
    required this.type,
  });
}
