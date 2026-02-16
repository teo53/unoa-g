import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/demo_config.dart';
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
                    child: ContentCoverSection(
                      isDark: isDark,
                      creatorName: creatorName,
                      themeColor: themeColor,
                      profile: profile,
                      onThemeColorTap: () => showThemeColorDialog(
                        context,
                        isDark: isDark,
                        currentIndex: profile?.themeColorIndex ?? 0,
                        onColorSelected: (index) {
                          ref
                              .read(authProvider.notifier)
                              .updateDemoProfile(themeColorIndex: index);
                        },
                      ),
                      onAvatarTap: _pickAvatar,
                      onProfileEditTap: () => showProfileEditDialog(
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
                    ),
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
                    child: ContentHighlightsSection(
                      isDark: isDark,
                      themeColor: themeColor,
                      highlights: contentState.highlights,
                    ),
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
                    child: ContentSocialLinksSection(
                      isDark: isDark,
                      links: contentState.socialLinks,
                      themeColor: themeColor,
                    ),
                  ),

                  // 4. 액션 버튼 (잠금)
                  LockedSection(
                    tooltipMessage: '팬 전용 기능',
                    child: ContentActionButtons(
                      isDark: isDark,
                      themeColor: themeColor,
                    ),
                  ),

                  // 5. 서포터 랭킹 (잠금)
                  LockedSection(
                    tooltipMessage: '팬별 개인 데이터',
                    child: ContentSupporterRanking(
                      isDark: isDark,
                      themeColor: themeColor,
                    ),
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
                    child: ContentFeedPreview(
                      isDark: isDark,
                      themeColor: themeColor,
                    ),
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
