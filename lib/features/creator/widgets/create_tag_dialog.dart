import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/fan_tag.dart';

/// 태그 생성 다이얼로그
/// 이름 입력 + 색상 선택 (8색 팔레트)
class CreateTagDialog extends StatefulWidget {
  const CreateTagDialog({super.key});

  /// 결과: {'name': String, 'color': String} 또는 null (취소)
  static Future<Map<String, String>?> show(BuildContext context) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreateTagDialog(),
    );
  }

  @override
  State<CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<CreateTagDialog> {
  final _nameController = TextEditingController();
  String _selectedColor = FanTag.colorPalette[0];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '새 태그 만들기',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그 이름 입력
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 20,
              decoration: InputDecoration(
                hintText: '태그 이름',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
                filled: true,
                fillColor:
                    isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '태그 이름을 입력해주세요';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // 색상 선택
            Text(
              '색상',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: FanTag.colorPalette.map((hex) {
                final color = _parseColor(hex);
                final isSelected = hex == _selectedColor;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: isDark ? Colors.white : Colors.black87,
                              width: 2.5,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // 미리보기
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _parseColor(_selectedColor).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _parseColor(_selectedColor).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _nameController.text.isEmpty ? '미리보기' : _nameController.text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _parseColor(_selectedColor),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '취소',
            style: TextStyle(
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text.trim(),
                'color': _selectedColor,
              });
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('만들기'),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    try {
      final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
      return Color(value | 0xFF000000);
    } catch (_) {
      return Colors.grey;
    }
  }
}
