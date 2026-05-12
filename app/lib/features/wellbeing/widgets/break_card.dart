import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// AURA Social – Wellbeing Break Card
///
/// Person 4, Task #16
/// Card hiển thị khi Wellbeing Guard suggest break.
/// Có 2 variants: 'session_break' và 'positive_inject'.
class WellbeingBreakCard extends StatelessWidget {
  const WellbeingBreakCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.variant,
    this.suggestion,
    this.onDismiss,
    this.onViewCompass,
  });

  final String title;
  final String subtitle;
  final String variant; // 'session_break' | 'positive_inject'
  final String? suggestion;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewCompass;

  @override
  Widget build(BuildContext context) {
    final isSessionBreak = variant == 'session_break';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isSessionBreak
              ? [const Color(0xFF1E3A5F), const Color(0xFF0D1B2A)]
              : [const Color(0xFF1A2F1A), const Color(0xFF0D1B0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isSessionBreak
              ? AuraColors.secondary.withValues(alpha: 0.25)
              : AuraColors.success.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: (isSessionBreak ? AuraColors.secondary : AuraColors.success)
                .withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                isSessionBreak ? '🌙' : '✨',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AuraTypography.titleMedium.copyWith(
                    color: AuraColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Dismiss
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AuraColors.textTertiary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Body
          Text(
            subtitle,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textSecondary,
              height: 1.5,
            ),
          ),

          // Suggestion
          if (suggestion != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
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

          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              if (isSessionBreak && onViewCompass != null) ...[
                ElevatedButton.icon(
                  onPressed: onViewCompass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraColors.secondary.withValues(alpha: 0.2),
                    foregroundColor: AuraColors.secondary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Text('🧭', style: TextStyle(fontSize: 14)),
                  label: Text('Xem Aura', style: AuraTypography.labelMedium),
                ),
                const SizedBox(width: 10),
              ],
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'Tiếp tục',
                  style: AuraTypography.labelMedium.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
