/// Private Card Model
/// Special "letter-style" message that artists send to selected fans
/// with decorative card backgrounds and personalized messages.
library;

/// Status of a private card
enum PrivateCardStatus {
  draft,
  sending,
  sent,
  failed,
}

/// Card template background design
class PrivateCardTemplate {
  final String id;
  final String name;
  final String category;
  final String thumbnailUrl;
  final String fullImageUrl;
  final bool isPremium;
  final int sortOrder;

  const PrivateCardTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.thumbnailUrl,
    required this.fullImageUrl,
    this.isPremium = false,
    this.sortOrder = 0,
  });

  factory PrivateCardTemplate.fromJson(Map<String, dynamic> json) {
    return PrivateCardTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'general',
      thumbnailUrl: json['thumbnail_url'] as String,
      fullImageUrl: json['full_image_url'] as String,
      isPremium: json['is_premium'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'thumbnail_url': thumbnailUrl,
        'full_image_url': fullImageUrl,
        'is_premium': isPremium,
        'sort_order': sortOrder,
      };
}

/// A private card composed/sent by an artist
class PrivateCard {
  final String id;
  final String channelId;
  final String artistId;
  final String? templateContent; // Text with {fanName} placeholders
  final String cardTemplateId;
  final String? cardImageUrl; // The decorative card background
  final List<String> mediaUrls; // Additional media attachments
  final Map<String, dynamic>? mediaMetadata;
  final int recipientCount;
  final String filterUsed;
  final List<String> recipientIds;
  final PrivateCardStatus status;
  final int maxCharacters;
  final DateTime createdAt;
  final DateTime? sentAt;

  const PrivateCard({
    required this.id,
    required this.channelId,
    required this.artistId,
    this.templateContent,
    required this.cardTemplateId,
    this.cardImageUrl,
    this.mediaUrls = const [],
    this.mediaMetadata,
    this.recipientCount = 0,
    this.filterUsed = 'allFans',
    this.recipientIds = const [],
    this.status = PrivateCardStatus.draft,
    this.maxCharacters = 500,
    required this.createdAt,
    this.sentAt,
  });

  /// Get personalized content for a specific fan
  String getPersonalizedContent({
    required String fanName,
    int? subscribeDays,
    String? tier,
  }) {
    String result = templateContent ?? '';
    result = result.replaceAll('{fanName}', fanName);
    if (subscribeDays != null) {
      result = result.replaceAll('{subscribeDays}', subscribeDays.toString());
    }
    if (tier != null) {
      result = result.replaceAll('{tier}', tier);
    }
    return result;
  }

  PrivateCard copyWith({
    String? id,
    String? channelId,
    String? artistId,
    String? templateContent,
    String? cardTemplateId,
    String? cardImageUrl,
    List<String>? mediaUrls,
    Map<String, dynamic>? mediaMetadata,
    int? recipientCount,
    String? filterUsed,
    List<String>? recipientIds,
    PrivateCardStatus? status,
    int? maxCharacters,
    DateTime? createdAt,
    DateTime? sentAt,
  }) {
    return PrivateCard(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      artistId: artistId ?? this.artistId,
      templateContent: templateContent ?? this.templateContent,
      cardTemplateId: cardTemplateId ?? this.cardTemplateId,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      recipientCount: recipientCount ?? this.recipientCount,
      filterUsed: filterUsed ?? this.filterUsed,
      recipientIds: recipientIds ?? this.recipientIds,
      status: status ?? this.status,
      maxCharacters: maxCharacters ?? this.maxCharacters,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  factory PrivateCard.fromJson(Map<String, dynamic> json) {
    return PrivateCard(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      artistId: json['artist_id'] as String,
      templateContent: json['template_content'] as String?,
      cardTemplateId: json['card_template_id'] as String? ?? '',
      cardImageUrl: json['card_image_url'] as String?,
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      mediaMetadata: json['media_metadata'] as Map<String, dynamic>?,
      recipientCount: json['recipient_count'] as int? ?? 0,
      filterUsed: json['filter_used'] as String? ?? 'allFans',
      recipientIds: (json['recipient_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: PrivateCardStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PrivateCardStatus.draft,
      ),
      maxCharacters: json['max_characters'] as int? ?? 500,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_id': channelId,
        'artist_id': artistId,
        'template_content': templateContent,
        'card_template_id': cardTemplateId,
        'card_image_url': cardImageUrl,
        'media_urls': mediaUrls,
        'media_metadata': mediaMetadata,
        'recipient_count': recipientCount,
        'filter_used': filterUsed,
        'recipient_ids': recipientIds,
        'status': status.name,
        'max_characters': maxCharacters,
        'created_at': createdAt.toIso8601String(),
        'sent_at': sentAt?.toIso8601String(),
      };
}
