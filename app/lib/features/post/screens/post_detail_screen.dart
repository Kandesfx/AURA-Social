import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../../../shared/widgets/aura_parsed_text.dart';
import '../../feed/models/post_model.dart';
import '../../feed/widgets/emotion_reaction_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// AURA Social – Post Detail Screen
///
/// Hiển thị full post + danh sách comments (stream Firestore).
/// Cho phép thêm comment mới.
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _commentFocusNode = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentCtrl.text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final comment = CommentModel(
        commentId: '',
        userId: user.uid,
        content: _commentCtrl.text.trim(),
        authorName: userData['display_name'] ?? user.displayName ?? '',
        authorAvatarUrl: userData['avatar_url'],
      );

      await FirebaseFirestore.instance
          .collection('posts').doc(widget.postId)
          .collection('comments')
          .add(comment.toFirestore());

      // Update comment count
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        'comments_count': FieldValue.increment(1),
      });

      _commentCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'), backgroundColor: AuraColors.error));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: Column(children: [
        Expanded(child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
          builder: (context, postSnap) {
            if (postSnap.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: AuraColors.primary));
            }
            if (!postSnap.hasData || !postSnap.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              });
              return Center(
                child: Text(
                  'Bài viết không tồn tại hoặc đã bị xóa',
                  style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary),
                ),
              );
            }

            final post = PostModel.fromFirestore(postSnap.data!);

            return CustomScrollView(slivers: [
              // Post content
              SliverToBoxAdapter(
                child: _PostContent(
                  post: post,
                  onCommentTap: () => _commentFocusNode.requestFocus(),
                ),
              ),

              // Divider
              SliverToBoxAdapter(child: Divider(color: AuraColors.surfaceBorder, height: 1)),

              // Comments header
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Bình luận (${post.commentsCount})', style: AuraTypography.titleSmall.copyWith(color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
              )),

              // Comments list
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts').doc(widget.postId)
                    .collection('comments')
                    .orderBy('created_at', descending: false)
                    .snapshots(),
                builder: (context, commentSnap) {
                  final comments = commentSnap.data?.docs
                      .map((d) => CommentModel.fromFirestore(d)).toList() ?? [];

                  if (comments.isEmpty) {
                    return SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text('Chưa có bình luận', style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textTertiary))),
                    ));
                  }

                  return SliverList(delegate: SliverChildBuilderDelegate(
                    (context, i) => _CommentTile(comment: comments[i], postId: widget.postId)
                        .animate().fadeIn(delay: (i * 50).ms, duration: 300.ms),
                    childCount: comments.length,
                  ));
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ]);
          },
        )),

        // Comment input
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(color: AuraColors.surface, border: Border(top: BorderSide(color: AuraColors.surfaceBorder, width: .5))),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _commentCtrl,
              focusNode: _commentFocusNode,
              enabled: !_sending,
              style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Viết bình luận...', isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AuraColors.surfaceBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AuraColors.surfaceBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: AuraColors.primary)),
                filled: true, fillColor: AuraColors.surfaceVariant,
              ),
              onSubmitted: (_) => _addComment(),
            )),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _addComment,
              icon: _sending
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AuraColors.primary))
                : Icon(Icons.send_rounded, color: AuraColors.primary),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PostContent extends StatelessWidget {
  const _PostContent({required this.post, required this.onCommentTap});
  final PostModel post;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context) {
    final ringVector = <String, double>{(post.authorDominantEmotion ?? 'joy'): 0.6, 'trust': 0.2, 'joy': 0.2};
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        AuraRing(size: 48, imageUrl: post.authorAvatarUrl, emotionVector: ringVector, glowIntensity: .3),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(post.authorName ?? 'User', style: AuraTypography.titleSmall.copyWith(color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
          Text('${post.authorUsername != null ? "@${post.authorUsername}" : ""} · ${post.createdAt != null ? timeago.format(post.createdAt!, locale: 'vi') : ''}',
            style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary)),
        ])),
        if (FirebaseAuth.instance.currentUser?.uid == post.userId)
          IconButton(
            icon: const Icon(Icons.more_horiz, size: 20),
            color: AuraColors.textTertiary,
            onPressed: () => _showPostOptions(context),
          ),
      ]),
      const SizedBox(height: 16),
      if (post.content.isNotEmpty) AuraParsedText(text: post.content, style: AuraTypography.bodyLarge.copyWith(color: AuraColors.textPrimary, height: 1.6)),
      if (post.hasMedia && post.mediaUrls.isNotEmpty) ...[
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(imageUrl: post.mediaUrls.first, width: double.infinity, fit: BoxFit.cover,
            placeholder: (_, __) => Container(height: 200, color: AuraColors.surfaceVariant),
            errorWidget: (_, __, ___) => Container(height: 200, color: AuraColors.surfaceVariant, child: Icon(Icons.image_not_supported, color: AuraColors.textTertiary)))),
      ],
      const SizedBox(height: 12),
      EmotionReactionBar(postId: post.postId, reactions: post.reactionsBreakdown),
      const SizedBox(height: 16),
      Row(children: [
        _FooterButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: '${post.commentsCount}',
          onTap: onCommentTap,
        ),
        const SizedBox(width: 16),
        _FooterButton(
          icon: Icons.repeat_rounded,
          label: '${post.sharesCount}',
          onTap: () {},
        ),
        const Spacer(),
        _FooterButton(
          icon: Icons.bookmark_outline_rounded,
          label: '',
          onTap: () {},
        ),
      ]),
    ]));
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.postId});
  final CommentModel comment;
  final String postId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AuraRing(size: 36, imageUrl: comment.authorAvatarUrl, glowIntensity: .2),
        const SizedBox(width: 10),
        Expanded(child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AuraColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(comment.authorName ?? 'User', style: AuraTypography.labelMedium.copyWith(color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(comment.createdAt != null ? timeago.format(comment.createdAt!, locale: 'vi') : '',
                style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary, fontSize: 11)),
              // Delete button nếu là author
              if (uid == comment.userId) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () async {
                    await FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').doc(comment.commentId).delete();
                    await FirebaseFirestore.instance.collection('posts').doc(postId).update({'comments_count': FieldValue.increment(-1)});
                  },
                  child: Icon(Icons.close, size: 14, color: AuraColors.textTertiary),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Text(comment.content, style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textPrimary, height: 1.4)),
          ]),
        )),
      ]),
    );
  }
}
