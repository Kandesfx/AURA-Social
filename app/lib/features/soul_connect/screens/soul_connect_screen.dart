import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/soul_provider.dart';
import '../widgets/swipe_card.dart';

/// AURA Social – Soul Connect Screen
///
/// Person 3, Task #12
/// Gợi ý kết nối dựa trên emotional compatibility.
/// - AsyncValue handling: loading/error/data
/// - Swipeable card stack
/// - Accept/reject logic gọi API
class SoulConnectScreen extends ConsumerWidget {
  const SoulConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(soulSuggestionsProvider);
    final currentIndex = ref.watch(currentSoulIndexProvider);
    final actionState = ref.watch(soulActionProvider);

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
                  Icons.favorite_rounded,
                  size: 24,
                  color: AuraColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Soul Connect'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            onPressed: () => _showInfoSheet(context),
          ),
        ],
      ),
      body: suggestionsAsync.when(
        loading: () => _buildLoading(),
        error: (error, _) => _buildError(context, ref, error),
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return _buildEmpty();
          }

          return Column(
            children: [
              // ── Progress indicator ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${currentIndex + 1}',
                      style: AuraTypography.labelLarge.copyWith(
                        color: AuraColors.primary,
                      ),
                    ),
                    Text(
                      ' / ${suggestions.length}',
                      style: AuraTypography.labelMedium.copyWith(
                        color: AuraColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: suggestions.isEmpty
                              ? 0
                              : (currentIndex + 1) / suggestions.length,
                          backgroundColor: AuraColors.surfaceBorder,
                          valueColor: AlwaysStoppedAnimation(
                            AuraColors.primary.withValues(alpha: 0.7),
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              // ── Hint ──
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '← Vuốt để bỏ qua • Vuốt để kết nối →',
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              // ── Card Stack ──
              Expanded(
                child: SwipeCardStack(
                  suggestions: suggestions,
                  currentIndex: currentIndex,
                  isProcessing: actionState.isProcessing,
                  onAccept: (suggestion) {
                    ref.read(soulActionProvider.notifier).accept(
                          suggestion.connectionId,
                        );
                    ref.read(currentSoulIndexProvider.notifier).state++;
                  },
                  onReject: (suggestion) {
                    ref.read(soulActionProvider.notifier).reject(
                          suggestion.connectionId,
                        );
                    ref.read(currentSoulIndexProvider.notifier).state++;
                  },
                ),
              ),
            ],
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
              color: AuraColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AuraColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tìm tâm hồn đồng điệu...',
            style: AuraTypography.bodyLarge.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI đang phân tích emotional compatibility',
            style: AuraTypography.bodySmall.copyWith(
              color: AuraColors.textTertiary,
            ),
          ),
        ],
      ).animate()
          .fadeIn(duration: 500.ms)
          .shimmer(delay: 500.ms, duration: 1500.ms),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AuraColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AuraColors.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không thể tải gợi ý',
              style: AuraTypography.headlineSmall.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Có lỗi xảy ra khi kết nối tới server.\nHãy thử lại sau.',
              textAlign: TextAlign.center,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(soulSuggestionsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AuraColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 48,
                color: AuraColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có gợi ý nào',
              style: AuraTypography.headlineSmall.copyWith(
                color: AuraColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tiếp tục sử dụng AURA để AI\nhiểu bạn hơn và tìm những người phù hợp! 💜',
              textAlign: TextAlign.center,
              style: AuraTypography.bodyMedium.copyWith(
                color: AuraColors.textTertiary,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, duration: 500.ms),
      ),
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AuraColors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '💜 Soul Connect là gì?',
                  style: AuraTypography.headlineSmall.copyWith(
                    color: AuraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Soul Connect sử dụng AI để phân tích emotional compatibility giữa bạn và người dùng khác. '
                  'Dựa trên behavioral patterns, emotional responses, và content preferences, '
                  'AI sẽ tìm những người có "soul score" cao nhất với bạn.',
                  style: AuraTypography.bodyMedium.copyWith(
                    color: AuraColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                _InfoItem(icon: '🔮', text: 'Soul Score: Mức độ tương thích tổng thể'),
                _InfoItem(icon: '❤️', text: 'Emotional: Cùng cảm xúc, cùng vibe'),
                _InfoItem(icon: '📝', text: 'Content: Sở thích nội dung giống nhau'),
                _InfoItem(icon: '🎯', text: 'Activity: Hoạt động trên app tương tự'),
                _InfoItem(icon: '🤝', text: 'Social: Mối quan hệ xã hội bổ trợ'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AuraTypography.bodySmall.copyWith(
                color: AuraColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
