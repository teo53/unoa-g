import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// 팬 프로필 편집 화면
/// - 아바타 변경
/// - 닉네임 편집
/// - 소개글 편집
class FanProfileEditScreen extends ConsumerStatefulWidget {
  const FanProfileEditScreen({super.key});

  @override
  ConsumerState<FanProfileEditScreen> createState() =>
      _FanProfileEditScreenState();
}

class _FanProfileEditScreenState extends ConsumerState<FanProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  String? _avatarUrl;
  bool _hasChanges = false;
  bool _showBirthday = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _avatarUrl = profile?.avatarUrl;
    _showBirthday = profile?.showBirthday ?? false;
    _nameController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _changeAvatar() {
    // 데모 모드: picsum random seed 변경
    final random = Random();
    final seed = random.nextInt(1000);
    setState(() {
      _avatarUrl = 'https://picsum.photos/seed/fan_$seed/200';
      _hasChanges = true;
    });
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요')),
      );
      return;
    }

    final notifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);

    if (authState is AuthDemoMode) {
      notifier.updateDemoProfile(
        displayName: name,
        avatarUrl: _avatarUrl,
        bio: _bioController.text.trim(),
        showBirthday: _showBirthday,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필이 저장되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            size: 20,
          ),
        ),
        title: Text(
          '프로필 편집',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _hasChanges ? _saveProfile : null,
            child: Text(
              '저장',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _hasChanges
                    ? AppColors.primary600
                    : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: GestureDetector(
                onTap: _changeAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: _avatarUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                                  child: const Icon(Icons.person, size: 48),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                                  child: const Icon(Icons.person, size: 48),
                                ),
                              )
                            : Container(
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                                child: Icon(
                                  Icons.person,
                                  size: 48,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[400],
                                ),
                              ),
                      ),
                    ),
                    // Camera icon overlay
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: TextButton(
                onPressed: _changeAvatar,
                child: Text(
                  '프로필 사진 변경',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Nickname field
            _FieldLabel(label: '닉네임', isDark: isDark),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _nameController,
              isDark: isDark,
              hintText: '채팅방에 표시될 이름',
              maxLength: 20,
            ),

            const SizedBox(height: 24),

            // Bio field
            _FieldLabel(label: '소개글', isDark: isDark),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _bioController,
              isDark: isDark,
              hintText: '자기소개를 입력하세요 (선택)',
              maxLength: 100,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Birthday visibility section
            _FieldLabel(label: '생년월일', isDark: isDark),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.read(currentProfileProvider)?.dateOfBirth != null
                        ? _formatDate(
                            ref.read(currentProfileProvider)!.dateOfBirth!)
                        : '설정되지 않음',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          ref.read(currentProfileProvider)?.dateOfBirth != null
                              ? (isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight)
                              : (isDark
                                  ? AppColors.textSubDark
                                  : AppColors.textSubLight),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '프로필에 생년월일 공개',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight,
                        ),
                      ),
                      Switch(
                        value: _showBirthday,
                        onChanged: (value) {
                          setState(() {
                            _showBirthday = value;
                            _hasChanges = true;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Info note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '변경한 프로필은 구독 중인 모든 채팅방에 반영됩니다.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
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
}

/// Field label widget
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _FieldLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
      ),
    );
  }
}

/// Styled text field matching app design
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String hintText;
  final int? maxLength;
  final int maxLines;

  const _StyledTextField({
    required this.controller,
    required this.isDark,
    required this.hintText,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        counterStyle: TextStyle(
          fontSize: 11,
          color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
        ),
      ),
    );
  }
}
