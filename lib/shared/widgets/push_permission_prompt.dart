import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';

/// 푸시 알림 권한 요청 사전 설명 바텀시트
/// OS 레벨 권한 요청 전에 가치를 설명하는 프롬프트
class PushPermissionPrompt {
  /// 푸시 알림 가치 설명 바텀시트를 표시합니다.
  /// 사용자가 "허용"을 선택하면 onAccept 콜백이 호출됩니다.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _PushPermissionSheet(),
    );

    if (result == true) {
      return await _requestOsPermission();
    }
    return false;
  }

  /// Request actual OS notification permission via permission_handler.
  static Future<bool> _requestOsPermission() async {
    // Web does not support permission_handler
    if (kIsWeb) return false;

    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PushPermission] OS permission request failed: $e');
      }
      return false;
    }
  }
}

class _PushPermissionSheet extends StatelessWidget {
  const _PushPermissionSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary600,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                '아티스트의 새 메시지를 놓치지 마세요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                '알림을 허용하면 다음과 같은 소식을 실시간으로 받을 수 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark ? AppColors.textSubDark : AppColors.textSubLight,
                ),
              ),
              const SizedBox(height: 20),

              // Benefits
              _buildBenefit(
                isDark,
                Icons.chat_bubble_outline,
                '새 메시지 알림',
                '구독 중인 아티스트가 메시지를 보내면 바로 알려드려요',
              ),
              _buildBenefit(
                isDark,
                Icons.campaign_outlined,
                '펀딩 알림',
                '관심 있는 펀딩의 시작, 마감 임박, 결과를 안내해요',
              ),
              _buildBenefit(
                isDark,
                Icons.card_giftcard_outlined,
                '이벤트 & 혜택',
                '한정 이벤트, 보너스 DT 등 특별한 혜택을 놓치지 마세요',
              ),
              const SizedBox(height: 24),

              // Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '알림 허용하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Text(
                  '나중에 할게요',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Privacy note
              Text(
                '알림 설정은 언제든지 앱 설정에서 변경할 수 있습니다',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(
    bool isDark,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
