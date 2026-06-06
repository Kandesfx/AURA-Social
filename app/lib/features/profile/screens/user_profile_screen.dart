import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/emotion_profile_provider.dart';
import '../../feed/models/post_model.dart';

/// AURA Social – Other User Profile Screen
///
/// Hiển thị profile người khác (read-only) với:
/// - Follow / Unfollow button
/// - Avatar + Aura Ring (nếu aura_ring_visible)
/// - Stats, bio, interests
/// - Post grid
/// - Message button
class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isFollowing = false;
  bool _loadingFollow = true;
  bool _togglingFollow = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final service = ref.read(userProfileServiceProvider);
    final following = await service.isFollowing(myUid, widget.userId);
    if (mounted) setState(() { _isFollowing = following; _loadingFollow = false; });
  }

  Future<void> _toggleFollow() async {
    if (_togglingFollow) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    setState(() => _togglingFollow = true);

    try {
      final service = ref.read(userProfileServiceProvider);
      final nowFollowing = await service.toggleFollow(myUid, widget.userId);
      if (mounted) setState(() => _isFollowing = nowFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AuraColors.error));
      }
    } finally {
      if (mounted) setState(() => _togglingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider(widget.userId));
    final emotionAsync = ref.watch(emotionProfileProvider(widget.userId));
    final isMe = FirebaseAuth.instance.currentUser?.uid == widget.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: userAsync.when(
        loading: () => const AuraLoadingWidget(),
        error: (e, _) => AuraErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(userProfileProvider(widget.userId))),
        data: (user) {
          final emotion = emotionAsync.valueOrNull;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(children: [
              const SizedBox(height: 20),

              // ── Avatar + Aura Ring ──
              AuraRing(
                size: 110,
                imageUrl: user.avatarUrl,
                emotionVector: emotion?.currentEmotionVector,
                confidence: emotion?.emotionConfidence ?? 0.0,
                arousal: emotion?.arousal ?? 0.3,
                glowIntensity: 0.5,
              ),

              const SizedBox(height: 16),

              // ── Name + Username ──
              Text(user.displayName, style: AuraTypography.headlineMedium.copyWith(color: AuraColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('@${user.username}', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary)),

              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(user.bio!, style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textSecondary), textAlign: TextAlign.center)),
              ],

              const SizedBox(height: 20),

              // ── Stats Row ──
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _StatItem(count: _fmt(user.postsCount), label: 'Posts'),
                _divider(),
                _StatItem(
                  count: _fmt(user.followersCount), 
                  label: 'Followers',
                  onTap: () => context.push('/user/${user.uid}/follows/followers'),
                ),
                _divider(),
                _StatItem(
                  count: _fmt(user.followingCount), 
                  label: 'Following',
                  onTap: () => context.push('/user/${user.uid}/follows/following'),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Action Buttons ──
              if (!isMe) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(children: [
                  Expanded(child: _loadingFollow
                    ? Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AuraColors.primary)))
                    : SizedBox(height: 44, child: _isFollowing
                      ? OutlinedButton(
                          onPressed: _togglingFollow ? null : _toggleFollow,
                          style: OutlinedButton.styleFrom(side: BorderSide(color: AuraColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _togglingFollow
                            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AuraColors.primary))
                            : Text('Đang follow', style: AuraTypography.labelLarge.copyWith(color: AuraColors.primary)),
                        )
                      : FilledButton(
                          onPressed: _togglingFollow ? null : _toggleFollow,
                          style: FilledButton.styleFrom(backgroundColor: AuraColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _togglingFollow
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Follow', style: AuraTypography.labelLarge.copyWith(color: Colors.white)),
                        ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(height: 44, child: OutlinedButton.icon(
                    onPressed: () {}, // TODO: navigate to chat
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Nhắn tin'),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: AuraColors.surfaceBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Interests Tags ──
              if (user.interests.isNotEmpty) ...[
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(spacing: 8, runSpacing: 8,
                    children: user.interests.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AuraColors.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AuraColors.primary.withValues(alpha: .2))),
                      child: Text('#$tag', style: AuraTypography.labelSmall.copyWith(color: AuraColors.primary)),
                    )).toList())),
                const SizedBox(height: 20),
              ],

              // ── Post Grid ──
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Text('Bài viết', style: AuraTypography.titleMedium.copyWith(color: AuraColors.textPrimary)),
                  const Spacer(),
                ])),
              const SizedBox(height: 12),
              _UserPostGrid(userId: widget.userId),
            ]),
          );
        },
      ),
    );
  }

  static Widget _divider() => Container(height: 28, width: 1, margin: EdgeInsets.symmetric(horizontal: 20), color: AuraColors.surfaceBorder);
  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _UserPostGrid extends StatelessWidget {
  const _UserPostGrid({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts')
          .where('user_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AuraColors.primary)));
        }
        
        var posts = snap.data?.docs.map((d) => PostModel.fromFirestore(d)).toList() ?? [];
        posts = posts.where((p) => p.status == 'active').toList();
        posts.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        if (posts.length > 30) posts = posts.sublist(0, 30);
        
        if (posts.isEmpty) {
          return Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Chưa có bài viết', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary))));
        }

        return Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final post = posts[i];
              return GestureDetector(
                onTap: () => context.push('/post/${post.postId}'),
                child: Container(
                  decoration: BoxDecoration(color: AuraColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                  child: post.hasMedia && post.mediaUrls.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(imageUrl: post.mediaUrls.first, fit: BoxFit.cover))
                    : Container(
                        padding: const EdgeInsets.all(6),
                        child: Center(child: Text(post.content.length > 30 ? '${post.content.substring(0, 30)}...' : post.content,
                          style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary, fontSize: 10), textAlign: TextAlign.center, maxLines: 3))),
                ).animate().fadeIn(delay: (i * 50).ms, duration: 300.ms),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label, this.onTap});
  final String count; final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(children: [
        Text(count, style: AuraTypography.headlineSmall.copyWith(color: AuraColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: AuraTypography.labelSmall.copyWith(color: AuraColors.textTertiary)),
      ]),
    );
  }
}
