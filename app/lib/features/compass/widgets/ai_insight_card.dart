import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – AI Insight Card
///
/// Person 4, Task #15
/// Glassmorphism card hiển thị AI-generated insight.
class AIInsightCard extends StatelessWidget {
  const AIInsightCard({
    super.key,
    required this.insight,
    this.suggestion,
    this.wellbeingScore,
  });

  final String insight;
  final String? suggestion;
  final int? wellbeingScore;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AuraColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('💡', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Insight',
                style: AuraTypography.titleSmall.copyWith(
                  color: AuraColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Insight text
          Text(
            insight,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textSecondary,
              height: 1.6,
            ),
          ),

          // Suggestion
          if (suggestion != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AuraColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion!,
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Wellbeing Score
          if (wellbeingScore != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Wellbeing Score',
                  style: AuraTypography.labelMedium.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🌟', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$wellbeingScore/100',
                        style: AuraTypography.labelMedium.copyWith(
                          color: _scoreColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color get _scoreColor {
    if (wellbeingScore == null) return AuraColors.textTertiary;
    if (wellbeingScore! >= 75) return AuraColors.success;
    if (wellbeingScore! >= 50) return AuraColors.warning;
    return AuraColors.error;
  }
}
