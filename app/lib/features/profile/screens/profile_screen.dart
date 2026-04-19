import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';

/// AURA Social – Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Avatar + Aura Ring ──
            Builder(
              builder: (context) {
                final ring = AuraRing(
                  size: 110,
                  emotionVector: const {
                    'joy': 0.3, 'trust': 0.2, 'anticipation': 0.25,
                    'surprise': 0.1, 'sadness': 0.05, 'fear': 0.04,
                    'anger': 0.03, 'disgust': 0.03,
                  },
                  glowIntensity: 0.5,
                );
                return ring;
              },
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 16),

            // ── Name ──
            Text(
              'Nguyễn Hải',
              style: AuraTypography.headlineMedium.copyWith(
                color: AuraColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@hai_nguyen',
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),

            // ── Bio ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Dreamer. Coffee lover ☕ | Building things that matter 🚀',
                style: AuraTypography.bodyMedium.copyWith(
                  color: AuraColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats Row ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatItem(count: '42', label: 'Posts'),
                _divider(),
                _StatItem(count: '1.2K', label: 'Followers'),
                _divider(),
                _StatItem(count: '89', label: 'Following'),
                _divider(),
                _StatItem(count: '7', label: 'Soul'),
              ],
            ),

            const SizedBox(height: 20),

            // ── Edit Profile Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Edit Profile'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Emotional Compass Card ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AuraColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🧭', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emotional Compass',
                          style: AuraTypography.titleSmall.copyWith(
                            color: AuraColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Mood: ',
                              style: AuraTypography.bodySmall.copyWith(
                                color: AuraColors.textTertiary,
                              ),
                            ),
                            Text(
                              '🎯 Anticipation',
                              style: AuraTypography.bodySmall.copyWith(
                                color: AuraColors.emotionAnticipation,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '📊 78%',
                              style: AuraTypography.bodySmall.copyWith(
                                color: AuraColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AuraColors.textTertiary,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms)
             .slideX(begin: 0.03),

            const SizedBox(height: 24),

            // ── Post Grid ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Posts',
                    style: AuraTypography.titleMedium.copyWith(
                      color: AuraColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.grid_view_rounded,
                      size: 20, color: AuraColors.primary),
                  const SizedBox(width: 12),
                  Icon(Icons.view_list_rounded,
                      size: 20, color: AuraColors.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final colors = [
                    AuraColors.emotionJoy,
                    AuraColors.emotionTrust,
                    AuraColors.emotionAnticipation,
                    AuraColors.emotionSurprise,
                    AuraColors.emotionSadness,
                    AuraColors.emotionFear,
                    AuraColors.primary,
                    AuraColors.secondary,
                    AuraColors.tertiary,
                  ];
                  return Container(
                    decoration: BoxDecoration(
                      color: colors[index % colors.length].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image_rounded,
                      color: colors[index % colors.length].withValues(alpha: 0.4),
                      size: 32,
                    ),
                  ).animate()
                   .fadeIn(delay: (index * 60).ms, duration: 300.ms)
                   .scale(begin: const Offset(0.9, 0.9), duration: 300.ms);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 28,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: AuraColors.surfaceBorder,
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.count, required this.label});

  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: AuraTypography.headlineSmall.copyWith(
            color: AuraColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AuraTypography.labelSmall.copyWith(
            color: AuraColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
