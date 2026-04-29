import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// AURA Social – AI Status Bar
///
/// Person 4, Task #17
/// "🤖 Đang hiểu bạn..." animated indicator.
/// Hiển thị current emotional mode + AI processing status.
///
/// Usage:
/// ```dart
/// AIStatusBar(
///   emotionalMode: 'explore',
///   isProcessing: true,
/// )
/// ```
class AIStatusBar extends StatelessWidget {
  const AIStatusBar({
    super.key,
    this.emotionalMode = 'explore',
    this.isProcessing = true,
    this.onTap,
  });

  final String emotionalMode;
  final bool isProcessing;
  final VoidCallback? onTap;

  static const _modeMap = {
    'gentle_uplift': {'emoji': '🌤️', 'label': 'Nâng đỡ', 'color': 'joy'},
    'empathetic_mirror': {'emoji': '🪞', 'label': 'Đồng cảm', 'color': 'trust'},
    'amplify': {'emoji': '🚀', 'label': 'Khuếch đại', 'color': 'anticipation'},
    'deep_chill': {'emoji': '🌙', 'label': 'Thư giãn', 'color': 'sadness'},
    'explore': {'emoji': '🧭', 'label': 'Khám phá', 'color': 'surprise'},
  };

  @override
  Widget build(BuildContext context) {
    final mode = _modeMap[emotionalMode] ?? _modeMap['explore']!;
    final modeColor = AuraColors.getEmotionColor(mode['color'] as String);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              modeColor.withValues(alpha: 0.08),
              AuraColors.primary.withValues(alpha: 0.04),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: modeColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // AI indicator dot
            if (isProcessing)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AuraColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AuraColors.success.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .fadeIn(duration: 1000.ms)
               .then()
               .fadeOut(duration: 1000.ms),

            // Status text
            Text(
              isProcessing ? '🤖 Đang hiểu bạn...' : '🤖 AI sẵn sàng',
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.textSecondary,
              ),
            ),

            const Spacer(),

            // Mode badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: modeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mode['emoji'] as String, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    mode['label'] as String,
                    style: AuraTypography.labelSmall.copyWith(
                      color: modeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
