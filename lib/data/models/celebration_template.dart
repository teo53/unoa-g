/// A celebration message template with variable placeholders.
///
/// Variables: {nickname}, {day_count}, {artist_name}
class CelebrationTemplate {
  final String id;
  final String? channelId; // null = system default
  final String eventType;
  final String templateText;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  const CelebrationTemplate({
    required this.id,
    this.channelId,
    required this.eventType,
    required this.templateText,
    this.isDefault = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory CelebrationTemplate.fromJson(Map<String, dynamic> json) {
    return CelebrationTemplate(
      id: json['id'] as String,
      channelId: json['channel_id'] as String?,
      eventType: json['event_type'] as String,
      templateText: json['template_text'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel_id': channelId,
    'event_type': eventType,
    'template_text': templateText,
    'is_default': isDefault,
    'sort_order': sortOrder,
  };

  /// Whether this is a system-default template.
  bool get isSystemDefault => channelId == null;

  /// Korean label for the event type.
  String get eventTypeLabel {
    switch (eventType) {
      case 'birthday':
        return '생일';
      case 'milestone_50':
        return '50일';
      case 'milestone_100':
        return '100일';
      case 'milestone_365':
        return '1주년';
      case 'custom':
        return '커스텀';
      default:
        return eventType;
    }
  }
}
