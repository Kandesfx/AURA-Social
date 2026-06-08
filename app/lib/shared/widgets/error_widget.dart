import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// AURA Social – Error Widget
///
/// Widget lỗi tái sử dụng xuyên suốt app.
/// Hiển thị icon + message + optional retry button.
///
/// ### Usage:
/// ```dart
/// AuraErrorWidget(message: 'Đã xảy ra lỗi')
/// AuraErrorWidget(message: 'Network error', onRetry: () => ref.invalidate(...))
/// ```
class AuraErrorWidget extends StatelessWidget {
  const AuraErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  /// Error message hiển thị
  final String message;

  String get _friendlyMessage {
    final lower = message.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('dioexception') ||
        lower.contains('http') ||
        lower.contains('failed host lookup')) {
      return 'Không thể kết nối máy chủ. Vui lòng kiểm tra lại kết nối mạng và thử lại.';
    }
    if (lower.contains('firebaseauth') || lower.contains('auth')) {
      return 'Xác thực tài khoản thất bại. Vui lòng đăng nhập lại.';
    }
    if (lower.contains('permission-denied') || lower.contains('permission')) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    if (message.contains('Exception') || message.contains('[') || message.contains(':')) {
      return 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.';
    }
    return message;
  }

  /// Callback khi tap nút "Thử lại"
  final VoidCallback? onRetry;

  /// Custom icon (mặc định: error icon)
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon with subtle background
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AuraColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 36,
                color: AuraColors.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Đã xảy ra lỗi',
              style: AuraTypography.titleMedium.copyWith(
                color: AuraColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              _friendlyMessage,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Thử lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AuraColors.primary,
                    side: BorderSide(color: AuraColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget – khi không có data
///
/// ### Usage:
/// ```dart
/// AuraEmptyWidget(icon: Icons.inbox, title: 'Trống', subtitle: 'Chưa có dữ liệu')
/// ```
class AuraEmptyWidget extends StatelessWidget {
  const AuraEmptyWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AuraColors.textTertiary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AuraTypography.headlineSmall.copyWith(
                color: AuraColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AuraTypography.bodyMedium.copyWith(
                  color: AuraColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: action,
                style: FilledButton.styleFrom(
                  backgroundColor: AuraColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
