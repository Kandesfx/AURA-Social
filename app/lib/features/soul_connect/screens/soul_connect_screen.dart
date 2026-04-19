import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';

/// AURA Social – Soul Connect Screen
///
/// Gợi ý kết nối dựa trên emotional compatibility.
class SoulConnectScreen extends StatelessWidget {
  const SoulConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo_icon.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Soul Connect'),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Demo Soul Card
              Container(
                width: double.infinity,
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
                  children: [
                    AuraRing(
                      size: 100,
                      emotionVector: {
                        'joy': 0.3,
                        'trust': 0.25,
                        'anticipation': 0.2,
                        'surprise': 0.1,
                        'sadness': 0.05,
                        'fear': 0.04,
                        'anger': 0.03,
                        'disgust': 0.03,
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Trần Minh Anh',
                      style: AuraTypography.headlineMedium.copyWith(
                        color: AuraColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 Hà Nội',
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Soul Score
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
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
                            child: Text(
                              '87%',
                              style: AuraTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Compatibility bars
                    _CompatBar(label: 'Emotional', value: 0.92, color: AuraColors.emotionJoy),
                    const SizedBox(height: 8),
                    _CompatBar(label: 'Content', value: 0.85, color: AuraColors.emotionTrust),
                    const SizedBox(height: 8),
                    _CompatBar(label: 'Activity', value: 0.78, color: AuraColors.emotionAnticipation),
                    const SizedBox(height: 8),
                    _CompatBar(label: 'Social', value: 0.88, color: AuraColors.emotionSurprise),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Bỏ qua'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AuraColors.textTertiary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.favorite_rounded, size: 18),
                            label: const Text('Kết nối'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).scale(
                    begin: const Offset(0.95, 0.95),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompatBar extends StatelessWidget {
  const _CompatBar({
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
          width: 72,
          child: Text(
            label,
            style: AuraTypography.labelMedium.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AuraColors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).round()}%',
          style: AuraTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
