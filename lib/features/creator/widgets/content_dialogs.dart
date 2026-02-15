import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/creator_content.dart';
import 'content_edit_dialogs.dart';
import 'content_shared_widgets.dart';

/// 프로필 편집 다이얼로그
void showProfileEditDialog(
  BuildContext context, {
  required bool isDark,
  required String currentName,
  String? currentBio,
  required Color themeColor,
  required Function(String displayName, String? bio) onSave,
}) {
  final nameController = TextEditingController(text: currentName);
  final bioController = TextEditingController(text: currentBio ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로필 편집',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color:
                  isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '소개',
              hintText: '팬에게 보여질 소개글',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  onSave(
                    nameController.text,
                    bioController.text.isNotEmpty ? bioController.text : null,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '저장',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 테마 색상 선택 다이얼로그
void showThemeColorDialog(
  BuildContext context, {
  required bool isDark,
  required int currentIndex,
  required Function(int index) onColorSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        int selected = currentIndex;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '테마 색상',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '선택한 색상은 팬이 보는 프로필에 적용됩니다.',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(ArtistThemeColors.count, (i) {
                  final isSelected = i == selected;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() => selected = i);
                      onColorSelected(i);
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ArtistThemeColors.presets[i],
                            border: isSelected
                                ? Border.all(
                                    color:
                                        isDark ? Colors.white : Colors.black,
                                    width: 3)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 24)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ArtistThemeColors.names[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? ArtistThemeColors.presets[i]
                                : (isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ),
  );
}

/// 하이라이트 편집 다이얼로그
void showHighlightEditDialog(
  BuildContext context, {
  required bool isDark,
  required Color themeColor,
  required List<CreatorHighlight> currentHighlights,
  required Function(String highlightId) onToggleRing,
  required Function(String highlightId) onDelete,
  required VoidCallback onAdd,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '하이라이트 관리',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: Icon(Icons.add, size: 18, color: themeColor),
                    label: Text('추가', style: TextStyle(color: themeColor)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (currentHighlights.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      '하이라이트가 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ),
                )
              else
                ...currentHighlights.map((h) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: h.hasRing ? themeColor : Colors.grey,
                            width: h.hasRing ? 2 : 1,
                          ),
                        ),
                        child: Icon(h.icon,
                            size: 20,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      title: Text(
                        h.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.text,
                        ),
                      ),
                      subtitle: Text(
                        h.hasRing ? '링 활성' : '링 비활성',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              h.hasRing
                                  ? Icons.circle
                                  : Icons.circle_outlined,
                              color: h.hasRing ? themeColor : Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              onToggleRing(h.id);
                              setModalState(() {});
                            },
                            tooltip: '링 토글',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () {
                              onDelete(h.id);
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
  );
}

/// 하이라이트 추가 다이얼로그
void showAddHighlightDialog(
  BuildContext context, {
  required bool isDark,
  required Color themeColor,
  required Function(CreatorHighlight highlight) onAdd,
}) {
  final labelController = TextEditingController();
  final iconOptions = <MapEntry<String, IconData>>[
    const MapEntry('패션', Icons.checkroom),
    const MapEntry('음악', Icons.music_note),
    const MapEntry('카메라', Icons.camera_alt),
    const MapEntry('영상', Icons.videocam),
    const MapEntry('별', Icons.star),
    const MapEntry('하트', Icons.favorite),
    const MapEntry('그리기', Icons.brush),
    const MapEntry('마이크', Icons.mic),
  ];
  int selectedIconIndex = 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '하이라이트 추가',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: '라벨',
                hintText: '예: Today\'s OOTD',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('아이콘 선택',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(iconOptions.length, (i) {
                final isSelected = i == selectedIconIndex;
                return GestureDetector(
                  onTap: () => setModalState(() => selectedIconIndex = i),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? themeColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? themeColor
                            : (isDark
                                ? Colors.grey[600]!
                                : Colors.grey[300]!),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      iconOptions[i].value,
                      size: 22,
                      color: isSelected
                          ? themeColor
                          : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (labelController.text.isNotEmpty) {
                    final id =
                        DateTime.now().millisecondsSinceEpoch.toString();
                    onAdd(
                      CreatorHighlight(
                        id: id,
                        label: labelController.text,
                        icon: iconOptions[selectedIconIndex].value,
                        hasRing: true,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '추가',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 직캠 관리 시트
void showFancamManageSheet(
  BuildContext context, {
  required bool isDark,
  required List<CreatorFancam> fancams,
  required Function(CreatorFancam) onEdit,
  required Function(CreatorFancam) onDelete,
  required Function(CreatorFancam) onTogglePin,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => ManageListSheet<CreatorFancam>(
      title: '직캠 관리',
      items: fancams,
      itemTitle: (f) => f.title,
      itemSubtitle: (f) =>
          f.isPinned ? '\u{1F4CC} 고정됨' : f.formattedViewCount,
      onEdit: (f) {
        Navigator.pop(context);
        showFancamEditDialog(context, isDark, fancam: f, onSave: (updated) {
          onEdit(updated);
        });
      },
      onDelete: (f) {
        showDeleteConfirmDialog(context, itemType: '직캠', itemName: f.title,
            onConfirm: () {
          onDelete(f);
        });
      },
      onTogglePin: (f) {
        onTogglePin(f);
        Navigator.pop(context);
      },
      isDark: isDark,
    ),
  );
}

/// 드롭 관리 시트
void showDropManageSheet(
  BuildContext context, {
  required bool isDark,
  required List<CreatorDrop> drops,
  required Function(CreatorDrop) onEdit,
  required Function(CreatorDrop) onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => ManageListSheet<CreatorDrop>(
      title: '드롭 관리',
      items: drops,
      itemTitle: (d) => d.name,
      itemSubtitle: (d) => d.formattedPrice,
      onEdit: (d) {
        Navigator.pop(context);
        showDropEditDialog(context, isDark, drop: d, onSave: (updated) {
          onEdit(updated);
        });
      },
      onDelete: (d) {
        showDeleteConfirmDialog(context, itemType: '드롭', itemName: d.name,
            onConfirm: () {
          onDelete(d);
        });
      },
      isDark: isDark,
    ),
  );
}

/// 이벤트 관리 시트
void showEventManageSheet(
  BuildContext context, {
  required bool isDark,
  required List<CreatorEvent> events,
  required Function(CreatorEvent) onEdit,
  required Function(CreatorEvent) onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => ManageListSheet<CreatorEvent>(
      title: '이벤트 관리',
      items: events,
      itemTitle: (e) => e.title,
      itemSubtitle: (e) => '${e.formattedDate} \u00B7 ${e.location}',
      onEdit: (e) {
        Navigator.pop(context);
        showEventEditDialog(context, isDark, event: e, onSave: (updated) {
          onEdit(updated);
        });
      },
      onDelete: (e) {
        showDeleteConfirmDialog(context, itemType: '이벤트', itemName: e.title,
            onConfirm: () {
          onDelete(e);
        });
      },
      isDark: isDark,
    ),
  );
}

/// 변경사항 취소 확인 다이얼로그
void showContentDiscardDialog(
  BuildContext context, {
  required bool isDark,
}) {
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
          child: const Text('나가기', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
}
