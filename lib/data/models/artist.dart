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
}
