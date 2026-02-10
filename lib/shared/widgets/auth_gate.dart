import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import 'primary_button.dart';

/// Action-level auth gate.
///
/// Instead of silently failing or showing generic toasts when a guest
/// tries an action that requires authentication (e.g. sending a message,
/// funding), this displays a bottom sheet explaining *why* login is needed
/// and offering clear next actions.
class AuthGate {
  AuthGate._();

  /// Guard an action that requires authentication.
  ///
  /// If the user is authenticated (including demo mode), [onAuthenticated]
  /// fires immediately. Otherwise, a bottom sheet with [reason] is shown.
  static void guardAction(
    BuildContext context, {
    required String reason,
    required VoidCallback onAuthenticated,
  }) {
    try {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authProvider);

      if (authState is AuthAuthenticated || authState is AuthDemoMode) {
        onAuthenticated();
        return;
      }
    } catch (_) {
      // ProviderScope not available — show gate
    }

    _showLoginSheet(context, reason: reason);
  }

  /// Show the login bottom sheet with reason and CTAs.
  static void _showLoginSheet(BuildContext context, {required String reason}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    borderRadius: AppRadius.smBR,
                  ),
                ),
                const SizedBox(height: 24),

                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),

                // Reason text
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '로그인하거나 데모 모드로 체험해보세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? AppColors.textSubDark : AppColors.textSubLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Login CTA
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: '로그인',
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      final currentPath =
                          GoRouterState.of(context).uri.toString();
                      context.push(
                        '/login?next=${Uri.encodeComponent(currentPath)}',
                      );
                    },
                  ),
                ),

                // Dismiss
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(
                      '나중에',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSubDark
                            : AppColors.textSubLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
