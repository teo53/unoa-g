import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/demo_config.dart';
import '../../data/models/creator_content.dart';
import '../../providers/auth_provider.dart';
import '../../providers/creator_content_provider.dart';
import 'widgets/content_edit_dialogs.dart';

/// 크리에이터 콘텐츠 관리 화면 (WYSIWYG)
///
/// 팬이 보는 아티스트 프로필과 동일한 레이아웃을 보여주되,
/// 편집 가능한 섹션에 편집 오버레이 버튼을 올려 인라인 편집 가능.
class CreatorContentScreen extends ConsumerStatefulWidget {
  const CreatorContentScreen({super.key});

  @override
  ConsumerState<CreatorContentScreen> createState() =>
      _CreatorContentScreenState();
}

class _CreatorContentScreenState extends ConsumerState<CreatorContentScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentState = ref.watch(creatorContentProvider);
    final profile = ref.watch(currentProfileProvider);
    final creatorName = profile?.displayName ?? DemoConfig.demoCreatorName;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // 편집 모드 배너
          _buildEditModeBanner(isDark),

          // WYSIWYG 콘텐츠
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 커버 이미지 + 이름 + 그룹
                  _EditableSection(
                    label: '커버',
                    onEdit: () {
                      // 커버 이미지 변경 (추후 구현)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('커버 이미지 변경은 곧 지원됩니다')),
                      );
                    },
                    child: _buildCoverSection(isDark, creatorName),
                  ),

                  // 2. 하이라이트
                  _EditableSection(
                    label: '하이라이트',
                    onEdit: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('하이라이트 편집은 곧 지원됩니다')),
                      );
                    },
                    child: _buildHighlightsSection(isDark),
                  ),

                  // 3. 소셜 링크
                  _EditableSection(
                    label: '소셜',
                    onEdit: () {
                      showSocialLinksEditDialog(
                        context,
                        isDark,
                        links: contentState.socialLinks,
                        onSave: (links) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .updateSocialLinks(links);
                        },
                      );
                    },
                    child: _buildSocialLinksSection(isDark, contentState.socialLinks),
                  ),

                  // 4. 액션 버튼 (잠금)
                  _LockedSection(
                    tooltipMessage: '팬 전용 기능',
                    child: _buildActionButtons(isDark),
                  ),

                  // 5. 서포터 랭킹 (잠금)
                  _LockedSection(
                    tooltipMessage: '팬별 개인 데이터',
                    child: _buildSupporterRanking(isDark),
                  ),

                  // 6. 직캠
                  _EditableSection(
                    label: '직캠',
                    canAdd: true,
                    onEdit: () {
                      _showFancamManageSheet(isDark, contentState.fancams);
                    },
                    onAdd: () {
                      showFancamEditDialog(
                        context,
                        isDark,
                        onSave: (fancam) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .addFancam(fancam);
                        },
                      );
                    },
                    child: _buildFancamsSection(isDark, contentState.fancams),
                  ),

                  // 7. 드롭
                  _EditableSection(
                    label: '드롭',
                    canAdd: true,
                    onEdit: () {
                      _showDropManageSheet(isDark, contentState.drops);
                    },
                    onAdd: () {
                      showDropEditDialog(
                        context,
                        isDark,
                        onSave: (drop) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .addDrop(drop);
                        },
                      );
                    },
                    child: _buildDropsSection(isDark, contentState.drops),
                  ),

                  // 8. 이벤트
                  _EditableSection(
                    label: '이벤트',
                    canAdd: true,
                    onEdit: () {
                      _showEventManageSheet(isDark, contentState.events);
                    },
                    onAdd: () {
                      showEventEditDialog(
                        context,
                        isDark,
                        onSave: (event) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .addEvent(event);
                        },
                      );
                    },
                    child: _buildEventsSection(isDark, contentState.events),
                  ),

                  // 9. 탭바 + 피드 (잠금)
                  _LockedSection(
                    tooltipMessage: '피드는 채팅에서 관리됩니다',
                    child: _buildFeedPreview(isDark),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 편집 모드 배너 =====

  Widget _buildEditModeBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary600,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final hasChanges = ref.read(creatorContentProvider).hasChanges;
              if (hasChanges) {
                _showDiscardDialog(isDark);
              } else {
                context.pop();
              }
            },
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '편집 모드',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '팬에게 보이는 화면과 동일합니다',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 저장 버튼
          Consumer(
            builder: (context, ref, _) {
              final hasChanges = ref.watch(creatorContentProvider).hasChanges;
              return GestureDetector(
                onTap: hasChanges
                    ? () async {
                        await ref
                            .read(creatorContentProvider.notifier)
                            .saveAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('저장되었습니다')),
                          );
                        }
                      }
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: hasChanges
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '저장',
                    style: TextStyle(
                      color: hasChanges
                          ? AppColors.primary600
                          : Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== 섹션 빌더 (팬 프로필 레이아웃 복제) =====

  Widget _buildCoverSection(bool isDark, String creatorName) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary600,
            AppColors.primary500,
          ],
        ),
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          // 프로필 아바타
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 48, color: Colors.white60),
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
                    Icon(Icons.verified, size: 22, color: AppColors.verified),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Underground Idol Group',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildBadge('주간랭킹: 1위 +2', Icons.trending_up, isDark),
                    const SizedBox(width: 8),
                    _buildBadge('팬 52만', Icons.people, isDark),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary600,
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

  Widget _buildHighlightsSection(bool isDark) {
    final highlights = [
      _HighlightData("Today's OOTD", Icons.checkroom, true),
      _HighlightData('Rehearsal', Icons.music_note, false),
      _HighlightData('Q&A', Icons.camera_alt, false),
      _HighlightData('V-log', Icons.videocam, false),
    ];

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
                          ? AppColors.primary500
                          : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      width: h.hasRing ? 2 : 1,
                    ),
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                  ),
                  child: Icon(h.icon, size: 24,
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

  Widget _buildSocialLinksSection(bool isDark, SocialLinks links) {
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
            _socialIcon('IG', AppColors.primary500, isDark),
          if (links.youtube != null && links.youtube!.isNotEmpty) ...[
            const SizedBox(width: 12),
            _socialIconWidget(Icons.play_circle_outline, AppColors.primary500, isDark),
          ],
          if (links.tiktok != null && links.tiktok!.isNotEmpty) ...[
            const SizedBox(width: 12),
            _socialIcon('TT', AppColors.primary500, isDark),
          ],
          if (links.twitter != null && links.twitter!.isNotEmpty) ...[
            const SizedBox(width: 12),
            _socialIcon('X', AppColors.primary500, isDark),
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

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(Icons.chat_bubble_outline, 'DM', false, isDark),
          _actionButton(Icons.card_giftcard, '드롭', false, isDark),
          _actionButton(Icons.groups, '이벤트', true, isDark),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, bool isPrimary, bool isDark) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isPrimary
                ? AppColors.primary600
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

  Widget _buildSupporterRanking(bool isDark) {
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
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.emoji_events_outlined,
                color: AppColors.primary500, size: 20),
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
                  'Gold Member • 상위 5%',
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

  Widget _buildFancamsSection(bool isDark, List<CreatorFancam> fancams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('아티스트 직캠', '${fancams.length}개', isDark),
        if (fancams.isEmpty)
          _emptyPlaceholder('직캠을 추가하세요', Icons.videocam_outlined, isDark)
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: fancams.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildFancamCard(fancams[i], isDark),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFancamCard(CreatorFancam fancam, bool isDark) {
    return GestureDetector(
      onTap: () {
        showFancamEditDialog(
          context,
          isDark,
          fancam: fancam,
          onSave: (updated) {
            ref.read(creatorContentProvider.notifier).updateFancam(updated);
          },
        );
      },
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: fancam.thumbnailUrl,
                    width: 220,
                    height: 130,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: const Icon(Icons.videocam, size: 40),
                    ),
                  ),
                ),
                // Play button overlay
                const Positioned.fill(
                  child: Center(
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.red,
                      child:
                          Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                // Pinned badge
                if (fancam.isPinned)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text('고정됨',
                              style:
                                  TextStyle(fontSize: 9, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                // View count
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fancam.formattedViewCount,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                fancam.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropsSection(bool isDark, List<CreatorDrop> drops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('최신 드롭 (Drops)', '${drops.length}개', isDark),
        if (drops.isEmpty)
          _emptyPlaceholder('드롭을 추가하세요', Icons.card_giftcard_outlined, isDark)
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: drops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildDropCard(drops[i], isDark),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropCard(CreatorDrop drop, bool isDark) {
    return GestureDetector(
      onTap: () {
        showDropEditDialog(
          context,
          isDark,
          drop: drop,
          onSave: (updated) {
            ref.read(creatorContentProvider.notifier).updateDrop(updated);
          },
        );
      },
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  child: drop.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CachedNetworkImage(
                            imageUrl: drop.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.checkroom, size: 40,
                          color: isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
                if (drop.isSoldOut)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('SOLD OUT',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  )
                else if (drop.isNew)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('NEW',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                drop.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.text,
                  decoration:
                      drop.isSoldOut ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                drop.formattedPrice,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: drop.isSoldOut
                      ? Colors.grey
                      : AppColors.primary500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection(bool isDark, List<CreatorEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('다가오는 이벤트', '${events.length}개', isDark),
        if (events.isEmpty)
          _emptyPlaceholder('이벤트를 추가하세요', Icons.event_outlined, isDark)
        else
          ...events.map((event) => _buildEventCard(event, isDark)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEventCard(CreatorEvent event, bool isDark) {
    return GestureDetector(
      onTap: () {
        showEventEditDialog(
          context,
          isDark,
          event: event,
          onSave: (updated) {
            ref.read(creatorContentProvider.notifier).updateEvent(updated);
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                event.isOffline ? Icons.location_on : Icons.videocam,
                color: AppColors.primary600,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: event.isOffline
                              ? Colors.grey[200]
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: event.isOffline
                                ? Colors.grey[600]
                                : AppColors.primary600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                  ),
                  Text(
                    event.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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

  Widget _buildFeedPreview(bool isDark) {
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
              _tabPreview('하이라이트', true, isDark),
              _tabPreview('공지사항', false, isDark),
              _tabPreview('오타 레터', false, isDark),
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
                backgroundColor: AppColors.primary500,
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

  Widget _tabPreview(String label, bool isActive, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary500 : Colors.transparent,
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
                  ? AppColors.primary500
                  : (isDark ? Colors.grey[500] : Colors.grey[500]),
            ),
          ),
        ),
      ),
    );
  }

  // ===== 공통 헬퍼 =====

  Widget _sectionHeader(String title, String count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
          Icon(icon, size: 32,
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
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

  // ===== 관리 시트 (목록에서 편집/삭제) =====

  void _showFancamManageSheet(bool isDark, List<CreatorFancam> fancams) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ManageListSheet<CreatorFancam>(
        title: '직캠 관리',
        items: fancams,
        itemTitle: (f) => f.title,
        itemSubtitle: (f) => f.isPinned ? '📌 고정됨' : f.formattedViewCount,
        onEdit: (f) {
          Navigator.pop(context);
          showFancamEditDialog(context, isDark, fancam: f, onSave: (updated) {
            ref.read(creatorContentProvider.notifier).updateFancam(updated);
          });
        },
        onDelete: (f) {
          showDeleteConfirmDialog(context,
              itemType: '직캠', itemName: f.title, onConfirm: () {
            ref.read(creatorContentProvider.notifier).deleteFancam(f.id);
          });
        },
        onTogglePin: (f) {
          ref.read(creatorContentProvider.notifier).toggleFancamPin(f.id);
          Navigator.pop(context);
        },
        isDark: isDark,
      ),
    );
  }

  void _showDropManageSheet(bool isDark, List<CreatorDrop> drops) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ManageListSheet<CreatorDrop>(
        title: '드롭 관리',
        items: drops,
        itemTitle: (d) => d.name,
        itemSubtitle: (d) => d.formattedPrice,
        onEdit: (d) {
          Navigator.pop(context);
          showDropEditDialog(context, isDark, drop: d, onSave: (updated) {
            ref.read(creatorContentProvider.notifier).updateDrop(updated);
          });
        },
        onDelete: (d) {
          showDeleteConfirmDialog(context,
              itemType: '드롭', itemName: d.name, onConfirm: () {
            ref.read(creatorContentProvider.notifier).deleteDrop(d.id);
          });
        },
        isDark: isDark,
      ),
    );
  }

  void _showEventManageSheet(bool isDark, List<CreatorEvent> events) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ManageListSheet<CreatorEvent>(
        title: '이벤트 관리',
        items: events,
        itemTitle: (e) => e.title,
        itemSubtitle: (e) => '${e.formattedDate} · ${e.location}',
        onEdit: (e) {
          Navigator.pop(context);
          showEventEditDialog(context, isDark, event: e, onSave: (updated) {
            ref.read(creatorContentProvider.notifier).updateEvent(updated);
          });
        },
        onDelete: (e) {
          showDeleteConfirmDialog(context,
              itemType: '이벤트', itemName: e.title, onConfirm: () {
            ref.read(creatorContentProvider.notifier).deleteEvent(e.id);
          });
        },
        isDark: isDark,
      ),
    );
  }

  void _showDiscardDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: const Text('변경사항 취소'),
        content: const Text('저장하지 않은 변경사항이 있습니다. 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('계속 편집'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
            child: Text('나가기', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ===== 래퍼 위젯 =====

/// 편집 가능한 섹션 래퍼 — 편집/추가 오버레이 버튼 표시
class _EditableSection extends StatelessWidget {
  final Widget child;
  final String? label;
  final VoidCallback onEdit;
  final bool canAdd;
  final VoidCallback? onAdd;

  const _EditableSection({
    required this.child,
    required this.onEdit,
    this.label,
    this.canAdd = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // 편집 버튼
        Positioned(
          top: 8,
          right: canAdd ? 48 : 8,
          child: _overlayButton(
            icon: Icons.edit,
            label: label,
            onTap: onEdit,
          ),
        ),
        // 추가 버튼
        if (canAdd && onAdd != null)
          Positioned(
            top: 8,
            right: 8,
            child: _overlayButton(
              icon: Icons.add,
              onTap: onAdd!,
            ),
          ),
        // 편집 가능 테두리
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _overlayButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 10 : 8,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.primary600),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 잠금 섹션 래퍼 — 반투명 + 잠금 아이콘
class _LockedSection extends StatelessWidget {
  final Widget child;
  final String? tooltipMessage;

  const _LockedSection({
    required this.child,
    this.tooltipMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.45,
          child: IgnorePointer(child: child),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Tooltip(
            message: tooltipMessage ?? '편집 불가',
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 관리 시트 (목록에서 편집/삭제)
class _ManageListSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemTitle;
  final String Function(T) itemSubtitle;
  final void Function(T) onEdit;
  final void Function(T) onDelete;
  final void Function(T)? onTogglePin;
  final bool isDark;

  const _ManageListSheet({
    required this.title,
    required this.items,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.onEdit,
    required this.onDelete,
    this.onTogglePin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(
              child: Text(
                '항목이 없습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            )
          else
            ...items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    itemTitle(item),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.text,
                    ),
                  ),
                  subtitle: Text(
                    itemSubtitle(item),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onTogglePin != null)
                        IconButton(
                          icon: const Icon(Icons.push_pin_outlined, size: 20),
                          onPressed: () => onTogglePin!(item),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => onEdit(item),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 20, color: AppColors.danger),
                        onPressed: () => onDelete(item),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

/// 하이라이트 데이터 모델
class _HighlightData {
  final String label;
  final IconData icon;
  final bool hasRing;

  _HighlightData(this.label, this.icon, this.hasRing);
}
