import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

/// Fan birthday registration screen.
///
/// Privacy: Only month/day stored (no year).
/// Consent: Explicit toggle with timestamp + privacy notice.
class BirthdaySettingsScreen extends ConsumerStatefulWidget {
  final String channelId;
  final int? initialMonth;
  final int? initialDay;
  final bool initialVisible;

  const BirthdaySettingsScreen({
    super.key,
    required this.channelId,
    this.initialMonth,
    this.initialDay,
    this.initialVisible = false,
  });

  @override
  ConsumerState<BirthdaySettingsScreen> createState() => _BirthdaySettingsScreenState();
}

class _BirthdaySettingsScreenState extends ConsumerState<BirthdaySettingsScreen> {
  late int _selectedMonth;
  late int _selectedDay;
  late bool _isVisible;
  bool _isSaving = false;
  bool _hasChanges = false;

  static const _monthNames = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ];

  static const _daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth ?? 1;
    _selectedDay = widget.initialDay ?? 1;
    _isVisible = widget.initialVisible;
  }

  int get _maxDay => _daysInMonth[_selectedMonth - 1];

  void _onMonthChanged(int month) {
    setState(() {
      _selectedMonth = month;
      if (_selectedDay > _maxDay) {
        _selectedDay = _maxDay;
      }
      _hasChanges = true;
    });
  }

  void _onDayChanged(int day) {
    setState(() {
      _selectedDay = day;
      _hasChanges = true;
    });
  }

  void _onVisibilityChanged(bool visible) {
    setState(() {
      _isVisible = visible;
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      if (AppConfig.enableDemoMode) {
        // Demo mode: simulate save
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // Production: upsert to fan_celebrations table
        final profile = ref.read(currentProfileProvider);
        final userId = profile?.id ?? '';
        if (userId.isEmpty) throw Exception('User not authenticated');

        await Supabase.instance.client.from('fan_celebrations').upsert(
          {
            'user_id': userId,
            'channel_id': widget.channelId,
            'birth_month': _selectedMonth,
            'birth_day': _selectedDay,
            'birthday_visible': _isVisible,
            'visibility_consent_at':
                _isVisible ? DateTime.now().toUtc().toIso8601String() : null,
          },
          onConflict: 'user_id,channel_id',
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('생일 정보가 저장되었습니다')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  Future<void> _deleteBirthday() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('생일 정보 삭제'),
        content: const Text('등록된 생일 정보를 삭제하시겠습니까?\n삭제 후에는 아티스트에게 생일 축하 메시지를 받을 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        if (!AppConfig.enableDemoMode) {
          final profile = ref.read(currentProfileProvider);
          final userId = profile?.id ?? '';
          if (userId.isNotEmpty) {
            await Supabase.instance.client
                .from('fan_celebrations')
                .delete()
                .eq('user_id', userId)
                .eq('channel_id', widget.channelId);
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('생일 정보가 삭제되었습니다')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      showStatusBar: true,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '생일 등록',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Birthday Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary500.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cake_outlined,
                        size: 40,
                        color: AppColors.primary500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '생일을 등록하면 아티스트에게\n특별한 축하 메시지를 받을 수 있어요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Month/Day Picker Section
                  _SectionLabel(title: '생일 (월/일)', isDark: isDark),
                  const SizedBox(height: 12),
                  _buildDatePicker(isDark),
                  const SizedBox(height: 24),

                  // Visibility Toggle
                  _SectionLabel(title: '공개 설정', isDark: isDark),
                  const SizedBox(height: 12),
                  _buildVisibilityToggle(isDark),
                  const SizedBox(height: 24),

                  // Privacy Notice
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceAltDark
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '생일 정보는 해당 아티스트에게만 공개되며, 언제든 설정에서 삭제할 수 있습니다. 생년은 수집하지 않습니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSubDark
                                  : AppColors.textSubLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_hasChanges && !_isSaving) ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '저장하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delete Button
                  if (widget.initialMonth != null)
                    Center(
                      child: TextButton(
                        onPressed: _deleteBirthday,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        child: const Text('생일 정보 삭제'),
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

  Widget _buildDatePicker(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Month picker
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '월',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: List.generate(12, (i) {
                      return DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          _monthNames[i],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) _onMonthChanged(v);
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          // Day picker
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '일',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButton<int>(
                    value: _selectedDay,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: List.generate(_maxDay, (i) {
                      return DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          '${i + 1}일',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMainDark
                                : AppColors.textMainLight,
                          ),
                        ),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) _onDayChanged(v);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '아티스트에게 생일 공개',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '공개 시 아티스트가 생일에 축하 메시지를 보낼 수 있어요',
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
            Switch(
              value: _isVisible,
              onChanged: _onVisibilityChanged,
              activeColor: AppColors.primary600,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionLabel({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
      ),
    );
  }
}
