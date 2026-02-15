import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/creator_content.dart';
import '../../../providers/auth_provider.dart';

/// 커버 섹션 (프로필 배너)
class ContentCoverSection extends StatelessWidget {
  final bool isDark;
  final String creatorName;
  final Color themeColor;
  final UserProfile? profile;
  final VoidCallback onThemeColorTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onProfileEditTap;

  const ContentCoverSection({
    super.key,
    required this.isDark,
    required this.creatorName,
    required this.themeColor,
    required this.profile,
    required this.onThemeColorTap,
    required this.onAvatarTap,
    required this.onProfileEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: themeColor,
      ),
      child: Stack(
        children: [
          // 하단 그래디언트 오버레이
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),
          // 테마 색상 버튼
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: onThemeColorTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('테마',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          // 프로필 아바타
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white24,
                      child: profile != null &&
                              profile!.avatarUrl != null &&
                              profile!.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profile!.avatarUrl!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Icon(Icons.person,
                                    size: 48, color: Colors.white60),
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 48,
                                    color: Colors.white60),
                              ),
                            )
                          : const Icon(Icons.person,
                              size: 48, color: Colors.white60),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(Icons.camera_alt, size: 16, color: themeColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 이름 + 그룹
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onProfileEditTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              creatorName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              size: 22, color: AppColors.verified),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit,
                              size: 14, color: Colors.white70),
                        ],
                      ),
                      if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile!.bio!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          '소개를 입력하세요',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildBadge(
                        '주간랭킹: 1위 +2', Icons.trending_up, isDark, themeColor),
                    const SizedBox(width: 8),
                    _buildBadge('팬 52만', Icons.people, isDark, themeColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
      String text, IconData icon, bool isDark, Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 하이라이트 섹션
class ContentHighlightsSection extends StatelessWidget {
  final bool isDark;
  final Color themeColor;
  final List<CreatorHighlight> highlights;

  const ContentHighlightsSection({
    super.key,
    required this.isDark,
    required this.themeColor,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return _emptyPlaceholder(
          '하이라이트를 추가하세요', Icons.auto_awesome_outlined, isDark);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: highlights.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) {
            final h = highlights[i];
            return Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: h.hasRing
                          ? themeColor
                          : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      width: h.hasRing ? 2 : 1,
                    ),
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                  ),
                  child: Icon(h.icon,
                      size: 24,
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Text(
                  h.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyPlaceholder(String message, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 32, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// 소셜 링크 섹션
class ContentSocialLinksSection extends StatelessWidget {
  final bool isDark;
  final SocialLinks links;
  final Color themeColor;

  const ContentSocialLinksSection({
    super.key,
    required this.isDark,
    required this.links,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!links.hasAnyLink) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          '소셜 링크를 추가하세요',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (links.instagram != null && links.instagram!.isNotEmpty)
            _socialIcon('IG', themeColor, isDark),
          if (links.youtube != null && links.youtube!.isNotEmpty) ...[
            const SizedBox(width: 12),
            _socialIconWidget(Icons.play_circle_outline, themeColor, isDark),
          ],
          if (links.tiktok != null && links.tiktok!.isNotEmpty) ...[
            const SizedBox(width: 12),
            _socialIcon('TT', themeColor, isDark),
          ],
          if (links.twitter != null && links.twitter!.isNotEmpty) ...[
            const SizedBox(width: 12),
            _socialIcon('X', themeColor, isDark),
          ],
        ],
      ),
    );
  }

  Widget _socialIcon(String label, Color color, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _socialIconWidget(IconData icon, Color color, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

/// 액션 버튼 섹션
class ContentActionButtons extends StatelessWidget {
  final bool isDark;
  final Color themeColor;

  const ContentActionButtons({
    super.key,
    required this.isDark,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(
              Icons.chat_bubble_outline, 'DM', false, isDark, themeColor),
          _actionButton(Icons.card_giftcard, '드롭', false, isDark, themeColor),
          _actionButton(Icons.groups, '이벤트', true, isDark, themeColor),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, bool isPrimary, bool isDark,
      Color themeColor) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isPrimary
                ? themeColor
                : (isDark ? AppColors.surfaceDark : Colors.grey[100]),
            border: isPrimary
                ? null
                : Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isPrimary
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// 서포터 랭킹 섹션
class ContentSupporterRanking extends StatelessWidget {
  final bool isDark;
  final Color themeColor;

  const ContentSupporterRanking({
    super.key,
    required this.isDark,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColor.withValues(alpha: 0.1),
            ),
            child:
                Icon(Icons.emoji_events_outlined, color: themeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 서포터 랭킹: 12위',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.text,
                  ),
                ),
                Text(
                  'Gold Member \u2022 상위 5%',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 피드 미리보기 섹션
class ContentFeedPreview extends StatelessWidget {
  final bool isDark;
  final Color themeColor;

  const ContentFeedPreview({
    super.key,
    required this.isDark,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 탭바 미리보기
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            children: [
              _tabPreview('하이라이트', true, isDark, themeColor),
              _tabPreview('공지사항', false, isDark, themeColor),
              _tabPreview('오타 레터', false, isDark, themeColor),
            ],
          ),
        ),
        // 피드 아이템 미리보기 (1개만)
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: themeColor,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '피드 게시물 미리보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '피드는 채팅탭에서 브로드캐스트로 관리됩니다...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabPreview(
      String label, bool isActive, bool isDark, Color themeColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? themeColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? themeColor
                  : (isDark ? Colors.grey[500] : Colors.grey[500]),
            ),
          ),
        ),
      ),
    );
  }
}
