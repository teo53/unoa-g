import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';

/// Feed Post Widget - Uses primary500 for like icon and avatar border
class ArtistFeedPost extends StatelessWidget {
  final String artistName;
  final String artistAvatarUrl;
  final String content;
  final String? imageUrl;
  final String time;
  final int likes;
  final int comments;
  final bool isPinned;

  const ArtistFeedPost({
    super.key,
    required this.artistName,
    required this.artistAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.time,
    required this.likes,
    required this.comments,
    this.isPinned = false,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinned indicator
          if (isPinned) ...[
            const Row(
              children: [
                Icon(
                  Icons.push_pin,
                  size: 14,
                  color: AppColors.primary500,
                ),
                SizedBox(width: 4),
                Text(
                  '고정된 게시물',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Header
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  border: Border.all(
                    color: AppColors.primary500,
                    width: 2,
                  ),
                ),
                child: artistAvatarUrl.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      )
                    : ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: artistAvatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$artistName ($artistName)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textMainDark
                            : AppColors.textMainLight,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_horiz,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),

          // Image
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              const Icon(
                Icons.favorite,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(likes),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(comments),
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Feed Compose Bottom Sheet - Uses primary600 for CTA
class FeedComposeSheet extends StatefulWidget {
  final String artistName;

  const FeedComposeSheet({super.key, required this.artistName});

  @override
  State<FeedComposeSheet> createState() => _FeedComposeSheetState();
}

class _FeedComposeSheetState extends State<FeedComposeSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasContent = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '피드 작성',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Text Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '팬들에게 전하고 싶은 이야기를 작성해주세요...',
                  hintStyle: TextStyle(
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Attachment Options
            Row(
              children: [
                AttachmentButton(
                  icon: Icons.image_outlined,
                  label: '사진',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('사진 첨부 기능 준비 중')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                AttachmentButton(
                  icon: Icons.videocam_outlined,
                  label: '영상',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('영상 첨부 기능 준비 중')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                AttachmentButton(
                  icon: Icons.poll_outlined,
                  label: '투표',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('투표 기능 준비 중')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Post Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasContent
                    ? () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('피드가 작성되었습니다'),
                            backgroundColor: AppColors.primary600,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  disabledBackgroundColor:
                      isDark ? Colors.grey[800] : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '게시하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _hasContent
                        ? Colors.white
                        : (isDark ? Colors.grey[600] : Colors.grey[500]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Announcement Post Widget - 공지사항 스타일
class AnnouncementPost extends StatelessWidget {
  final String artistName;
  final String artistAvatarUrl;
  final String content;
  final String time;
  final int likes;
  final int comments;

  const AnnouncementPost({
    super.key,
    required this.artistName,
    required this.artistAvatarUrl,
    required this.content,
    required this.time,
    required this.likes,
    required this.comments,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primary500.withValues(alpha: 0.3)
              : AppColors.primary100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Official badge header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '공식 공지',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.push_pin,
                size: 16,
                color: AppColors.primary500,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Content
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              const Icon(
                Icons.favorite,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(likes),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(comments),
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.bookmark_border,
                size: 20,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ota Letter Post Widget - 편지/일기 스타일
class OtaLetterPost extends StatelessWidget {
  final String artistName;
  final String artistAvatarUrl;
  final String content;
  final String time;
  final int likes;
  final int comments;

  const OtaLetterPost({
    super.key,
    required this.artistName,
    required this.artistAvatarUrl,
    required this.content,
    required this.time,
    required this.likes,
    required this.comments,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : const Color(0xFFFFFDF5), // 따뜻한 편지 톤
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.amber.withValues(alpha: 0.2)
              : const Color(0xFFE8DCC8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Letter header - 편지 스타일 아이콘
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: artistAvatarUrl.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      )
                    : ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: artistAvatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$artistName의 편지',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.mail_outline_rounded,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                      ],
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Decorative line
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          const SizedBox(height: 16),

          // Letter content
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.8,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              const Icon(
                Icons.favorite,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(likes),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
              const SizedBox(width: 4),
              Text(
                _formatCount(comments),
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.bookmark_border,
                size: 20,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Attachment Button Widget
class AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AttachmentButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
