/// YouTube fancam video model
class YouTubeFancam {
  final String id;
  final String videoId;
  final String title;
  final String? description;
  final DateTime? uploadedAt;
  final int? viewCount;
  final bool isPinned;

  const YouTubeFancam({
    required this.id,
    required this.videoId,
    required this.title,
    this.description,
    this.uploadedAt,
    this.viewCount,
    this.isPinned = false,
  });

  /// Extract video ID from various YouTube URL formats
  static String? extractVideoId(String url) {
    // Standard watch URL: https://www.youtube.com/watch?v=VIDEO_ID
    // Short URL: https://youtu.be/VIDEO_ID
    // Embed URL: https://www.youtube.com/embed/VIDEO_ID
    // Shorts URL: https://www.youtube.com/shorts/VIDEO_ID

    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }

    // If the input is already a video ID (11 characters)
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }

    return null;
  }

  /// Get YouTube video URL
  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';

  /// Get thumbnail URL (default quality)
  String get thumbnailUrl => 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  /// Get high quality thumbnail URL
  String get thumbnailUrlHQ => 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';

  /// Get medium quality thumbnail URL
  String get thumbnailUrlMQ => 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

  /// Get standard quality thumbnail URL
  String get thumbnailUrlSD => 'https://img.youtube.com/vi/$videoId/sddefault.jpg';

  /// Format view count for display
  String get formattedViewCount {
    if (viewCount == null) return '';
    if (viewCount! >= 1000000) {
      return '${(viewCount! / 1000000).toStringAsFixed(1)}M views';
    } else if (viewCount! >= 10000) {
      return '${(viewCount! / 10000).toStringAsFixed(0)}만 views';
    } else if (viewCount! >= 1000) {
      return '${(viewCount! / 1000).toStringAsFixed(1)}K views';
    }
    return '$viewCount views';
  }
}

class Artist {
  final String id;
  final String name;
  final String? englishName;
  final String? group;
  final String avatarUrl;
  final int followerCount;
  final int? rank;
  final bool isVerified;
  final bool isOnline;
  final String? bio;
  final int postCount;
  final String tier; // STANDARD, VIP
  final List<YouTubeFancam> fancams;

  const Artist({
    required this.id,
    required this.name,
    this.englishName,
    this.group,
    required this.avatarUrl,
    required this.followerCount,
    this.rank,
    this.isVerified = false,
    this.isOnline = false,
    this.bio,
    this.postCount = 0,
    this.tier = 'STANDARD',
    this.fancams = const [],
  });

  String get displayName => englishName != null ? '$name ($englishName)' : name;

  String get formattedFollowers {
    if (followerCount >= 1000000) {
      return '${(followerCount / 1000000).toStringAsFixed(1)}M';
    } else if (followerCount >= 10000) {
      return '${(followerCount / 10000).toStringAsFixed(0)}만';
    } else if (followerCount >= 1000) {
      return '${(followerCount / 1000).toStringAsFixed(0)}천';
    }
    return followerCount.toString();
  }

  /// Get pinned fancam (first pinned or first in list)
  YouTubeFancam? get pinnedFancam {
    if (fancams.isEmpty) return null;
    return fancams.firstWhere(
      (f) => f.isPinned,
      orElse: () => fancams.first,
    );
  }
}
