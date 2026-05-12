import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../models/soul_connection_model.dart';
import 'compatibility_breakdown.dart';

/// AURA Social – Soul Card Widget
///
/// Card hiển thị một soul suggestion.
/// Bao gồm: avatar + Aura Ring, tên, bio, soul score,
/// connection type badge, compatibility breakdown, action buttons.
class SoulCard extends StatelessWidget {
  const SoulCard({
    super.key,
    required this.suggestion,
    required this.onAccept,
    required this.onReject,
    this.isProcessing = false,
  });

  final SoulSuggestion suggestion;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final user = suggestion.otherUser;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AuraColors.surfaceVariant,
            AuraColors.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AuraColors.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Avatar with Aura Ring ──
          AuraRing(
            size: 100,
            emotionVector: user.emotionVector,
          ),
          const SizedBox(height: 16),

          // ── Name ──
          Text(
            user.displayName,
            style: AuraTypography.headlineMedium.copyWith(
              color: AuraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // ── Bio ──
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            Text(
              user.bio!,
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // ── Connection Type Badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AuraColors.tertiary.withValues(alpha: 0.15),
                  AuraColors.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AuraColors.tertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '💜 ${suggestion.connectionType}',
              style: AuraTypography.labelMedium.copyWith(
                color: AuraColors.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Soul Score ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AuraColors.primary.withValues(alpha: 0.15),
                  AuraColors.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔮', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Soul Score: ',
                  style: AuraTypography.labelLarge.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AuraColors.primaryGradient.createShader(bounds),
                  child: TweenAnimationBuilder<int>(
                    tween: IntTween(
                      begin: 0,
                      end: (suggestion.soulScore * 100).round(),
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Text(
                        '$value%',
                        style: AuraTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Compatibility Breakdown ──
          CompatibilityBreakdownWidget(
            breakdown: suggestion.breakdown,
          ),
          const SizedBox(height: 24),

          // ── Action Buttons ──
          Row(
            children: [
              // Skip button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : onReject,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Bỏ qua'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AuraColors.textTertiary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: AuraColors.surfaceBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Connect button
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AuraColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AuraColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : onAccept,
                    icon: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.favorite_rounded, size: 18),
                    label: Text(isProcessing ? 'Đang...' : 'Kết nối'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.95, 0.95),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }
}
