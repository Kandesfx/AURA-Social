import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/settings_provider.dart';

/// AURA Social – AI Settings Screen
///
/// Person 4, Task #10
/// Toggle ON/OFF các tính năng AI của AURA.
class AISettingsScreen extends ConsumerWidget {
  const AISettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt AI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Header Card ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AuraColors.primary.withValues(alpha: 0.1),
                  AuraColors.secondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AuraColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AuraColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🤖', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AURA AI Engine',
                          style: AuraTypography.titleMedium.copyWith(
                            color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Quản lý cách AI hiểu và hỗ trợ bạn',
                          style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

          const SizedBox(height: 20),

          // ── AI Features ──
          _buildAIToggle(
            ref: ref,
            icon: '🧠',
            title: 'Phân tích Cảm xúc',
            subtitle: 'AI phân tích cảm xúc từ bài viết, reaction và hành vi của bạn để tạo Emotion Profile.',
            value: settings.emotionalAnalysis,
            onChanged: (v) => ref.read(settingsProvider.notifier).setEmotionalAnalysis(v),
            delay: 0,
          ),

          _buildAIToggle(
            ref: ref,
            icon: '📊',
            title: 'Theo dõi Hành vi',
            subtitle: 'Ghi nhận scroll, view, interaction để cải thiện nội dung. Dữ liệu tự xóa sau 30 ngày.',
            value: settings.behavioralTracking,
            onChanged: (v) => ref.read(settingsProvider.notifier).setBehavioralTracking(v),
            delay: 50,
          ),

          _buildAIToggle(
            ref: ref,
            icon: '✨',
            title: 'Gợi ý Nội dung',
            subtitle: 'For You feed được cá nhân hóa dựa trên cảm xúc và sở thích của bạn.',
            value: settings.contentRecommendations,
            onChanged: (v) => ref.read(settingsProvider.notifier).setContentRecommendations(v),
            delay: 100,
          ),

          _buildAIToggle(
            ref: ref,
            icon: '💜',
            title: 'Soul Connect AI',
            subtitle: 'Tìm kiếm người có cùng "tần số cảm xúc" để kết nối.',
            value: settings.soulConnectAI,
            onChanged: (v) => ref.read(settingsProvider.notifier).setSoulConnectAI(v),
            delay: 150,
          ),

          _buildAIToggle(
            ref: ref,
            icon: '🛡️',
            title: 'Wellbeing Guard',
            subtitle: 'Nhắc nghỉ khi sử dụng lâu, inject nội dung tích cực khi phát hiện cảm xúc tiêu cực.',
            value: settings.wellbeingGuard,
            onChanged: (v) => ref.read(settingsProvider.notifier).setWellbeingGuard(v),
            delay: 200,
          ),

          const SizedBox(height: 16),

          // ── Privacy note ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AuraColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.privacy_tip_outlined, size: 18,
                    color: AuraColors.textTertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dữ liệu AI được xử lý ẩn danh và tự động xóa sau 30 ngày. '
                    'Bạn có thể xuất hoặc xóa toàn bộ dữ liệu trong Quyền riêng tư.',
                    style: AuraTypography.bodySmall.copyWith(color: AuraColors.textTertiary),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 300.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAIToggle({
    required WidgetRef ref,
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AuraColors.primary.withValues(alpha: 0.2)
              : AuraColors.surfaceBorder,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? AuraColors.primary.withValues(alpha: 0.1)
                : AuraColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(title, style: AuraTypography.bodyLarge.copyWith(
          color: AuraColors.textPrimary, fontWeight: FontWeight.w500)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: AuraTypography.bodySmall.copyWith(
            color: AuraColors.textTertiary)),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AuraColors.primary,
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: delay.ms).slideX(begin: 0.02);
  }
}
