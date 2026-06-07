import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../../../shared/widgets/aura_parsed_text.dart';
import '../models/post_model.dart';
import 'emotion_reaction_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// AURA Social – Post Card Widget
///
/// Card hiển thị 1 bài post trong feed.
/// Nhận [PostModel] thay vì mock data.
/// Bao gồm: avatar+AuraRing, content, image, emotion reactions, comment count.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.persistReactionChanges = true,
  });

  final PostModel post;
  final bool persistReactionChanges;

  @override
  Widget build(BuildContext context) {
    // Kiểm tra tác giả bài viết
    final currentUser = Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;
    final isAuthor = currentUser != null && currentUser.uid == post.userId;

    // Tạo emotion vector cho AuraRing từ author's dominant emotion
    final authorEmotion = post.authorDominantEmotion ?? 'explore';
    final ringVector = <String, double>{authorEmotion: 0.6, 'trust': 0.2, 'joy': 0.2};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header: Avatar + Name + Time ──
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(children: [
            AuraRing(
              size: 44,
              imageUrl: post.authorAvatarUrl,
              emotionVector: ringVector,
              glowIntensity: 0.3,
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.authorName ?? 'User', style: AuraTypography.titleSmall.copyWith(color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(
                '${post.authorUsername != null ? "@${post.authorUsername}" : ""} · ${_timeAgo(post.createdAt)}',
                style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary),
              ),
            ])),
            if (isAuthor)
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 20),
                color: AuraColors.textTertiary,
                onPressed: () => _showPostOptions(context),
              ),
          ]),
        ),

        // ── Content ──
        if (post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: AuraParsedText(text: post.content, style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary, height: 1.5)),
          ),

        // ── Image ──
        if (post.hasMedia && post.mediaUrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AuraColors.surfaceVariant,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AuraColors.primary))),
                  errorWidget: (_, __, ___) => Container(color: AuraColors.surfaceVariant,
                    child: Icon(Icons.image_not_supported_outlined, color: AuraColors.textTertiary, size: 40)),
                ),
              ),
            ),
          ),

        // ── Emotion Reaction Bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: EmotionReactionBar(
            postId: post.postId,
            reactions: post.reactionsBreakdown,
            persistChanges: persistReactionChanges,
          ),
        ),

        // ── Footer: Comments + Share + Bookmark ──
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(children: [
            _FooterButton(icon: Icons.chat_bubble_outline_rounded, label: '${post.commentsCount}',
              onTap: () => context.push('/post/${post.postId}')),
            const SizedBox(width: 16),
            _FooterButton(icon: Icons.repeat_rounded, label: '${post.sharesCount}', onTap: () {}),
            const Spacer(),
            _FooterButton(icon: Icons.bookmark_outline_rounded, label: '', onTap: () {}),
          ]),
        ),
      ]),
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    return timeago.format(date, locale: 'vi');
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AuraColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit_rounded, color: AuraColors.primary),
                title: Text('Chỉnh sửa bài viết', style: AuraTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/create-post', extra: post);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AuraColors.error),
                title: Text('Xóa bài viết', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Xóa bài viết?',
          style: AuraTypography.titleMedium.copyWith(
            color: AuraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.',
          style: AuraTypography.bodyMedium.copyWith(
            color: AuraColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Hủy',
              style: AuraTypography.labelLarge.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                // Xóa post trên Firestore
                await FirebaseFirestore.instance.collection('posts').doc(post.postId).delete();
                // Giảm số lượng post của user
                await FirebaseFirestore.instance.collection('users').doc(post.userId).update({
                  'posts_count': FieldValue.increment(-1),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa bài viết thành công'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa bài viết: $e'),
                      backgroundColor: AuraColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AuraColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xóa',
              style: AuraTypography.labelLarge.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Row(children: [
      Icon(icon, size: 18, color: AuraColors.textTertiary),
      if (label.isNotEmpty && label != '0') ...[
        const SizedBox(width: 4),
        Text(label, style: AuraTypography.labelMedium.copyWith(color: AuraColors.textTertiary)),
      ],
    ]));
  }
}
