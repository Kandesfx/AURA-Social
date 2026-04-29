import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../providers/notification_provider.dart';

/// AURA Social – Notification Tile Widget
///
/// Person 4, Task #8
/// Hiển thị một notification item với:
/// - AuraRing mini-avatar
/// - Icon theo type (reaction/follow/message/soul/wave)
/// - Sender name + action text
/// - Relative timestamp
/// - Unread indicator
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  final NotificationItem notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : AuraColors.primary.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(
              color: AuraColors.surfaceBorder.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar with AuraRing ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                AuraRing(
                  size: 48,
                  emotionVector: notification.senderEmotionVector,
                  animate: false,
                  glowIntensity: 0.2,
                  child: Container(
                    color: AuraColors.surfaceVariant,
                    child: Center(
                      child: Text(
                        notification.senderName.isNotEmpty
                            ? notification.senderName[0].toUpperCase()
                            : '?',
                        style: AuraTypography.titleMedium.copyWith(
                          color: AuraColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Type icon badge
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _typeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AuraColors.background,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _typeIcon,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: notification.senderName,
                          style: AuraTypography.bodyMedium.copyWith(
                            color: AuraColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' ${notification.body}',
                          style: AuraTypography.bodyMedium.copyWith(
                            color: notification.isRead
                                ? AuraColors.textTertiary
                                : AuraColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt, locale: 'en_short'),
                    style: AuraTypography.labelSmall.copyWith(
                      color: AuraColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Unread dot ──
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8, left: 8),
                decoration: const BoxDecoration(
                  color: AuraColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case NotificationType.reaction:
        return Icons.emoji_emotions_rounded;
      case NotificationType.follow:
        return Icons.person_add_rounded;
      case NotificationType.message:
        return Icons.chat_bubble_rounded;
      case NotificationType.soulConnect:
        return Icons.favorite_rounded;
      case NotificationType.waveInvite:
        return Icons.waves_rounded;
      case NotificationType.system:
        return Icons.auto_awesome_rounded;
    }
  }

  Color get _typeColor {
    switch (notification.type) {
      case NotificationType.reaction:
        return AuraColors.emotionJoy;
      case NotificationType.follow:
        return AuraColors.secondary;
      case NotificationType.message:
        return AuraColors.info;
      case NotificationType.soulConnect:
        return AuraColors.tertiary;
      case NotificationType.waveInvite:
        return AuraColors.emotionSurprise;
      case NotificationType.system:
        return AuraColors.primary;
    }
  }
}
