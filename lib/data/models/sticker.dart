/// Sticker Models
/// 땡큐 스티커 시스템 데이터 모델
library;

/// 스티커 팩 (크리에이터가 설정)
class StickerSet {
  final String id;
  final String channelId;
  final String creatorId;
  final String name;
  final String? description;
  final String? thumbnailUrl;
  final int priceDt;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Sticker> stickers;
  final bool isPurchased; // 현재 사용자가 구매했는지

  const StickerSet({
    required this.id,
    required this.channelId,
    required this.creatorId,
    required this.name,
    this.description,
    this.thumbnailUrl,
    this.priceDt = 100,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
    this.stickers = const [],
    this.isPurchased = false,
  });

  bool get isFree => priceDt == 0;

  factory StickerSet.fromJson(Map<String, dynamic> json) {
    return StickerSet(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      creatorId: json['creator_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      priceDt: json['price_dt'] as int? ?? 100,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      stickers: json['stickers'] != null
          ? (json['stickers'] as List)
              .map((s) => Sticker.fromJson(s as Map<String, dynamic>))
              .toList()
          : [],
      isPurchased: json['is_purchased'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'creator_id': creatorId,
      'name': name,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'price_dt': priceDt,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'stickers': stickers.map((s) => s.toJson()).toList(),
      'is_purchased': isPurchased,
    };
  }

  StickerSet copyWith({
    String? id,
    String? channelId,
    String? creatorId,
    String? name,
    String? description,
    String? thumbnailUrl,
    int? priceDt,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Sticker>? stickers,
    bool? isPurchased,
  }) {
    return StickerSet(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      creatorId: creatorId ?? this.creatorId,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      priceDt: priceDt ?? this.priceDt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stickers: stickers ?? this.stickers,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StickerSet && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// 개별 스티커
class Sticker {
  final String id;
  final String stickerSetId;
  final String name;
  final String imageUrl;
  final String? animationUrl;
  final int sortOrder;
  final DateTime createdAt;

  const Sticker({
    required this.id,
    required this.stickerSetId,
    required this.name,
    required this.imageUrl,
    this.animationUrl,
    this.sortOrder = 0,
    required this.createdAt,
  });

  bool get isAnimated => animationUrl != null;

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id'] as String,
      stickerSetId: json['sticker_set_id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
      animationUrl: json['animation_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sticker_set_id': stickerSetId,
      'name': name,
      'image_url': imageUrl,
      'animation_url': animationUrl,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Sticker copyWith({
    String? id,
    String? stickerSetId,
    String? name,
    String? imageUrl,
    String? animationUrl,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Sticker(
      id: id ?? this.id,
      stickerSetId: stickerSetId ?? this.stickerSetId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Sticker && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// 스티커 구매 기록
class StickerPurchase {
  final String id;
  final String buyerId;
  final String stickerSetId;
  final int priceDt;
  final DateTime purchasedAt;

  const StickerPurchase({
    required this.id,
    required this.buyerId,
    required this.stickerSetId,
    required this.priceDt,
    required this.purchasedAt,
  });

  factory StickerPurchase.fromJson(Map<String, dynamic> json) {
    return StickerPurchase(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      stickerSetId: json['sticker_set_id'] as String,
      priceDt: json['price_dt'] as int? ?? 0,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'sticker_set_id': stickerSetId,
      'price_dt': priceDt,
      'purchased_at': purchasedAt.toIso8601String(),
    };
  }
}
