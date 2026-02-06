import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/creator_content.dart';

/// 영향받는 화면 종류
enum AffectedView {
  artistProfile('프로필 페이지', Icons.person_outline),
  chatList('채팅 목록', Icons.chat_bubble_outline),
  discoverPage('탐색 페이지', Icons.explore_outlined),
  pushNotification('푸시 알림', Icons.notifications_outlined);

  final String label;
  final IconData icon;

  const AffectedView(this.label, this.icon);
}

/// 크리에이터 프로필 편집 화면
/// - 기본 정보: 아바타, 이름, 소개글, 배경
/// - 콘텐츠: 드롭, 이벤트, 직캠 관리
/// - 테마 & 소셜: 테마 색상, SNS 링크
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

  // Social links
  String _instagramLink = '';
  String _youtubeLink = '';
  String _tiktokLink = '';
  String _twitterLink = '';

  // Content lists
  List<CreatorDrop> _drops = [];
  List<CreatorEvent> _events = [];
  List<CreatorFancam> _fancams = [];

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

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _tabController = TabController(length: 3, vsync: this);

    // 프로필에서 테마 색상 및 소셜 링크 로드
    if (profile != null) {
      _selectedThemeColor = profile.themeColorIndex;
      _instagramLink = profile.instagramLink ?? '';
      _youtubeLink = profile.youtubeLink ?? '';
      _tiktokLink = profile.tiktokLink ?? '';
      _twitterLink = profile.twitterLink ?? '';
    }

    _loadMockContent();
  }

  void _loadMockContent() {
    // Mock 데이터 로드
    _drops = [
      CreatorDrop(
        id: '1',
        name: '시즌 포토카드 세트',
        priceKrw: 15000,
        isNew: true,
      ),
      CreatorDrop(
        id: '2',
        name: '한정판 굿즈 박스',
        priceKrw: 45000,
        isSoldOut: true,
      ),
    ];
    _events = [
      CreatorEvent(
        id: '1',
        title: '팬미팅 2024',
        location: '서울 올림픽공원',
        date: DateTime(2024, 6, 15),
        isOffline: true,
      ),
    ];
    _fancams = [
      CreatorFancam(
        id: '1',
        videoId: 'dQw4w9WgXcQ',
        title: '직캠 - 신곡 무대',
        viewCount: 125000,
        isPinned: true,
      ),
    ];
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

  Future<void> _saveProfile() async {
    final confirmed = await _showChangeConfirmationDialog();
    if (confirmed != true) return;

    // 데모 모드인 경우 데모 프로필 업데이트
    final isDemoMode = ref.read(isDemoModeProvider);
    if (isDemoMode) {
      ref.read(authProvider.notifier).updateDemoProfile(
        displayName: _nameController.text.isNotEmpty ? _nameController.text : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        themeColorIndex: _selectedThemeColor,
        instagramLink: _instagramLink.isNotEmpty ? _instagramLink : null,
        youtubeLink: _youtubeLink.isNotEmpty ? _youtubeLink : null,
        tiktokLink: _tiktokLink.isNotEmpty ? _tiktokLink : null,
        twitterLink: _twitterLink.isNotEmpty ? _twitterLink : null,
      );
    } else {
      // 실제 인증된 사용자인 경우 서버에 저장
      await ref.read(authProvider.notifier).updateProfile(
        displayName: _nameController.text.isNotEmpty ? _nameController.text : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('프로필이 저장되었습니다'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    context.pop();
  }

  Future<bool?> _showChangeConfirmationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '변경 사항 확인',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '프로필 변경 사항을 저장하시겠습니까?',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이 변경 사항은 다음 화면에 반영됩니다:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...AffectedView.values.take(3).map((view) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(view.icon, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            view.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSubDark
                                  : AppColors.textSubLight,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              '취소',
              style: TextStyle(
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '저장하기',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
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
            _buildHeader(context, isDark),
            _buildTabBar(isDark),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(isDark, profile),
                  _buildContentTab(isDark),
                  _buildThemeAndSocialTab(isDark),
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
          Tab(text: '콘텐츠'),
          Tab(text: '테마 & 소셜'),
        ],
      ),
    );
  }

  // ===== 기본 정보 탭 =====
  Widget _buildBasicInfoTab(bool isDark, dynamic profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _buildSectionTitle('이름', isDark),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: '크리에이터 이름을 입력하세요',
            isDark: isDark,
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 24),
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
          _buildSectionTitle('배경 이미지', isDark),
          const SizedBox(height: 8),
          _buildBackgroundSelector(isDark),
        ],
      ),
    );
  }

  // ===== 콘텐츠 탭 =====
  Widget _buildContentTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드롭 섹션
          _buildContentSection(
            title: '최신 드롭',
            icon: Icons.shopping_bag_outlined,
            isDark: isDark,
            itemCount: _drops.length,
            onAdd: () => _showDropEditDialog(isDark),
            child: _drops.isEmpty
                ? _buildEmptyState('드롭(상품)을 추가해보세요', isDark)
                : Column(
                    children: _drops.map((drop) => _buildDropItem(drop, isDark)).toList(),
                  ),
          ),
          const SizedBox(height: 24),

          // 이벤트 섹션
          _buildContentSection(
            title: '다가오는 이벤트',
            icon: Icons.event_outlined,
            isDark: isDark,
            itemCount: _events.length,
            onAdd: () => _showEventEditDialog(isDark),
            child: _events.isEmpty
                ? _buildEmptyState('이벤트를 추가해보세요', isDark)
                : Column(
                    children: _events.map((event) => _buildEventItem(event, isDark)).toList(),
                  ),
          ),
          const SizedBox(height: 24),

          // 직캠 섹션
          _buildContentSection(
            title: '아티스트 직캠',
            icon: Icons.videocam_outlined,
            isDark: isDark,
            itemCount: _fancams.length,
            onAdd: () => _showFancamEditDialog(isDark),
            child: _fancams.isEmpty
                ? _buildEmptyState('YouTube 직캠을 추가해보세요', isDark)
                : Column(
                    children: _fancams.map((fancam) => _buildFancamItem(fancam, isDark)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection({
    required String title,
    required IconData icon,
    required bool isDark,
    required int itemCount,
    required VoidCallback onAdd,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: isDark ? AppColors.textSubDark : AppColors.textSubLight),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$itemCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('추가'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildDropItem(CreatorDrop drop, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
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
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        drop.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                        ),
                      ),
                    ),
                    if (drop.isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (drop.isSoldOut)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SOLD OUT',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  drop.formattedPrice,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showDropEditDialog(isDark, drop: drop),
            icon: Icon(Icons.edit_outlined, size: 20, color: isDark ? AppColors.textSubDark : AppColors.textSubLight),
          ),
          IconButton(
            onPressed: () => _deleteDropConfirm(drop),
            icon: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(CreatorEvent event, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
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
              color: event.isOffline ? Colors.purple.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              event.isOffline ? Icons.location_on : Icons.videocam,
              color: event.isOffline ? Colors.purple : Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: event.isOffline ? Colors.purple.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: event.isOffline ? Colors.purple : Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                Text(
                  event.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEventEditDialog(isDark, event: event),
            icon: Icon(Icons.edit_outlined, size: 20, color: isDark ? AppColors.textSubDark : AppColors.textSubLight),
          ),
          IconButton(
            onPressed: () => _deleteEventConfirm(event),
            icon: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  Widget _buildFancamItem(CreatorFancam fancam, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  fancam.thumbnailUrl,
                  width: 64,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 48,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: const Icon(Icons.videocam, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.play_arrow, size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (fancam.isPinned)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.push_pin, size: 10, color: Colors.white),
                      ),
                    Expanded(
                      child: Text(
                        fancam.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.visibility, size: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      fancam.formattedViewCount,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                final index = _fancams.indexOf(fancam);
                _fancams[index] = fancam.copyWith(isPinned: !fancam.isPinned);
              });
              _onFieldChanged();
            },
            icon: Icon(
              fancam.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 20,
              color: fancam.isPinned ? AppColors.primary : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
            ),
          ),
          IconButton(
            onPressed: () => _deleteFancamConfirm(fancam),
            icon: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  // ===== 테마 & 소셜 탭 =====
  Widget _buildThemeAndSocialTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 테마 색상 섹션
          _buildSectionTitle('테마 색상', isDark),
          const SizedBox(height: 8),
          Text(
            '선택한 테마 색상은 팬이 보는 아티스트 프로필에 적용됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
            ),
          ),
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
            child: Row(
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
                                  color: isDark ? Colors.white : Colors.black,
                                  width: 3,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _themeColors[index].withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _themeColorNames[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? _themeColors[index]
                              : (isDark ? AppColors.textSubDark : AppColors.textSubLight),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 32),

          // 소셜 링크 섹션
          _buildSectionTitle('소셜 미디어 링크', isDark),
          const SizedBox(height: 8),
          Text(
            '프로필 하단에 표시됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
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
            color: isDark ? Colors.white : Colors.black,
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
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
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
              fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 공통 위젯 =====
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
                    color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== 다이얼로그 =====
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

  void _showDropEditDialog(bool isDark, {CreatorDrop? drop}) {
    final isEdit = drop != null;
    final nameController = TextEditingController(text: drop?.name ?? '');
    final priceController = TextEditingController(text: drop?.priceKrw.toString() ?? '');
    final descController = TextEditingController(text: drop?.description ?? '');
    final urlController = TextEditingController(text: drop?.externalUrl ?? '');
    bool isNew = drop?.isNew ?? true;
    bool isSoldOut = drop?.isSoldOut ?? false;
    XFile? selectedImage;
    String? existingImageUrl = drop?.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Padding(
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
                  isEdit ? '드롭 수정' : '새 드롭 추가',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 20),
                // 이미지 선택 영역
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setModalState(() {
                        selectedImage = image;
                        existingImageUrl = null;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                selectedImage!.path,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      : existingImageUrl != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: CachedNetworkImage(
                                  imageUrl: existingImageUrl!,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '상품 이미지 추가',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: '상품명 *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '가격 (원) *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '상품 설명',
                    hintText: '선택사항',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: '구매 링크',
                    hintText: 'https://...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('NEW'),
                      selected: isNew,
                      onSelected: (v) => setModalState(() => isNew = v),
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('SOLD OUT'),
                      selected: isSoldOut,
                      onSelected: (v) => setModalState(() => isSoldOut = v),
                      selectedColor: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isEmpty) return;
                      final newDrop = CreatorDrop(
                        id: drop?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        description: descController.text.isNotEmpty ? descController.text : null,
                        imageUrl: selectedImage?.path ?? existingImageUrl,
                        priceKrw: int.tryParse(priceController.text) ?? 0,
                        isNew: isNew,
                        isSoldOut: isSoldOut,
                        externalUrl: urlController.text.isNotEmpty ? urlController.text : null,
                      );
                      setState(() {
                        if (isEdit) {
                          final index = _drops.indexWhere((d) => d.id == drop.id);
                          _drops[index] = newDrop;
                        } else {
                          _drops.add(newDrop);
                        }
                      });
                      _onFieldChanged();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEdit ? '수정' : '추가',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventEditDialog(bool isDark, {CreatorEvent? event}) {
    final isEdit = event != null;
    final titleController = TextEditingController(text: event?.title ?? '');
    final locationController = TextEditingController(text: event?.location ?? '');
    final descController = TextEditingController(text: event?.description ?? '');
    final ticketUrlController = TextEditingController(text: event?.ticketUrl ?? '');
    DateTime selectedDate = event?.date ?? DateTime.now().add(const Duration(days: 30));
    bool isOffline = event?.isOffline ?? true;
    XFile? selectedImage;
    String? existingImageUrl = event?.imageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Padding(
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
                  isEdit ? '이벤트 수정' : '새 이벤트 추가',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 20),
                // 이미지 선택 영역
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setModalState(() {
                        selectedImage = image;
                        existingImageUrl = null;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                selectedImage!.path,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      : existingImageUrl != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: CachedNetworkImage(
                                  imageUrl: existingImageUrl!,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '이벤트 이미지 추가',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: '이벤트 제목 *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: '장소 *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '날짜: ${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                      ),
                    ),
                    trailing: Icon(
                      Icons.calendar_today,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '이벤트 설명',
                    hintText: '선택사항',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ticketUrlController,
                  decoration: InputDecoration(
                    labelText: '티켓/예매 링크',
                    hintText: 'https://...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('OFFLINE'),
                      selected: isOffline,
                      onSelected: (v) => setModalState(() => isOffline = true),
                      selectedColor: Colors.purple.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('ONLINE'),
                      selected: !isOffline,
                      onSelected: (v) => setModalState(() => isOffline = false),
                      selectedColor: Colors.green.withValues(alpha: 0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isEmpty) return;
                      final newEvent = CreatorEvent(
                        id: event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        location: locationController.text,
                        date: selectedDate,
                        isOffline: isOffline,
                        description: descController.text.isNotEmpty ? descController.text : null,
                        ticketUrl: ticketUrlController.text.isNotEmpty ? ticketUrlController.text : null,
                        imageUrl: selectedImage?.path ?? existingImageUrl,
                      );
                      setState(() {
                        if (isEdit) {
                          final index = _events.indexWhere((e) => e.id == event.id);
                          _events[index] = newEvent;
                        } else {
                          _events.add(newEvent);
                        }
                      });
                      _onFieldChanged();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isEdit ? '수정' : '추가',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFancamEditDialog(bool isDark, {CreatorFancam? fancam}) {
    final isEdit = fancam != null;
    final urlController = TextEditingController(
      text: fancam != null ? 'https://youtube.com/watch?v=${fancam.videoId}' : '',
    );
    String fetchedTitle = fancam?.title ?? '';
    bool isLoading = false;
    String? errorMessage;

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
                isEdit ? '직캠 수정' : '새 직캠 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 20),
              // YouTube URL 입력 + 불러오기 버튼
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: 'YouTube URL',
                        hintText: 'https://youtube.com/watch?v=...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorText: errorMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        final videoId = CreatorFancam.extractVideoId(urlController.text);
                        if (videoId == null) {
                          setModalState(() => errorMessage = '올바른 URL을 입력하세요');
                          return;
                        }

                        setModalState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        try {
                          final response = await http.get(Uri.parse(
                            'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json'
                          ));

                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            setModalState(() {
                              fetchedTitle = data['title'] ?? '';
                              isLoading = false;
                            });
                          } else {
                            setModalState(() {
                              errorMessage = '영상을 찾을 수 없습니다';
                              isLoading = false;
                            });
                          }
                        } catch (e) {
                          setModalState(() {
                            errorMessage = '제목을 불러올 수 없습니다';
                            isLoading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('불러오기', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 제목 (읽기전용)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '제목 (자동)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fetchedTitle.isEmpty ? 'URL을 입력하고 불러오기를 눌러주세요' : fetchedTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: fetchedTitle.isEmpty ? FontWeight.w400 : FontWeight.w500,
                        color: fetchedTitle.isEmpty
                          ? (isDark ? AppColors.textMutedDark : AppColors.textMuted)
                          : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: fetchedTitle.isEmpty ? null : () {
                    final videoId = CreatorFancam.extractVideoId(urlController.text);
                    if (videoId == null) return;

                    final newFancam = CreatorFancam(
                      id: fancam?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      videoId: videoId,
                      title: fetchedTitle,
                      isPinned: fancam?.isPinned ?? false,
                    );
                    setState(() {
                      if (isEdit) {
                        final index = _fancams.indexWhere((f) => f.id == fancam.id);
                        _fancams[index] = newFancam;
                      } else {
                        _fancams.add(newFancam);
                      }
                    });
                    _onFieldChanged();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: fetchedTitle.isEmpty
                      ? (isDark ? Colors.grey[700] : Colors.grey[300])
                      : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEdit ? '수정' : '추가',
                    style: TextStyle(
                      color: fetchedTitle.isEmpty
                        ? (isDark ? Colors.grey[500] : Colors.grey[600])
                        : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteDropConfirm(CreatorDrop drop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('드롭 삭제'),
        content: Text('"${drop.name}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _drops.removeWhere((d) => d.id == drop.id));
              _onFieldChanged();
              Navigator.pop(context);
            },
            child: Text('삭제', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _deleteEventConfirm(CreatorEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이벤트 삭제'),
        content: Text('"${event.title}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _events.removeWhere((e) => e.id == event.id));
              _onFieldChanged();
              Navigator.pop(context);
            },
            child: Text('삭제', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _deleteFancamConfirm(CreatorFancam fancam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('직캠 삭제'),
        content: Text('"${fancam.title}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _fancams.removeWhere((f) => f.id == fancam.id));
              _onFieldChanged();
              Navigator.pop(context);
            },
            child: Text('삭제', style: TextStyle(color: AppColors.danger)),
          ),
        ],
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
