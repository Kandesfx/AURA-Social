import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/emotion_gradients.dart';
import '../models/wave_model.dart';
import 'wave_momentum_bar.dart';

/// AURA Social – Wave Card Widget
///
/// Card hiển thị 1 Emotional Wave trong danh sách.
/// Bao gồm: emoji, title, description, member count,
/// momentum bar, time remaining, join button.
class WaveCard extends StatelessWidget {
  const WaveCard({
    super.key,
    required this.wave,
    required this.onJoin,
    required this.onTap,
    this.isJoined = false,
  });

  final WaveModel wave;
  final VoidCallback onJoin;
  final VoidCallback onTap;
  final bool isJoined;

  @override
  Widget build(BuildContext context) {
    final emotionColor = AuraColors.getEmotionColor(wave.dominantEmotion);
    final cardGradient = EmotionGradients.cardHighlight(wave.dominantEmotion);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: emotionColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: emotionColor.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Emoji + Title + Status ──
            Row(
              children: [
                Text(wave.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wave.title,
                        style: AuraTypography.titleMedium.copyWith(
                          color: AuraColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 14, color: AuraColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${wave.memberCount} người',
                            style: AuraTypography.bodySmall.copyWith(
                              color: AuraColors.textTertiary,
                            ),
                          ),
                          if (wave.timeRemainingText.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_rounded,
                                size: 14, color: AuraColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              'Còn ${wave.timeRemainingText}',
                              style: AuraTypography.bodySmall.copyWith(
                                color: AuraColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                if (wave.status == WaveStatus.fading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AuraColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sắp tàn',
                      style: AuraTypography.labelSmall.copyWith(
                        color: AuraColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Description ──
            Text(
              wave.description,
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // ── Momentum Bar ──
            WaveMomentumBar(momentum: wave.momentum),
            const SizedBox(height: 14),

            // ── Action Row ──
            Row(
              children: [
                // Message count
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 14, color: AuraColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${wave.messageCount}',
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Join / Joined button
                if (isJoined)
                  OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.chat_rounded, size: 16),
                    label: const Text('Vào chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: emotionColor,
                      side: BorderSide(color: emotionColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      textStyle: AuraTypography.labelMedium,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: EmotionGradients.forEmotion(wave.dominantEmotion),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onJoin,
                      icon: Text(wave.emoji, style: const TextStyle(fontSize: 14)),
                      label: const Text('Tham gia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        textStyle: AuraTypography.labelMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
