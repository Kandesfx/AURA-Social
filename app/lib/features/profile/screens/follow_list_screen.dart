import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../../../providers/user_profile_provider.dart';

class FollowListScreen extends ConsumerWidget {
  const FollowListScreen({
    super.key,
    required this.userId,
    required this.type,
  });

  final String userId;
  final String type; // 'followers' or 'following'

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = type == 'followers' ? 'Followers' : 'Following';
    final listAsync = ref.watch(followListProvider((uid: userId, type: type)));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: listAsync.when(
        loading: () => const AuraLoadingWidget(),
        error: (e, _) => AuraErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(followListProvider((uid: userId, type: type))),
        ),
        data: (userIds) {
          if (userIds.isEmpty) {
            return Center(
              child: Text(
                type == 'followers' ? 'Chưa có follower nào' : 'Chưa theo dõi ai',
                style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary),
              ),
            );
          }

          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              return _UserListItem(userId: userIds[index]);
            },
          );
        },
      ),
    );
  }
}

class _UserListItem extends ConsumerWidget {
  const _UserListItem({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));

    return userAsync.when(
      loading: () => ListTile(
        leading: CircleAvatar(backgroundColor: AuraColors.surfaceVariant),
        title: Text('Đang tải...'),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        return ListTile(
          onTap: () => context.push('/user/${user.uid}'),
          leading: AuraRing(
            size: 40,
            imageUrl: user.avatarUrl,
            emotionVector: null, // we skip emotional ring for performance
            glowIntensity: 0,
            animate: false,
          ),
          title: Text(
            user.displayName,
            style: AuraTypography.titleSmall.copyWith(
              color: AuraColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '@${user.username}',
            style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary),
          ),
        );
      },
    );
  }
}
