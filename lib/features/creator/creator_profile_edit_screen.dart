import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// 크리에이터 프로필 편집 화면 (풀 커스텀)
/// - 기본 정보: 아바타, 이름, 소개글
/// - 배경 & 테마: 배경 이미지, 테마 색상
/// - 뱃지 & 스타일: 뱃지 스타일, 프로필 레이아웃
/// - 소셜 링크: SNS 링크 관리
class CreatorProfileEditScreen extends ConsumerStatefulWidget {
  const CreatorProfileEditScreen({super.key});

  @override
  ConsumerState<CreatorProfileEditScreen> createState() =>
      _CreatorProfileEditScreenState();
}

class _CreatorProfileEditScreenState
    extends ConsumerState<CreatorProfileEditScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TabController _tabController;
  bool _hasChanges = false;

  // Theme settings
  int _selectedThemeColor = 0;
  int _selectedBadgeStyle = 0;
  int _selectedLayout = 0;

  // Social links
  String _instagramLink = '';
  String _youtubeLink = '';
  String _tiktokLink = '';
  String _twitterLink = '';

  final List<Color> _themeColors = [
    AppColors.primary,
    Colors.pink,
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.orange,
  ];

  final List<String> _themeColorNames = [
    '기본',
    '핑크',
    '블루',
    '퍼플',
    '틸',
    '오렌지',
  ];

  final List<String> _badgeStyles = [
    '기본',
    '골드',
    '다이아몬드',
    '애니메이션',
  ];

  final List<String> _layoutStyles = [
    '기본형',
    '카드형',
    '풀스크린형',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('프로필이 저장되었습니다'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Profile Preview Card
            _buildProfilePreview(isDark, profile),

            // Tab Bar
            _buildTabBar(isDark),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(isDark, profile),
                  _buildThemeTab(isDark),
                  _buildBadgeStyleTab(isDark),
                  _buildSocialLinksTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_hasChanges) {
                _showDiscardDialog(context, isDark);
              } else {
                context.pop();
              }
            },
            icon: Icon(
              Icons.close,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '프로필 편집',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
          TextButton(
            onPressed: _hasChanges ? _saveProfile : null,
            child: Text(
              '저장',
              style: TextStyle(
                color: _hasChanges
                    ? AppColors.primary
                    : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePreview(bool isDark, dynamic profile) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _themeColors[_selectedThemeColor].withValues(alpha: 0.15),
            _themeColors[_selectedThemeColor].withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _themeColors[_selectedThemeColor].withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '미리보기',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _themeColors[_selectedThemeColor],
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: profile?.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: profile!.avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _nameController.text.isEmpty
                                ? '크리에이터 이름'
                                : _nameController.text,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textMainDark
                                  : AppColors.textMainLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPreviewBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bioController.text.isEmpty
                          ? '소개글을 입력하세요'
                          : _bioController.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBadge() {
    final badgeColors = [
      AppColors.primary,
      Colors.amber,
      Colors.cyan,
      AppColors.primary,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColors[_selectedBadgeStyle].withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: _selectedBadgeStyle == 2
            ? Border.all(color: Colors.cyan.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _selectedBadgeStyle == 1
                ? Icons.workspace_premium
                : _selectedBadgeStyle == 2
                    ? Icons.diamond
                    : Icons.verified,
            size: 12,
            color: badgeColors[_selectedBadgeStyle],
          ),
          const SizedBox(width: 4),
          Text(
            '인증',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: badgeColors[_selectedBadgeStyle],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor:
            isDark ? AppColors.textSubDark : AppColors.textSubLight,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: '기본 정보'),
          Tab(text: '테마'),
          Tab(text: '스타일'),
          Tab(text: '소셜'),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(bool isDark, dynamic profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Section
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _themeColors[_selectedThemeColor]
                              .withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: profile?.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: profile!.avatarUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showImageSourceDialog(isDark),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _themeColors[_selectedThemeColor],
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
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _showImageSourceDialog(isDark),
                  child: Text(
                    '프로필 사진 변경',
                    style: TextStyle(
                      color: _themeColors[_selectedThemeColor],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Name Field
          _buildSectionTitle('이름', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: '크리에이터 이름을 입력하세요',
            isDark: isDark,
            onChanged: (_) => _onFieldChanged(),
          ),

          const SizedBox(height: 24),

          // Bio Field
          _buildSectionTitle('소개', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _bioController,
            hint: '팬들에게 보여줄 소개글을 작성하세요',
            isDark: isDark,
            maxLines: 4,
            maxLength: 200,
            onChanged: (_) => _onFieldChanged(),
          ),

          const SizedBox(height: 24),

          // Background Image
          _buildSectionTitle('배경 이미지', isDark),
          const SizedBox(height: 8),
          _buildBackgroundSelector(isDark),
        ],
      ),
    );
  }

  Widget _buildThemeTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('테마 색상', isDark),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_themeColors.length, (index) {
                    final isSelected = _selectedThemeColor == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedThemeColor = index;
                        });
                        _onFieldChanged();
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _themeColors[index],
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      width: 3,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _themeColors[index]
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 24)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _themeColorNames[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? _themeColors[index]
                                  : (isDark
                                      ? AppColors.textSubDark
                                      : AppColors.textSubLight),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle('적용 범위', isDark),
          const SizedBox(height: 8),
          Text(
            '선택한 테마 색상은 프로필 테두리, 뱃지, 버튼 등에 적용됩니다.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStyleTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('뱃지 스타일', isDark),
          const SizedBox(height: 12),
          ...List.generate(_badgeStyles.length, (index) {
            final isSelected = _selectedBadgeStyle == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBadgeStyle = index;
                });
                _onFieldChanged();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    _buildBadgePreview(index),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _badgeStyles[index],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          _buildSectionTitle('프로필 레이아웃', isDark),
          const SizedBox(height: 12),
          ...List.generate(_layoutStyles.length, (index) {
            final isSelected = _selectedLayout == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLayout = index;
                });
                _onFieldChanged();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      index == 0
                          ? Icons.view_agenda
                          : index == 1
                              ? Icons.credit_card
                              : Icons.fullscreen,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textSubDark
                              : AppColors.textSubLight),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _layoutStyles[index],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textMainDark
                              : AppColors.textMainLight,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBadgePreview(int style) {
    final colors = [
      AppColors.primary,
      Colors.amber,
      Colors.cyan,
      AppColors.primary,
    ];
    final icons = [
      Icons.verified,
      Icons.workspace_premium,
      Icons.diamond,
      Icons.verified,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors[style].withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: style == 2
            ? Border.all(color: Colors.cyan.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icons[style], size: 16, color: colors[style]),
          const SizedBox(width: 6),
          Text(
            '인증',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors[style],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinksTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('소셜 미디어 링크', isDark),
          const SizedBox(height: 8),
          Text(
            '프로필에 표시할 소셜 미디어 링크를 추가하세요.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
          ),
          const SizedBox(height: 16),

          _buildSocialLinkItem(
            icon: Icons.camera_alt,
            label: 'Instagram',
            hint: 'instagram.com/username',
            value: _instagramLink,
            color: Colors.pink,
            isDark: isDark,
            onChanged: (v) {
              setState(() => _instagramLink = v);
              _onFieldChanged();
            },
          ),

          _buildSocialLinkItem(
            icon: Icons.play_circle_filled,
            label: 'YouTube',
            hint: 'youtube.com/@channel',
            value: _youtubeLink,
            color: Colors.red,
            isDark: isDark,
            onChanged: (v) {
              setState(() => _youtubeLink = v);
              _onFieldChanged();
            },
          ),

          _buildSocialLinkItem(
            icon: Icons.music_note,
            label: 'TikTok',
            hint: 'tiktok.com/@username',
            value: _tiktokLink,
            color: Colors.black,
            isDark: isDark,
            onChanged: (v) {
              setState(() => _tiktokLink = v);
              _onFieldChanged();
            },
          ),

          _buildSocialLinkItem(
            icon: Icons.alternate_email,
            label: 'Twitter / X',
            hint: 'x.com/username',
            value: _twitterLink,
            color: Colors.blue,
            isDark: isDark,
            onChanged: (v) {
              setState(() => _twitterLink = v);
              _onFieldChanged();
            },
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () {
              // 커스텀 링크 추가 로직
            },
            icon: const Icon(Icons.add),
            label: const Text('다른 링크 추가'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinkItem({
    required IconData icon,
    required String label,
    required String hint,
    required String value,
    required Color color,
    required bool isDark,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: onChanged,
            style: TextStyle(
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterStyle: TextStyle(
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundSelector(bool isDark) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showImageSourceDialog(isDark),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
                const SizedBox(height: 8),
                Text(
                  '배경 이미지 추가',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  _onFieldChanged();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _onFieldChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscardDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '변경사항 삭제',
          style: TextStyle(
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        content: Text(
          '저장하지 않은 변경사항이 있습니다. 정말 나가시겠습니까?',
          style: TextStyle(
            color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: TextStyle(
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pop();
            },
            child: Text(
              '나가기',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
