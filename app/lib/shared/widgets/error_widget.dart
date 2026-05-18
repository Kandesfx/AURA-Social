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
              message,
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
