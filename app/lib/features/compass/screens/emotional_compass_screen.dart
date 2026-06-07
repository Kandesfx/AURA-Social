import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../widgets/emotion_radar_chart.dart';
import '../widgets/emotion_timeline.dart';
import '../widgets/ai_insight_card.dart';
import '../../../providers/emotion_profile_provider.dart';
import '../../../shared/models/emotion_profile_model.dart';
import '../../../services/wellbeing_service.dart';

/// AURA Social – Emotional Compass Screen
///
/// Person 4, Task #12
/// Full emotional profile view: radar chart, 7-day timeline, AI insights.
class EmotionalCompassScreen extends ConsumerWidget {
  const EmotionalCompassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportProvider);
    final emotionProfileAsync = ref.watch(currentEmotionProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('La bàn cảm xúc'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            onPressed: () => _showInfoSheet(context),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AuraColors.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Không thể tải báo cáo tâm trạng',
                style: AuraTypography.titleMedium.copyWith(
                  color: AuraColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(weeklyReportProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuraColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (report) {
          final profile = emotionProfileAsync.valueOrNull ?? const EmotionProfileModel();
          final rawDistribution = report['mood_distribution'];
          final emotionVector = rawDistribution is Map
              ? Map<String, dynamic>.from(rawDistribution).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
              : <String, double>{};
          
          final dominant = report['dominant_emotion'] as String? ?? 'explore';
          final stabilityLabel = report['stability_label'] as String? ?? 'Ổn định';
          final stabilityIndex = (report['stability_index'] as num? ?? 0.8).toDouble();
          final personalizedLetter = report['personalized_letter'] as String? ?? '';
          final selfCarePlan = Map<String, dynamic>.from(report['self_care_plan'] ?? {});
          final activities = List<String>.from(selfCarePlan['activities'] ?? []);
          final suggestionText = activities.isNotEmpty ? activities.join('\n• ') : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 60),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ── Current Mood Header ──
                _buildMoodHeader(profile, emotionVector, dominant, stabilityLabel, stabilityIndex)
                    .animate().fadeIn(duration: 500.ms).slideY(begin: -0.05),

                const SizedBox(height: 24),

                // ── Radar Chart ──
                _buildRadarSection(emotionVector)
                    .animate().fadeIn(duration: 500.ms, delay: 100.ms)
                    .scale(begin: const Offset(0.9, 0.9), duration: 500.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 24),

                // ── Emotion Breakdown ──
                _buildEmotionBreakdown(emotionVector)
                    .animate().fadeIn(duration: 400.ms, delay: 200.ms),

                const SizedBox(height: 24),

                // ── 7-Day Timeline ──
                _buildTimelineSection(profile)
                    .animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05),

                const SizedBox(height: 24),

                // ── AI Insight ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AIInsightCard(
                    insight: personalizedLetter,
                    suggestion: suggestionText.isNotEmpty ? '• $suggestionText' : null,
                    wellbeingScore: (stabilityIndex * 100).round(),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.05),
                const SizedBox(height: 24),
                _buildChallengesBanner(context).animate().fadeIn(duration: 400.ms, delay: 450.ms).slideY(begin: 0.05),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChallengesBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AuraColors.primary.withValues(alpha: 0.15),
            AuraColors.secondary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AuraColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AuraColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.eco_outlined,
              color: AuraColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thử thách tâm hồn',
                  style: AuraTypography.titleMedium.copyWith(
                    color: AuraColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rèn luyện tinh thần cùng AI hàng ngày.',
                  style: AuraTypography.bodySmall.copyWith(
                    color: AuraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => GoRouter.of(context).push('/challenges'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodHeader(EmotionProfileModel profile, Map<String, double> emotionVector, String dominant, String stabilityLabel, double stabilityIndex) {
    final dominantColor = AuraColors.getEmotionColor(dominant);

    // Calculate valence: positive emotions minus negative emotions
    final joy = emotionVector['joy'] ?? 0.0;
    final trust = emotionVector['trust'] ?? 0.0;
    final anticipation = emotionVector['anticipation'] ?? 0.0;
    final sadness = emotionVector['sadness'] ?? 0.0;
    final fear = emotionVector['fear'] ?? 0.0;
    final anger = emotionVector['anger'] ?? 0.0;
    final disgust = emotionVector['disgust'] ?? 0.0;
    final valence = (joy + trust + anticipation) - (sadness + fear + anger + disgust);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dominantColor.withValues(alpha: 0.08),
            AuraColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dominantColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          AuraRing(
            size: 60,
            emotionVector: emotionVector,
            confidence: profile.emotionConfidence,
            arousal: profile.arousal,
            glowIntensity: 0.5,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Mood trung bình',
                        style: AuraTypography.labelMedium.copyWith(
                          color: AuraColors.textTertiary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: dominantColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🧭 $stabilityLabel',
                        style: AuraTypography.labelSmall.copyWith(color: dominantColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_getEmoji(dominant)} ${_capitalize(dominant)}',
                  style: AuraTypography.headlineSmall.copyWith(
                    color: dominantColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Valence: ', style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.textTertiary)),
                    Text(
                      valence >= 0 ? '+${valence.toStringAsFixed(2)}' : valence.toStringAsFixed(2),
                      style: AuraTypography.bodySmall.copyWith(
                        color: valence >= 0 ? AuraColors.success : AuraColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Stability: ', style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.textTertiary)),
                    Text('${(stabilityIndex * 100).round()}%', style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSection(Map<String, double> emotionVector) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Phổ cảm xúc',
                  style: AuraTypography.titleMedium.copyWith(
                    color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AuraColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('8D Vector', style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.textTertiary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          EmotionRadarChart(emotionVector: emotionVector, size: 240),
        ],
      ),
    );
  }

  Widget _buildEmotionBreakdown(Map<String, double> emotionVector) {
    final sorted = emotionVector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi tiết cảm xúc', style: AuraTypography.titleMedium.copyWith(
            color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          ...sorted.map((e) => _emotionBar(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _emotionBar(String emotion, double value) {
    final color = AuraColors.getEmotionColor(emotion);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(_getEmoji(emotion), style: const TextStyle(fontSize: 14)),
          ),
          SizedBox(
            width: 84,
            child: Text(_capitalize(emotion),
                style: AuraTypography.labelMedium.copyWith(color: AuraColors.textSecondary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AuraColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '${(value * 100).round()}%',
              style: AuraTypography.labelSmall.copyWith(
                color: AuraColors.textTertiary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(EmotionProfileModel profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Hành trình cảm xúc (7 ngày)',
                  style: AuraTypography.titleMedium.copyWith(
                    color: AuraColors.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          EmotionTimeline(height: 200, weeklyPattern: profile.weeklyPattern),
        ],
      ),
    );
  }

  String _getEmoji(String emotion) {
    const map = {
      'joy': '😊', 'trust': '🤝', 'anticipation': '🎯', 'surprise': '😮',
      'sadness': '😢', 'fear': '😰', 'anger': '😠', 'disgust': '🤢',
    };
    return map[emotion] ?? '❓';
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuraColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AuraColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('🧭 Emotional Compass là gì?',
                style: AuraTypography.headlineSmall.copyWith(color: AuraColors.textPrimary)),
            const SizedBox(height: 12),
            Text(
              'Emotional Compass phân tích cảm xúc của bạn dựa trên:\n\n'
              '• Nội dung bài viết của bạn\n'
              '• Reactions bạn gửi đi\n'
              '• Thời gian bạn xem các loại nội dung\n'
              '• Hành vi tương tác trên AURA\n\n'
              'Tất cả được xử lý ẩn danh và bạn có thể tắt bất kỳ lúc nào trong Cài đặt AI.',
              style: AuraTypography.bodyMedium.copyWith(color: AuraColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
