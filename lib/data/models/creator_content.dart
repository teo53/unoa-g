/// 크리에이터 콘텐츠 관련 모델 정의
/// - 드롭(상품), 이벤트, 직캠 관리
library;

import 'package:flutter/material.dart';

/// 드롭(상품) 모델
class CreatorDrop {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int priceKrw;
  final bool isSoldOut;
  final bool isNew;
  final DateTime? releaseDate;
  final String? externalUrl;
  final int displayOrder;

  const CreatorDrop({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.priceKrw,
    this.isSoldOut = false,
    this.isNew = false,
    this.releaseDate,
    this.externalUrl,
    this.displayOrder = 0,
  });

  CreatorDrop copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? priceKrw,
    bool? isSoldOut,
    bool? isNew,
    DateTime? releaseDate,
    String? externalUrl,
    int? displayOrder,
  }) {
    return CreatorDrop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      priceKrw: priceKrw ?? this.priceKrw,
      isSoldOut: isSoldOut ?? this.isSoldOut,
      isNew: isNew ?? this.isNew,
      releaseDate: releaseDate ?? this.releaseDate,
      externalUrl: externalUrl ?? this.externalUrl,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  /// 가격 포맷팅 (예: ₩12,000)
  String get formattedPrice {
    final formatted = priceKrw.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '₩$formatted';
  }
}

/// 이벤트 모델
class CreatorEvent {
  final String id;
  final String title;
  final String location;
  final DateTime date;
  final bool isOffline;
  final String? description;
  final String? ticketUrl;
  final String? imageUrl;
  final int displayOrder;

  const CreatorEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    this.isOffline = true,
    this.description,
    this.ticketUrl,
    this.imageUrl,
    this.displayOrder = 0,
  });

  CreatorEvent copyWith({
    String? id,
    String? title,
    String? location,
    DateTime? date,
    bool? isOffline,
    String? description,
    String? ticketUrl,
    String? imageUrl,
    int? displayOrder,
  }) {
    return CreatorEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: date ?? this.date,
      isOffline: isOffline ?? this.isOffline,
      description: description ?? this.description,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  /// 이벤트 타입 라벨
  String get typeLabel => isOffline ? 'OFFLINE' : 'ONLINE';

  /// 날짜 포맷팅 (예: 2024.03.15)
  String get formattedDate {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

/// 직캠 모델
class CreatorFancam {
  final String id;
  final String videoId; // YouTube video ID
  final String title;
  final String? description;
  final int viewCount;
  final bool isPinned;
  final int displayOrder;
  final DateTime? uploadDate;

  const CreatorFancam({
    required this.id,
    required this.videoId,
    required this.title,
    this.description,
    this.viewCount = 0,
    this.isPinned = false,
    this.displayOrder = 0,
    this.uploadDate,
  });

  CreatorFancam copyWith({
    String? id,
    String? videoId,
    String? title,
    String? description,
    int? viewCount,
    bool? isPinned,
    int? displayOrder,
    DateTime? uploadDate,
  }) {
    return CreatorFancam(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      description: description ?? this.description,
      viewCount: viewCount ?? this.viewCount,
      isPinned: isPinned ?? this.isPinned,
      displayOrder: displayOrder ?? this.displayOrder,
      uploadDate: uploadDate ?? this.uploadDate,
    );
  }

  /// YouTube 썸네일 URL
  String get thumbnailUrl => 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

  /// YouTube 영상 URL
  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';

  /// 조회수 포맷팅 (예: 1.2M, 350K)
  String get formattedViewCount {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(0)}K';
    }
    return viewCount.toString();
  }

  /// YouTube URL에서 video ID 추출
  static String? extractVideoId(String url) {
    // https://www.youtube.com/watch?v=VIDEO_ID
    // https://youtu.be/VIDEO_ID
    // https://www.youtube.com/embed/VIDEO_ID
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }
}

/// 하이라이트 모델
class CreatorHighlight {
  final String id;
  final String label;
  final IconData icon;
  final bool hasRing;
  final int displayOrder;

  const CreatorHighlight({
    required this.id,
    required this.label,
    this.icon = Icons.star,
    this.hasRing = false,
    this.displayOrder = 0,
  });

  CreatorHighlight copyWith({
    String? id,
    String? label,
    IconData? icon,
    bool? hasRing,
    int? displayOrder,
  }) {
    return CreatorHighlight(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      hasRing: hasRing ?? this.hasRing,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}

/// 소셜 미디어 링크 모델
class SocialLinks {
  final String? instagram;
  final String? youtube;
  final String? tiktok;
  final String? twitter;
  final List<CustomLink> customLinks;

  const SocialLinks({
    this.instagram,
    this.youtube,
    this.tiktok,
    this.twitter,
    this.customLinks = const [],
  });

  SocialLinks copyWith({
    String? instagram,
    String? youtube,
    String? tiktok,
    String? twitter,
    List<CustomLink>? customLinks,
  }) {
    return SocialLinks(
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      tiktok: tiktok ?? this.tiktok,
      twitter: twitter ?? this.twitter,
      customLinks: customLinks ?? this.customLinks,
    );
  }

  /// Map으로 변환 (저장용)
  Map<String, dynamic> toMap() {
    return {
      if (instagram != null && instagram!.isNotEmpty) 'instagram': instagram,
      if (youtube != null && youtube!.isNotEmpty) 'youtube': youtube,
      if (tiktok != null && tiktok!.isNotEmpty) 'tiktok': tiktok,
      if (twitter != null && twitter!.isNotEmpty) 'twitter': twitter,
      if (customLinks.isNotEmpty)
        'custom': customLinks.map((l) => l.toMap()).toList(),
    };
  }

  /// Map에서 생성
  factory SocialLinks.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SocialLinks();
    return SocialLinks(
      instagram: map['instagram'] as String?,
      youtube: map['youtube'] as String?,
      tiktok: map['tiktok'] as String?,
      twitter: map['twitter'] as String?,
      customLinks: (map['custom'] as List<dynamic>?)
              ?.map((e) => CustomLink.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 링크가 있는지 확인
  bool get hasAnyLink =>
      (instagram?.isNotEmpty ?? false) ||
      (youtube?.isNotEmpty ?? false) ||
      (tiktok?.isNotEmpty ?? false) ||
      (twitter?.isNotEmpty ?? false) ||
      customLinks.isNotEmpty;
}

/// 커스텀 링크 모델
class CustomLink {
  final String label;
  final String url;
  final IconData? icon;

  const CustomLink({
    required this.label,
    required this.url,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'url': url,
    };
  }

  factory CustomLink.fromMap(Map<String, dynamic> map) {
    return CustomLink(
      label: map['label'] as String,
      url: map['url'] as String,
    );
  }
}
