import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/emotion_types.dart';

/// AURA Social – Emotion Reaction Bar (Connected to Firestore)
///
/// Thanh reaction 8 cảm xúc (Plutchik). Tap → ghi/xóa reaction vào Firestore.
/// Toggle: tap lần 1 = react, tap lần 2 = unreact.
///
/// ### Firestore writes:
/// - `posts/{postId}.reactions_breakdown.{emotion}` ± 1
/// - `posts/{postId}.reactions_count` ± 1
/// - `posts/{postId}/reactions/{userId}` = {emotion, timestamp}
class EmotionReactionBar extends StatefulWidget {
  const EmotionReactionBar({
    super.key,
    required this.postId,
    required this.reactions,
  });

  final String postId;
  final Map<String, int> reactions;

  @override
  State<EmotionReactionBar> createState() => _EmotionReactionBarState();
}

class _EmotionReactionBarState extends State<EmotionReactionBar> {
  String? _selectedEmotion;
  late Map<String, int> _localReactions;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _localReactions = Map.from(widget.reactions);
    _loadMyReaction();
  }

  /// Load reaction hiện tại của user từ Firestore
  Future<void> _loadMyReaction() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('posts').doc(widget.postId)
        .collection('reactions').doc(uid).get();

    if (doc.exists && mounted) {
      setState(() => _selectedEmotion = doc.data()?['emotion']);
    }
  }

  /// Toggle reaction: tap = react, tap lại = unreact
  Future<void> _toggleReaction(String emotion) async {
    if (_processing) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _processing = true;
    HapticFeedback.lightImpact();

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final reactionRef = postRef.collection('reactions').doc(uid);
    final oldEmotion = _selectedEmotion;

    setState(() {
      if (oldEmotion == emotion) {
        // Unreact
        _selectedEmotion = null;
        _localReactions[emotion] = (_localReactions[emotion] ?? 1) - 1;
      } else {
        // Remove old reaction first
        if (oldEmotion != null) {
          _localReactions[oldEmotion] = (_localReactions[oldEmotion] ?? 1) - 1;
        }
        // Add new reaction
        _selectedEmotion = emotion;
        _localReactions[emotion] = (_localReactions[emotion] ?? 0) + 1;
      }
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      if (oldEmotion == emotion) {
        // Unreact: xóa reaction document + giảm count
        batch.delete(reactionRef);
        batch.update(postRef, {
          'reactions_count': FieldValue.increment(-1),
          'reactions_breakdown.$emotion': FieldValue.increment(-1),
        });
      } else {
        if (oldEmotion != null) {
          // Thay đổi reaction: giảm cũ, tăng mới
          batch.update(postRef, {
            'reactions_breakdown.$oldEmotion': FieldValue.increment(-1),
            'reactions_breakdown.$emotion': FieldValue.increment(1),
          });
        } else {
          // React mới: tăng count
          batch.update(postRef, {
            'reactions_count': FieldValue.increment(1),
            'reactions_breakdown.$emotion': FieldValue.increment(1),
          });
        }
        batch.set(reactionRef, {
          'emotion': emotion,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      // Rollback UI nếu Firestore fail
      if (mounted) {
        setState(() {
          _selectedEmotion = oldEmotion;
          _localReactions = Map.from(widget.reactions);
        });
      }
    }
    _processing = false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: EmotionType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final emotion = EmotionType.values[index];
          final count = _localReactions[emotion.key] ?? 0;
          final isSelected = _selectedEmotion == emotion.key;

          return GestureDetector(
            onTap: () => _toggleReaction(emotion.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AuraColors.getEmotionColor(emotion.key).withValues(alpha: .15)
                    : count > 0 ? AuraColors.surfaceVariant : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? Border.all(
                  color: AuraColors.getEmotionColor(emotion.key).withValues(alpha: .5), width: 1) : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(emotion.emoji, style: const TextStyle(fontSize: 16)),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 3),
                  Text(_fmt(count), style: AuraTypography.labelSmall.copyWith(
                    color: isSelected ? AuraColors.getEmotionColor(emotion.key) : AuraColors.textTertiary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
