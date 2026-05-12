import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../models/post_model.dart';
import 'emotion_reaction_bar.dart';

/// AURA Social – Post Card Widget
///
/// Card hiển thị 1 bài post trong feed.
/// Nhận [PostModel] thay vì mock data.
/// Bao gồm: avatar+AuraRing, content, image, emotion reactions, comment count.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
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
            IconButton(icon: const Icon(Icons.more_horiz, size: 20), color: AuraColors.textTertiary, onPressed: () {}),
          ]),
        ),

        // ── Content ──
        if (post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(post.content, style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary, height: 1.5)),
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
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AuraColors.primary))),
                  errorWidget: (_, __, ___) => Container(color: AuraColors.surfaceVariant,
                    child: const Icon(Icons.image_not_supported_outlined, color: AuraColors.textTertiary, size: 40)),
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
