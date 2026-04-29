import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_tile.dart';

/// AURA Social – Notifications Screen
///
/// Person 4, Task #7
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: Text('Đọc hết',
                  style: AuraTypography.labelMedium.copyWith(color: AuraColors.primary)),
            ),
        ],
      ),
      body: notifState.isLoading
          ? _buildLoading()
          : notifState.notifications.isEmpty
              ? _buildEmpty()
              : _buildList(context, ref, notifState),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation(AuraColors.primary.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AuraColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 48,
                color: AuraColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('Chưa có thông báo',
              style: AuraTypography.headlineSmall.copyWith(color: AuraColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Thông báo mới sẽ xuất hiện ở đây',
              style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, NotificationState state) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final today = state.notifications.where((n) => n.createdAt.isAfter(todayStart)).toList();
    final earlier = state.notifications.where((n) => n.createdAt.isBefore(todayStart)).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
      color: AuraColors.primary,
      backgroundColor: AuraColors.surface,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        children: [
          if (state.unreadCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AuraColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AuraColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: AuraColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text('${state.unreadCount} thông báo chưa đọc',
                      style: AuraTypography.labelMedium.copyWith(color: AuraColors.primary)),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
          if (today.isNotEmpty) ...[
            _sectionHeader('Hôm nay'),
            ...today.asMap().entries.map((e) => NotificationTile(
              notification: e.value,
              onTap: () => ref.read(notificationProvider.notifier).markAsRead(e.value.id),
            ).animate().fadeIn(duration: 300.ms, delay: (e.key * 50).ms).slideX(begin: 0.03)),
          ],
          if (earlier.isNotEmpty) ...[
            _sectionHeader('Trước đó'),
            ...earlier.asMap().entries.map((e) => NotificationTile(
              notification: e.value,
              onTap: () => ref.read(notificationProvider.notifier).markAsRead(e.value.id),
            ).animate().fadeIn(duration: 300.ms, delay: ((today.length + e.key) * 50).ms).slideX(begin: 0.03)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: AuraTypography.labelLarge.copyWith(
          color: AuraColors.textSecondary, letterSpacing: 0.8)),
    );
  }
}
