import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/broadcast_message.dart';
import '../../chat/chat_thread_screen_v2.dart';
import '../../creator/helpers/personalization_preview.dart';

/// 미디어 타입
enum MediaType {
  image,
  video,
  voice,
}

/// 미디어 전송 전 확인 다이얼로그
///
/// 아티스트가 미디어(사진/동영상/음성)를 전송하기 전에
/// 미리보기를 확인하고 최종 확인할 수 있는 다이얼로그입니다.
class MediaPreviewConfirmation extends StatefulWidget {
  final MediaType mediaType;
  final String mediaPath;
  final String? caption;
  final int subscriberCount;
  final String artistName;
  final String? artistAvatarUrl;
  final Future<void> Function(String mediaPath, String? caption)? onConfirm;
  final VoidCallback? onReselect;

  const MediaPreviewConfirmation({
    super.key,
    required this.mediaType,
    required this.mediaPath,
    this.caption,
    required this.subscriberCount,
    required this.artistName,
    this.artistAvatarUrl,
    this.onConfirm,
    this.onReselect,
  });

  /// 바텀 시트로 표시
  static Future<bool?> show({
    required BuildContext context,
    required MediaType mediaType,
    required String mediaPath,
    String? caption,
    required int subscriberCount,
    required String artistName,
    String? artistAvatarUrl,
    Future<void> Function(String mediaPath, String? caption)? onConfirm,
    VoidCallback? onReselect,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaPreviewConfirmation(
        mediaType: mediaType,
        mediaPath: mediaPath,
        caption: caption,
        subscriberCount: subscriberCount,
        artistName: artistName,
        artistAvatarUrl: artistAvatarUrl,
        onConfirm: onConfirm,
        onReselect: onReselect,
      ),
    );
  }

  @override
  State<MediaPreviewConfirmation> createState() =>
      _MediaPreviewConfirmationState();
}

class _MediaPreviewConfirmationState extends State<MediaPreviewConfirmation> {
  late TextEditingController _captionController;
  bool _isSending = false;
  PreviewFanType _selectedFanType = PreviewFanType.vipLongTime;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.caption ?? '');
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      await widget.onConfirm?.call(
        widget.mediaPath,
        _captionController.text.isNotEmpty ? _captionController.text : null,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('전송 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 핸들 바
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 헤더
            _buildHeader(context, isDark),

            const Divider(height: 1),

            // 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: mediaQuery.viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 미디어 미리보기
                    _buildMediaPreview(isDark),

                    const SizedBox(height: 24),

                    // 캡션 입력 (선택사항)
                    _buildCaptionInput(isDark),

                    const SizedBox(height: 24),

                    // 팬 타입 선택기
                    _buildFanTypeSelector(isDark),

                    const SizedBox(height: 16),

                    // 팬에게 보이는 모습
                    _buildFanViewPreview(isDark),

                    const SizedBox(height: 16),

                    // 경고 메시지
                    _buildWarningMessage(isDark),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            _buildBottomActions(isDark, mediaQuery),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: Icon(
              Icons.close,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
          Expanded(
            child: Text(
              _getTitle(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
          ),
          const SizedBox(width: 48), // 균형 맞추기
        ],
      ),
    );
  }

  String _getTitle() {
    switch (widget.mediaType) {
      case MediaType.image:
        return '사진 전송 확인';
      case MediaType.video:
        return '동영상 전송 확인';
      case MediaType.voice:
        return '음성 메시지 전송 확인';
    }
  }

  Widget _buildMediaPreview(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getMediaIcon(),
              size: 16,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(width: 6),
            Text(
              '선택한 ${_getMediaTypeName()}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.grey[300]!,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildMediaContent(),
          ),
        ),
      ],
    );
  }

  IconData _getMediaIcon() {
    switch (widget.mediaType) {
      case MediaType.image:
        return Icons.image_outlined;
      case MediaType.video:
        return Icons.videocam_outlined;
      case MediaType.voice:
        return Icons.mic_outlined;
    }
  }

  String _getMediaTypeName() {
    switch (widget.mediaType) {
      case MediaType.image:
        return '사진';
      case MediaType.video:
        return '동영상';
      case MediaType.voice:
        return '음성 메시지';
    }
  }

  Widget _buildMediaContent() {
    switch (widget.mediaType) {
      case MediaType.image:
        return _buildImagePreview();
      case MediaType.video:
        return _buildVideoPreview();
      case MediaType.voice:
        return _buildVoicePreview();
    }
  }

  Widget _buildImagePreview() {
    // 로컬 파일인 경우
    if (widget.mediaPath.startsWith('/') || widget.mediaPath.contains(':\\')) {
      return Image.file(
        File(widget.mediaPath),
        fit: BoxFit.cover,
        height: 250,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // URL인 경우 (데모용)
    return Container(
      height: 250,
      color: AppColors.surfaceDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              '선택된 이미지',
              style: TextStyle(
                color: AppColors.textSubDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.mediaPath.split('/').last,
              style: TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      height: 200,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 비디오 썸네일 (실제로는 비디오 플레이어 사용)
          Container(
            color: Colors.grey[900],
          ),
          // 재생 버튼
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              size: 40,
              color: AppColors.primary600,
            ),
          ),
          // 비디오 정보
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '0:15',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 파형 시각화 (시뮬레이션)
          Container(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(30, (index) {
                // 랜덤 높이 시뮬레이션
                final height = 10.0 + (index % 5) * 8.0 + (index % 3) * 6.0;
                return Container(
                  width: 4,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          // 재생 컨트롤
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '음성 메시지',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                    ),
                  ),
                  Text(
                    '0:15',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSubDark
                          : AppColors.textSubLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildCaptionInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.text_fields,
              size: 16,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(width: 6),
            Text(
              '캡션 (선택사항)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.grey[300]!,
            ),
          ),
          child: TextField(
            controller: _captionController,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: '함께 보낼 메시지를 입력하세요...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFanTypeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 16,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(width: 6),
            Text(
              '미리보기 기준 팬',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PreviewFanType.values
                .where((t) => t != PreviewFanType.custom)
                .map((type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFanTypeChip(type, isDark),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFanTypeChip(PreviewFanType type, bool isDark) {
    final isSelected = _selectedFanType == type;
    final sampleData = type.sampleData;

    return GestureDetector(
      onTap: () => setState(() => _selectedFanType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.borderDark : Colors.grey[300]!,
                ),
        ),
        child: Text(
          '${sampleData.name} (${sampleData.tier})',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textMainDark : AppColors.textMainLight),
          ),
        ),
      ),
    );
  }

  Widget _buildFanViewPreview(bool isDark) {
    // 미리보기용 메시지 생성
    final previewMessage = BroadcastMessage(
      id: 'preview',
      channelId: 'preview',
      senderId: 'artist',
      senderType: 'artist',
      deliveryScope: DeliveryScope.broadcast,
      content: _captionController.text.isNotEmpty
          ? _captionController.text
          : null,
      messageType: _getBroadcastMessageType(),
      mediaUrl: widget.mediaPath,
      createdAt: DateTime.now(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.visibility,
              size: 16,
              color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
            ),
            const SizedBox(width: 6),
            Text(
              '팬에게 보이는 모습',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSubDark : AppColors.textSubLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: MessageBubbleV2(
            message: previewMessage,
            isArtist: true,
            artistAvatarUrl: widget.artistAvatarUrl,
            artistName: widget.artistName,
            showAvatar: true,
          ),
        ),
      ],
    );
  }

  BroadcastMessageType _getBroadcastMessageType() {
    switch (widget.mediaType) {
      case MediaType.image:
        return BroadcastMessageType.image;
      case MediaType.video:
        return BroadcastMessageType.video;
      case MediaType.voice:
        return BroadcastMessageType.voice;
    }
  }

  Widget _buildWarningMessage(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Colors.amber[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전송 전 확인해주세요',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.subscriberCount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}명의 구독자에게 전송됩니다.\n전송 후에는 취소할 수 없습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDark, MediaQueryData mediaQuery) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        mediaQuery.padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // 다시 선택 버튼
          if (widget.onReselect != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  widget.onReselect?.call();
                },
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: Text(
                  '다시 선택',
                  style: TextStyle(
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (widget.onReselect != null) const SizedBox(width: 12),
          // 전송하기 버튼
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _handleConfirm,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(
                _isSending ? '전송 중...' : '전송하기',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    isDark ? Colors.grey[800] : Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
