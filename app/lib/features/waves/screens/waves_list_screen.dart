import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/waves_provider.dart';
import '../widgets/wave_card.dart';

/// AURA Social – Waves List Screen
///
/// Person 3, Task #16
/// Hiển thị danh sách Emotional Waves đang hoạt động.
/// - AsyncValue handling
/// - Join/Leave waves
/// - Navigate to wave chat
class WavesListScreen extends ConsumerWidget {
  const WavesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wavesAsync = ref.watch(activeWavesProvider);
    final joinedIds = ref.watch(joinedWaveIdsProvider);
    final totalUsers = ref.watch(totalWaveUsersProvider);

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
                errorBuilder: (_, __, ___) => Icon(
                  Icons.waves_rounded,
                  size: 24,
                  color: AuraColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Emotional Waves'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            onPressed: () => _showInfoSheet(context),
          ),
        ],
      ),
      body: wavesAsync.when(
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(ref),
        data: (waves) {
          if (waves.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activeWavesProvider),
            color: AuraColors.primary,
            backgroundColor: AuraColors.surface,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              children: [
                // ── Header Stats ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AuraColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('🌊', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '$totalUsers người đang cùng vibe',
                              style: AuraTypography.labelMedium.copyWith(
                                color: AuraColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                // ── Active Waves ──
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 12, bottom: 8),
                  child: Text(
                    'Đang hoạt động (${waves.where((w) => w.status.value == 'active').length})',
                    style: AuraTypography.titleSmall.copyWith(
                      color: AuraColors.textSecondary,
                    ),
                  ),
                ),

                ...waves.asMap().entries.map((entry) {
                  final index = entry.key;
                  final wave = entry.value;
                  final isJoined = joinedIds.contains(wave.id);

                  return WaveCard(
                    wave: wave,
                    isJoined: isJoined,
                    onJoin: () {
                      ref.read(joinedWaveIdsProvider.notifier).update(
                        (state) => {...state, wave.id},
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã tham gia ${wave.title} ${wave.emoji}'),
                          backgroundColor: AuraColors.surfaceHigh,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onTap: () {
                      if (!isJoined) {
                        ref.read(joinedWaveIdsProvider.notifier).update(
                          (state) => {...state, wave.id},
                        );
                      }
                      context.push('/wave/${wave.id}');
                    },
                  ).animate(delay: Duration(milliseconds: 100 + index * 80))
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, duration: 400.ms);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AuraColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AuraColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang dò sóng cảm xúc...',
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: AuraColors.error.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Không thể tải waves',
            style: AuraTypography.headlineSmall.copyWith(
              color: AuraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(activeWavesProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Chưa có wave nào',
            style: AuraTypography.headlineSmall.copyWith(
              color: AuraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waves được tạo tự động bởi AI\nkhi phát hiện nhóm người có cảm xúc tương tự.',
            textAlign: TextAlign.center,
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textTertiary,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AuraColors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '🌊 Emotional Waves là gì?',
                  style: AuraTypography.headlineSmall.copyWith(
                    color: AuraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AI phát hiện nhóm người đang có cảm xúc tương tự (ví dụ: '
                  'thức khuya, stress deadline, vui cuối tuần) và tự động '
                  'tạo "wave" – một nhóm chat tạm thời để mọi người kết nối.\n\n'
                  'Waves có "momentum" – khi ít người hoạt động, wave sẽ tự fade.',
                  style: AuraTypography.bodyMedium.copyWith(
                    color: AuraColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
