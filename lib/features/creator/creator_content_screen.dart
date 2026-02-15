import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/demo_config.dart';
import '../../data/models/creator_content.dart';
import '../../providers/auth_provider.dart';
import '../../providers/creator_content_provider.dart';
import 'widgets/content_edit_dialogs.dart';
import 'widgets/content_item_sections.dart';
import 'widgets/content_shared_widgets.dart';
import 'widgets/content_dialogs.dart';
import 'widgets/content_profile_sections.dart';

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
    final themeColor =
        ArtistThemeColors.fromIndex(profile?.themeColorIndex ?? 0);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
                  EditableSection(
                    label: '커버',
                    onEdit: () {
                      showProfileEditDialog(
                        context,
                        isDark: isDark,
                        currentName: creatorName,
                        currentBio: profile?.bio,
                        themeColor: themeColor,
                        onSave: (displayName, bio) {
                          ref.read(authProvider.notifier).updateDemoProfile(
                                displayName: displayName,
                                bio: bio,
                              );
                        },
                      );
                    },
                    child: _buildCoverSection(
                        isDark, creatorName, themeColor, profile),
                  ),

                  // 2. 하이라이트
                  EditableSection(
                    label: '하이라이트',
                    onEdit: () {
                      showHighlightEditDialog(
                        context,
                        isDark: isDark,
                        themeColor: themeColor,
                        currentHighlights: contentState.highlights,
                        onToggleRing: (id) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .toggleHighlightRing(id);
                        },
                        onDelete: (id) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .deleteHighlight(id);
                        },
                        onAdd: () {
                          showAddHighlightDialog(
                            context,
                            isDark: isDark,
                            themeColor: themeColor,
                            onAdd: (highlight) {
                              ref
                                  .read(creatorContentProvider.notifier)
                                  .addHighlight(highlight);
                            },
                          );
                        },
                      );
                    },
                    child: _buildHighlightsSection(
                        isDark, themeColor, contentState.highlights),
                  ),

                  // 3. 소셜 링크
                  EditableSection(
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
                    child: _buildSocialLinksSection(
                        isDark, contentState.socialLinks, themeColor),
                  ),

                  // 4. 액션 버튼 (잠금)
                  LockedSection(
                    tooltipMessage: '팬 전용 기능',
                    child: _buildActionButtons(isDark, themeColor),
                  ),

                  // 5. 서포터 랭킹 (잠금)
                  LockedSection(
                    tooltipMessage: '팬별 개인 데이터',
                    child: _buildSupporterRanking(isDark, themeColor),
                  ),

                  // 6. 직캠
                  EditableSection(
                    label: '직캠',
                    canAdd: true,
                    onEdit: () {
                      showFancamManageSheet(
                        context,
                        isDark: isDark,
                        fancams: contentState.fancams,
                        onEdit: (fancam) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .updateFancam(fancam);
                        },
                        onDelete: (fancam) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .deleteFancam(fancam.id);
                        },
                        onTogglePin: (fancam) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .toggleFancamPin(fancam.id);
                        },
                      );
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
                    child: ContentFancamsSection(
                      isDark: isDark,
                      fancams: contentState.fancams,
                      themeColor: themeColor,
                      onFancamTap: (fancam) {
                        showFancamEditDialog(
                          context,
                          isDark,
                          fancam: fancam,
                          onSave: (updated) {
                            ref
                                .read(creatorContentProvider.notifier)
                                .updateFancam(updated);
                          },
                        );
                      },
                    ),
                  ),

                  // 7. 드롭
                  EditableSection(
                    label: '드롭',
                    canAdd: true,
                    onEdit: () {
                      showDropManageSheet(
                        context,
                        isDark: isDark,
                        drops: contentState.drops,
                        onEdit: (drop) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .updateDrop(drop);
                        },
                        onDelete: (drop) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .deleteDrop(drop.id);
                        },
                      );
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
                    child: ContentDropsSection(
                      isDark: isDark,
                      drops: contentState.drops,
                      themeColor: themeColor,
                      onDropTap: (drop) {
                        showDropEditDialog(
                          context,
                          isDark,
                          drop: drop,
                          onSave: (updated) {
                            ref
                                .read(creatorContentProvider.notifier)
                                .updateDrop(updated);
                          },
                        );
                      },
                    ),
                  ),

                  // 8. 이벤트
                  EditableSection(
                    label: '이벤트',
                    canAdd: true,
                    onEdit: () {
                      showEventManageSheet(
                        context,
                        isDark: isDark,
                        events: contentState.events,
                        onEdit: (event) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .updateEvent(event);
                        },
                        onDelete: (event) {
                          ref
                              .read(creatorContentProvider.notifier)
                              .deleteEvent(event.id);
                        },
                      );
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
                    child: ContentEventsSection(
                      isDark: isDark,
                      events: contentState.events,
                      themeColor: themeColor,
                      onEventTap: (event) {
                        showEventEditDialog(
                          context,
                          isDark,
                          event: event,
                          onSave: (updated) {
                            ref
                                .read(creatorContentProvider.notifier)
                                .updateEvent(updated);
                          },
                        );
                      },
                    ),
                  ),

                  // 9. 탭바 + 피드 (잠금)
                  LockedSection(
                    tooltipMessage: '피드는 채팅에서 관리됩니다',
                    child: _buildFeedPreview(isDark, themeColor),
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
                showContentDiscardDialog(context, isDark: isDark);
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
                      color: hasChanges ? AppColors.primary600 : Colors.white60,
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

  Widget _buildCoverSection(
      bool isDark, String creatorName, Color themeColor, UserProfile? profile) {
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
              onTap: () => showThemeColorDialog(
                context,
                isDark: isDark,
                currentIndex: profile?.themeColorIndex ?? 0,
                onColorSelected: (index) {
                  ref
                      .read(authProvider.notifier)
                      .updateDemoProfile(themeColorIndex: index);
                },
              ),
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
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white24,
                      child: profile?.avatarUrl != null &&
                              profile!.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profile.avatarUrl!,
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
                  onTap: () => showProfileEditDialog(
                    context,
                    isDark: isDark,
                    currentName: creatorName,
                    currentBio: profile?.bio,
                    themeColor: themeColor,
                    onSave: (displayName, bio) {
                      ref.read(authProvider.notifier).updateDemoProfile(
                            displayName: displayName,
                            bio: bio,
                          );
                    },
                  ),
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
                          profile.bio!,
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

  Widget _buildHighlightsSection(
      bool isDark, Color themeColor, List<CreatorHighlight> highlights) {
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

  Widget _buildSocialLinksSection(
      bool isDark, SocialLinks links, Color themeColor) {
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

  Widget _buildActionButtons(bool isDark, Color themeColor) {
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

  Widget _buildSupporterRanking(bool isDark, Color themeColor) {
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


  Widget _buildFeedPreview(bool isDark, Color themeColor) {
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

  // ===== 공통 헬퍼 =====

  Widget _sectionHeader(
      String title, String count, bool isDark, Color themeColor) {
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
              color: themeColor,
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


  // ===== 아바타 선택 =====

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (image != null) {
      // In demo mode, use the local path as avatar URL
      ref.read(authProvider.notifier).updateDemoProfile(avatarUrl: image.path);
    }
  }

}

