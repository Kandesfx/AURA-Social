import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/wellbeing_service.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String? _completingId;

  Future<void> _handleComplete(ChallengeItem challenge) async {
    if (_completingId != null) return;
    setState(() {
      _completingId = challenge.id;
    });

    final success = await ref
        .read(activeChallengesProvider.notifier)
        .completeChallenge(challenge.id);

    if (mounted) {
      setState(() {
        _completingId = null;
      });

      if (success) {
        // Show success animation overlay or dialog
        _showSuccessDialog(challenge.title);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật tiến trình. Hãy thử lại sau.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AuraColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AuraColors.surfaceBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AuraColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie Success Animation
              SizedBox(
                height: 150,
                width: 150,
                child: Lottie.network(
                  'https://lottie.host/80eb6d02-4ec4-4cb6-a675-01e408544e39/bXF9kL2b1k.json',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.check_circle_outline_rounded,
                      size: 80,
                      color: AuraColors.success,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chúc Mừng! 🎉',
                style: AuraTypography.titleLarge.copyWith(
                  color: AuraColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đã hoàn thành thử thách:',
                style: AuraTypography.bodySmall.copyWith(
                  color: AuraColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AuraTypography.bodyMedium.copyWith(
                  color: AuraColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Tiếp tục gieo mầm'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(activeChallengesProvider);

    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: AppBar(
        title: const Text('Thử thách tâm hồn'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(activeChallengesProvider.notifier).loadChallenges(),
        color: AuraColors.primary,
        child: challengesAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: AuraColors.primary),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Không thể tải thử thách',
                  style: AuraTypography.titleMedium.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(activeChallengesProvider.notifier).loadChallenges(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuraColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (challenges) {
            if (challenges.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Empty state lottie or icon
                    SizedBox(
                      height: 180,
                      width: 180,
                      child: Lottie.network(
                        'https://lottie.host/890eb1ef-6916-43e9-a359-009989b52a36/jYtJ5TjC8T.json',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.eco_outlined,
                            size: 64,
                            color: AuraColors.primary.withValues(alpha: 0.5),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tất cả đã hoàn thành!',
                      style: AuraTypography.titleMedium.copyWith(
                        color: AuraColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Bạn đã hoàn thành toàn bộ thử thách sức khỏe tinh thần cho ngày hôm nay. Hãy tiếp tục duy trì năng lượng tích cực này nhé!',
                        style: AuraTypography.bodySmall.copyWith(
                          color: AuraColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: challenges.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mỗi ngày một thói quen lành mạnh',
                          style: AuraTypography.displaySmall.copyWith(
                            color: AuraColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AURA thiết kế những thử thách này dựa trên nhịp cảm xúc gần đây của bạn để giúp bạn cân bằng và phục hồi tinh thần.',
                          style: AuraTypography.bodyMedium.copyWith(
                            color: AuraColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final challenge = challenges[index - 1];
                final categoryColor = AuraColors.getEmotionColor(challenge.category);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AuraColors.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AuraColors.surfaceBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              challenge.category.toUpperCase(),
                              style: AuraTypography.labelSmall.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${challenge.durationDays} ngày',
                            style: AuraTypography.labelSmall.copyWith(
                              color: AuraColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        challenge.title,
                        style: AuraTypography.titleMedium.copyWith(
                          color: AuraColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        challenge.description,
                        style: AuraTypography.bodySmall.copyWith(
                          color: AuraColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Tiến độ:',
                                      style: AuraTypography.labelSmall.copyWith(
                                        color: AuraColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${challenge.progress}/${challenge.maxProgress}',
                                      style: AuraTypography.labelSmall.copyWith(
                                        color: AuraColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: challenge.progress / challenge.maxProgress,
                                    backgroundColor: AuraColors.surfaceVariant,
                                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: _completingId == challenge.id
                                ? null
                                : () => _handleComplete(challenge),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: categoryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: _completingId == challenge.id
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Hoàn thành'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
              },
            );
          },
        ),
      ),
    );
  }
}
