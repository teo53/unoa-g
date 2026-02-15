import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 편집 가능한 섹션 래퍼 — 편집/추가 오버레이 버튼 표시
class EditableSection extends StatelessWidget {
  final Widget child;
  final String? label;
  final VoidCallback onEdit;
  final bool canAdd;
  final VoidCallback? onAdd;

  const EditableSection({
    super.key,
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
                  style: const TextStyle(
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
class LockedSection extends StatelessWidget {
  final Widget child;
  final String? tooltipMessage;

  const LockedSection({
    super.key,
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
              child:
                  const Icon(Icons.lock_outline, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 관리 시트 (목록에서 편집/삭제)
class ManageListSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemTitle;
  final String Function(T) itemSubtitle;
  final void Function(T) onEdit;
  final void Function(T) onDelete;
  final void Function(T)? onTogglePin;
  final bool isDark;

  const ManageListSheet({
    super.key,
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
                        icon: const Icon(Icons.delete_outline,
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
