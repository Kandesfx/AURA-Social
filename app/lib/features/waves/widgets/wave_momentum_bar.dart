import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Wave Momentum Bar
///
/// Animated progress bar hiển thị momentum (0.0 - 1.0) của Wave.
/// Color-coded: green (high), yellow (medium), red (low).
class WaveMomentumBar extends StatelessWidget {
  const WaveMomentumBar({
    super.key,
    required this.momentum,
    this.height = 5,
    this.showLabel = true,
  });

  final double momentum;
  final double height;
  final bool showLabel;

  Color get _color {
    if (momentum > 0.6) return AuraColors.success;
    if (momentum > 0.3) return AuraColors.warning;
    return AuraColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: momentum),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: AuraColors.surfaceBorder,
                  valueColor: AlwaysStoppedAnimation(_color),
                  minHeight: height,
                );
              },
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            '${(momentum * 100).round()}%',
            style: AuraTypography.labelSmall.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
