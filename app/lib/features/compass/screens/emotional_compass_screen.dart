import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/aura_ring_widget.dart';
import '../widgets/emotion_radar_chart.dart';
import '../widgets/emotion_timeline.dart';
import '../widgets/ai_insight_card.dart';

/// AURA Social – Emotional Compass Screen
///
/// Person 4, Task #12
/// Full emotional profile view: radar chart, 7-day timeline, AI insights.
class EmotionalCompassScreen extends StatelessWidget {
  const EmotionalCompassScreen({super.key});

  // Mock data
  static const _emotionVector = {
    'joy': 0.30,
    'trust': 0.20,
    'anticipation': 0.25,
    'surprise': 0.10,
    'sadness': 0.05,
    'fear': 0.04,
    'anger': 0.03,
    'disgust': 0.03,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotional Compass'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Current Mood Header ──
            _buildMoodHeader()
                .animate().fadeIn(duration: 500.ms).slideY(begin: -0.05),

            const SizedBox(height: 24),

            // ── Radar Chart ──
            _buildRadarSection()
                .animate().fadeIn(duration: 500.ms, delay: 100.ms)
                .scale(begin: const Offset(0.9, 0.9), duration: 500.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            // ── Emotion Breakdown ──
            _buildEmotionBreakdown()
                .animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 24),

            // ── 7-Day Timeline ──
            _buildTimelineSection()
                .animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ── AI Insight ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const AIInsightCard(
                insight: 'Bạn thường vui vào cuối tuần và stressed vào T3-T4. '
                    'Hoạt động thể chất giúp tăng mood của bạn đáng kể.',
                suggestion: 'Hãy thử dành 15 phút tập thể dục vào buổi sáng T3-T4',
                wellbeingScore: 72,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodHeader() {
    // Find dominant emotion
    final sorted = _emotionVector.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dominant = sorted.first;
    final dominantColor = AuraColors.getEmotionColor(dominant.key);

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
            emotionVector: _emotionVector,
            glowIntensity: 0.5,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Mood hiện tại',
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
                        '🧭 explore',
                        style: AuraTypography.labelSmall.copyWith(color: dominantColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_getEmoji(dominant.key)} ${_capitalize(dominant.key)}',
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
                    Text('+0.65', style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.success, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Text('Confidence: ', style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.textTertiary)),
                    Text('78%', style: AuraTypography.bodySmall.copyWith(
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

  Widget _buildRadarSection() {
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
          const EmotionRadarChart(emotionVector: _emotionVector, size: 240),
        ],
      ),
    );
  }

  Widget _buildEmotionBreakdown() {
    final sorted = _emotionVector.entries.toList()
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
            width: 72,
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

  Widget _buildTimelineSection() {
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
          const EmotionTimeline(height: 200),
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
