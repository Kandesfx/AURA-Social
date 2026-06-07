import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/soul_connection_model.dart';

/// AURA Social – Compatibility Breakdown Widget
///
/// 5 progress bars hiển thị chi tiết tương thích giữa 2 users.
/// Mỗi bar: label + animated progress + percentage.
class CompatibilityBreakdownWidget extends StatelessWidget {
  const CompatibilityBreakdownWidget({
    super.key,
    required this.breakdown,
  });

  final CompatibilityBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final items = [
      _BarData('Emotion', breakdown.emotionalPattern, AuraColors.emotionJoy),
      _BarData('Content', breakdown.contentTaste, AuraColors.emotionTrust),
      _BarData('Activity', breakdown.activity, AuraColors.emotionAnticipation),
      _BarData('Social', breakdown.complementary, AuraColors.emotionSurprise),
      _BarData('Interest', breakdown.interests, AuraColors.emotionSadness),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _CompatibilityBar(
            label: items[i].label,
            value: items[i].value,
            color: items[i].color,
          ).animate(delay: Duration(milliseconds: 200 + i * 100))
           .fadeIn(duration: 400.ms)
           .slideX(begin: -0.1, duration: 400.ms),
          if (i < items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BarData {
  final String label;
  final double value;
  final Color color;
  _BarData(this.label, this.value, this.color);
}

class _CompatibilityBar extends StatelessWidget {
  const _CompatibilityBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: AuraTypography.labelMedium.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  backgroundColor: AuraColors.surfaceBorder,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: AuraTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
