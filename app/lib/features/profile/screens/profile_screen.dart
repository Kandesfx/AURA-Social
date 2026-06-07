import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../providers/emotion_profile_provider.dart';
import '../../feed/models/post_model.dart';

/// AURA Social – Profile Screen (Connected to Firestore)
///
/// Hiển thị profile user đang login với:
/// - Avatar + Aura Ring (emotion vector thực từ provider)
/// - Stats: followers, following, posts
/// - Emotional Compass card (mood + confidence + mode)
/// - Post grid (query Firestore)
/// - Logout, Edit Profile, Settings actions
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final emotionAsync = ref.watch(currentEmotionProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const AuraLoadingWidget(),
        error: (e, _) => AuraErrorWidget(message: e.toString(), onRetry: () => ref.invalidate(currentUserProfileProvider)),
        data: (user) {
          if (user == null) return const AuraErrorWidget(message: 'Không tìm thấy thông tin người dùng');

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
                _StatItem(count: _fmtCount(user.postsCount), label: 'Posts'),
                _divider(),
                _StatItem(
                  count: _fmtCount(user.followersCount), 
                  label: 'Followers',
                  onTap: () => context.push('/user/${user.uid}/follows/followers'),
                ),
                _divider(),
                _StatItem(
                  count: _fmtCount(user.followingCount), 
                  label: 'Following',
                  onTap: () => context.push('/user/${user.uid}/follows/following'),
                ),
                _divider(),
                _StatItem(count: _fmtCount(user.connectionsCount), label: 'Soul'),
              ]),

              const SizedBox(height: 20),

            // ── Emotional Compass Card ──
              GestureDetector(
                onTap: () => context.push('/compass'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AuraColors.primary.withValues(alpha: 0.08),
                        AuraColors.secondary.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AuraColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AuraColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🧭', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emotional Compass',
                              style: AuraTypography.titleSmall.copyWith(
                                color: AuraColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Mood: ',
                                  style: AuraTypography.bodySmall.copyWith(
                                    color: AuraColors.textTertiary,
                                  ),
                                ),
                                Text(
                                  '${_getEmoji(emotion?.dominantEmotion ?? 'explore')} ${_capitalize(emotion?.dominantEmotion ?? 'explore')}',
                                  style: AuraTypography.bodySmall.copyWith(
                                    color: AuraColors.getEmotionColor(emotion?.dominantEmotion ?? 'explore'),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '📊 ${( (emotion?.emotionConfidence ?? 0.5) * 100 ).round()}%',
                                  style: AuraTypography.bodySmall.copyWith(
                                    color: AuraColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AuraColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
               .slideX(begin: 0.03),

              const SizedBox(height: 12),

              // ── Wellbeing Tracker Card ──
              GestureDetector(
                onTap: () => context.push('/wellbeing'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AuraColors.success.withValues(alpha: 0.08),
                        AuraColors.secondary.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AuraColors.success.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AuraColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🧘', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theo dõi sức khỏe tinh thần',
                              style: AuraTypography.titleSmall.copyWith(
                                color: AuraColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhịp thở, gợi ý nghỉ ngơi & hỗ trợ khẩn cấp',
                              style: AuraTypography.bodySmall.copyWith(
                                color: AuraColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AuraColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms)
               .slideX(begin: 0.03),

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

              // ── Post Grid Header ──
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Text('Bài viết', style: AuraTypography.titleMedium.copyWith(color: AuraColors.textPrimary)),
                  const Spacer(),
                  Icon(Icons.grid_view_rounded, size: 20, color: AuraColors.primary),
                ])),
              const SizedBox(height: 12),

              // ── Post Grid (Firestore) ──
              _PostGrid(userId: user.uid),
            ]),
          );
        },
      ),
    );
  }

  static Widget _divider() => Container(height: 28, width: 1, margin: EdgeInsets.symmetric(horizontal: 20), color: AuraColors.surfaceBorder);
  static String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  static String _getEmoji(String emotion) {
    const map = {
      'joy': '😊', 'trust': '🤝', 'anticipation': '🎯', 'surprise': '😮',
      'sadness': '😢', 'fear': '😰', 'anger': '😠', 'disgust': '🤢',
    };
    return map[emotion] ?? '🧭';
  }

  static String _capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
}

/// Emotional Compass card – hiển thị dominant emotion + confidence + mode
/// Post grid – query Firestore posts của 1 user
class _PostGrid extends StatelessWidget {
  const _PostGrid({required this.userId});
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
        
        if (snap.hasError) {
          return Padding(padding: const EdgeInsets.all(16), child: Text('Error: ${snap.error}', style: TextStyle(color: Colors.red)));
        }

        var posts = snap.data?.docs.map((d) => PostModel.fromFirestore(d)).toList() ?? [];
        posts = posts.where((p) => p.status == 'active').toList();
        posts.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        if (posts.length > 30) posts = posts.sublist(0, 30);

        if (posts.isEmpty) {
          return Padding(padding: const EdgeInsets.all(32), child: Center(
            child: Column(children: [
              Icon(Icons.photo_library_outlined, size: 48, color: AuraColors.textTertiary.withValues(alpha: .4)),
              const SizedBox(height: 8),
              Text('Chưa có bài viết nào', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary)),
            ])));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
            itemCount: posts.length,
            itemBuilder: (context, i) {
              final post = posts[i];
              return GestureDetector(
                onTap: () => context.push('/post/${post.postId}'),
                child: Container(
                  decoration: BoxDecoration(
                    color: AuraColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: post.hasMedia && post.mediaUrls.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(imageUrl: post.mediaUrls.first, fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AuraColors.surfaceVariant),
                          errorWidget: (_, __, ___) => _textPreview(post)))
                    : _textPreview(post),
                ).animate().fadeIn(delay: (i * 50).ms, duration: 300.ms).scale(begin: const Offset(.9, .9), duration: 300.ms),
              );
            },
          ),
        );
      },
    );
  }

  Widget _textPreview(PostModel post) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        AuraColors.getEmotionColor(post.dominantEmotion).withValues(alpha: .15),
        AuraColors.surfaceVariant,
      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(8)),
    child: Center(child: Text(
      post.content.length > 40 ? '${post.content.substring(0, 40)}...' : post.content,
      style: AuraTypography.bodySmall.copyWith(color: AuraColors.textSecondary, fontSize: 10),
      textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis)),
  );
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label, this.onTap});
  final String count;
  final String label;
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
