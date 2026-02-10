import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/broadcast_message.dart';
import '../../../providers/chat_provider.dart';
import 'full_screen_image_viewer.dart';

/// KakaoTalk-style media gallery sheet with 3 tabs: Photos, Videos, Files.
/// Shows all media from the chat in a grouped, browsable format.
class MediaGallerySheet extends ConsumerStatefulWidget {
  final String channelId;

  const MediaGallerySheet({
    super.key,
    required this.channelId,
  });

  /// Show the media gallery as a full-screen bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String channelId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaGallerySheet(channelId: channelId),
    );
  }

  @override
  ConsumerState<MediaGallerySheet> createState() => _MediaGallerySheetState();
}

class _MediaGallerySheetState extends ConsumerState<MediaGallerySheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(chatProvider(widget.channelId));
    final messages = chatState.messages;

    // Filter media messages
    final photos = messages
        .where((m) =>
            m.messageType == BroadcastMessageType.image && m.mediaUrl != null)
        .toList();
    final videos = messages
        .where((m) =>
            m.messageType == BroadcastMessageType.video && m.mediaUrl != null)
        .toList();
    final files = messages
        .where((m) =>
            m.messageType == BroadcastMessageType.voice && m.mediaUrl != null)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              _buildDragHandle(isDark),

              // Header
              _buildHeader(context, isDark),

              // Tab bar
              _buildTabBar(isDark, photos.length, videos.length, files.length),

              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPhotosGrid(context, isDark, photos),
                    _buildVideosList(context, isDark, videos),
                    _buildFilesList(context, isDark, files),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[600] : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 22,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '미디어 모아보기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(
      bool isDark, int photoCount, int videoCount, int fileCount) {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.primary500,
      unselectedLabelColor:
          isDark ? AppColors.textSubDark : AppColors.textSubLight,
      indicatorColor: AppColors.primary500,
      indicatorWeight: 2.5,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      tabs: [
        Tab(text: '사진 ($photoCount)'),
        Tab(text: '동영상 ($videoCount)'),
        Tab(text: '파일 ($fileCount)'),
      ],
    );
  }

  // =============================================
  // Photos Grid Tab
  // =============================================

  Widget _buildPhotosGrid(
      BuildContext context, bool isDark, List<BroadcastMessage> photos) {
    if (photos.isEmpty) {
      return _buildEmptyState(
        isDark,
        Icons.photo_library_outlined,
        '사진이 없습니다',
      );
    }

    // Group by month
    final grouped = _groupByMonth(photos);

    return ListView.builder(
      padding: const EdgeInsets.all(2),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final entry = grouped.entries.elementAt(groupIndex);
        final monthPhotos = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ),
            // Photo grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: monthPhotos.length,
              itemBuilder: (context, index) {
                final photo = monthPhotos[index];
                return GestureDetector(
                  onTap: () => FullScreenImageViewer.show(
                    context,
                    imageUrl: photo.mediaUrl!,
                    senderName: photo.senderName,
                    date: photo.createdAt,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: CachedNetworkImage(
                      imageUrl: photo.mediaUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // =============================================
  // Videos List Tab
  // =============================================

  Widget _buildVideosList(
      BuildContext context, bool isDark, List<BroadcastMessage> videos) {
    if (videos.isEmpty) {
      return _buildEmptyState(
        isDark,
        Icons.videocam_outlined,
        '동영상이 없습니다',
      );
    }

    final grouped = _groupByMonth(videos);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final entry = grouped.entries.elementAt(groupIndex);
        final monthVideos = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ),
            // Video list
            ...monthVideos
                .map((video) => _buildVideoItem(context, isDark, video)),
          ],
        );
      },
    );
  }

  Widget _buildVideoItem(
      BuildContext context, bool isDark, BroadcastMessage video) {
    final thumbnailUrl =
        video.mediaMetadata?['thumbnail_url'] as String? ?? video.mediaUrl!;
    final duration = video.mediaMetadata?['duration'] as int? ?? 0;

    return InkWell(
      onTap: () {
        final uri = Uri.tryParse(video.mediaUrl!);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Thumbnail with play icon and duration
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: const Icon(Icons.videocam_off, size: 24),
                      ),
                    ),
                    // Play icon overlay
                    Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    // Duration badge
                    if (duration > 0)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Video info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.senderName ?? '알 수 없음',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(video.createdAt),
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
      ),
    );
  }

  // =============================================
  // Files/Voice List Tab
  // =============================================

  Widget _buildFilesList(
      BuildContext context, bool isDark, List<BroadcastMessage> files) {
    if (files.isEmpty) {
      return _buildEmptyState(
        isDark,
        Icons.insert_drive_file_outlined,
        '파일이 없습니다',
      );
    }

    final grouped = _groupByMonth(files);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final entry = grouped.entries.elementAt(groupIndex);
        final monthFiles = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
            ),
            // File list
            ...monthFiles.map((file) => _buildFileItem(context, isDark, file)),
          ],
        );
      },
    );
  }

  Widget _buildFileItem(
      BuildContext context, bool isDark, BroadcastMessage file) {
    final isVoice = file.messageType == BroadcastMessageType.voice;
    final duration = file.mediaMetadata?['duration'] as int? ?? 0;

    return InkWell(
      onTap: () {
        final uri = Uri.tryParse(file.mediaUrl!);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Icon
            CircleAvatar(
              radius: 22,
              backgroundColor: isDark
                  ? AppColors.primary500.withValues(alpha: 0.15)
                  : AppColors.primary100,
              child: Icon(
                isVoice ? Icons.mic : Icons.insert_drive_file_outlined,
                size: 20,
                color: AppColors.primary500,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVoice ? '음성 메시지' : '파일',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        file.senderName ?? '알 수 없음',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                      if (duration > 0) ...[
                        Text(
                          ' · ${_formatDuration(duration)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSubDark
                                : AppColors.textSubLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Date
            Text(
              _formatDate(file.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // Helpers
  // =============================================

  Widget _buildEmptyState(bool isDark, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<BroadcastMessage>> _groupByMonth(
      List<BroadcastMessage> messages) {
    final grouped = <String, List<BroadcastMessage>>{};
    for (final msg in messages) {
      final key = '${msg.createdAt.year}년 ${msg.createdAt.month}월';
      grouped.putIfAbsent(key, () => []).add(msg);
    }
    return grouped;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
