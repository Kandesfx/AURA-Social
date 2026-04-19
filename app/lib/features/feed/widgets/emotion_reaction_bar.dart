import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/emotion_types.dart';

/// AURA Social – Emotion Reaction Bar
///
/// Thanh reaction 8 cảm xúc thay cho like/dislike truyền thống.
/// Đây là feature khác biệt cốt lõi của AURA Social.
class EmotionReactionBar extends StatelessWidget {
  const EmotionReactionBar({
    super.key,
    required this.reactions,
    this.onReactionTap,
    this.selectedEmotion,
  });

  /// Map emotion_key → count
  final Map<String, int> reactions;

  /// Callback khi tap 1 reaction
  final void Function(String emotion)? onReactionTap;

  /// Emotion đã chọn (nếu có)
  final String? selectedEmotion;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: EmotionType.values.length,
        separatorBuilder: (_, i) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final emotion = EmotionType.values[index];
          final count = reactions[emotion.key] ?? 0;
          final isSelected = selectedEmotion == emotion.key;

          return GestureDetector(
            onTap: () => onReactionTap?.call(emotion.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AuraColors.getEmotionColor(emotion.key).withValues(alpha: 0.15)
                    : count > 0
                        ? AuraColors.surfaceVariant
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(
                        color: AuraColors.getEmotionColor(emotion.key)
                            .withValues(alpha: 0.5),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emotion.emoji, style: const TextStyle(fontSize: 16)),
                  if (count > 0) ...[
                    const SizedBox(width: 3),
                    Text(
                      _formatCount(count),
                      style: AuraTypography.labelSmall.copyWith(
                        color: isSelected
                            ? AuraColors.getEmotionColor(emotion.key)
                            : AuraColors.textTertiary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
