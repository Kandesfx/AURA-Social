import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/emotion_profile_provider.dart';
import '../../../shared/models/emotion_profile_model.dart';
import '../widgets/break_card.dart';
import '../widgets/crisis_resource_card.dart';
import '../../compass/widgets/ai_insight_card.dart';

/// AURA Social – Wellbeing Screen (Theo dõi sức khỏe tinh thần)
///
/// Person 4 – Màn hình trung tâm wellbeing.
/// Tập hợp: mood overview, gợi ý nghỉ ngơi, bài tập thở, và thông tin hỗ trợ khẩn cấp.
///
/// Đọc dữ liệu từ [currentEmotionProfileProvider] (read-only).
/// Không chỉnh sửa hay phụ thuộc vào logic của các màn hình khác.
class WellbeingScreen extends ConsumerWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emotionProfileAsync = ref.watch(currentEmotionProfileProvider);

    return Scaffold(
      backgroundColor: AuraColors.background,
      appBar: AppBar(
        backgroundColor: AuraColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AuraColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧘', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Wellbeing',
              style: AuraTypography.titleLarge
                  .copyWith(color: AuraColors.textPrimary),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: emotionProfileAsync.when(
        data: (profile) => _buildContent(context, profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _buildContent(context, const EmotionProfileModel()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EmotionProfileModel profile) {
    final wellbeingScore = _calculateWellbeingScore(profile);
    final isCrisis = profile.valence <= -0.5;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Wellbeing Score Overview ──
          _buildScoreCard(wellbeingScore, profile)
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.05),

          const SizedBox(height: 20),

          // ── Mood Summary ──
          _buildMoodSummary(profile)
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 20),

          // ── Section: Gợi ý nghỉ ngơi ──
          _buildSectionTitle('💤 Gợi ý nghỉ ngơi'),
          const SizedBox(height: 8),
          _buildBreakSuggestions(context, profile)
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: 20),

          // ── Section: Bài tập thở ──
          _buildSectionTitle('🌬️ Bài tập thở'),
          const SizedBox(height: 8),
          _buildBreathingExercise(profile)
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms),

          const SizedBox(height: 20),

          // ── AI Insight ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AIInsightCard(
              insight: profile.weeklyTrend['insight_summary'] ??
                  'Hãy dành thời gian cho bản thân mỗi ngày. Những khoảnh khắc nhỏ cũng giúp cải thiện sức khỏe tinh thần đáng kể.',
              suggestion: profile.weeklyTrend['suggestion'] ??
                  'Thử nghe nhạc nhẹ hoặc đi bộ 10 phút vào buổi chiều',
              wellbeingScore: wellbeingScore,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

          const SizedBox(height: 20),

          // ── Section: Hỗ trợ khẩn cấp (luôn hiển thị) ──
          _buildSectionTitle('💜 Hỗ trợ sức khỏe tinh thần'),
          const SizedBox(height: 8),
          _buildCrisisSection(context, isCrisis)
              .animate()
              .fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // WELLBEING SCORE CARD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildScoreCard(int score, EmotionProfileModel profile) {
    final scoreColor = _getScoreColor(score);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.12),
            AuraColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      scoreColor.withValues(alpha: 0.2),
                      scoreColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: AuraTypography.displayMedium.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wellbeing Score',
                      style: AuraTypography.titleMedium.copyWith(
                        color: AuraColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getScoreLabel(score),
                      style: AuraTypography.bodyMedium.copyWith(
                        color: scoreColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.moodDescription,
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 8,
              backgroundColor: AuraColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // MOOD SUMMARY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildMoodSummary(EmotionProfileModel profile) {
    final dominant = profile.dominantEmotion;
    final dominantColor = AuraColors.getEmotionColor(dominant);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dominantColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(_getEmoji(dominant),
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cảm xúc chủ đạo',
                  style: AuraTypography.labelMedium.copyWith(
                    color: AuraColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _capitalize(dominant),
                  style: AuraTypography.titleMedium.copyWith(
                    color: dominantColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Valence',
                style: AuraTypography.labelSmall.copyWith(
                  color: AuraColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${profile.valence >= 0 ? "+" : ""}${profile.valence.toStringAsFixed(2)}',
                style: AuraTypography.titleSmall.copyWith(
                  color: profile.valence >= 0
                      ? AuraColors.success
                      : AuraColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BREAK SUGGESTIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildBreakSuggestions(
      BuildContext context, EmotionProfileModel profile) {
    final isStressed = profile.valence < -0.2;

    return Column(
      children: [
        WellbeingBreakCard(
          title: isStressed
              ? 'Có vẻ bạn đang căng thẳng'
              : 'Nghỉ ngơi một chút nhé!',
          subtitle: isStressed
              ? 'Hãy tạm dừng và dành vài phút cho bản thân. Bạn xứng đáng được nghỉ ngơi.'
              : 'Bạn đang làm rất tốt! Nhưng đừng quên nghỉ giải lao để duy trì năng lượng.',
          variant: isStressed ? 'session_break' : 'positive_inject',
          suggestion: isStressed
              ? 'Thử đi bộ ngắn 5 phút hoặc uống một cốc nước ấm'
              : 'Nghe một bài nhạc yêu thích hoặc nhắm mắt thư giãn 2 phút',
          onDismiss: () {},
          onViewCompass: isStressed ? () => context.push('/compass') : null,
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BREATHING EXERCISE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildBreathingExercise(EmotionProfileModel profile) {
    final isStressed = profile.valence < -0.2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D1F3C),
            const Color(0xFF0A1628),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AuraColors.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌬️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isStressed ? 'Hít thở sâu – 4-7-8' : 'Box Breathing – 4-4-4-4',
                  style: AuraTypography.titleMedium.copyWith(
                    color: AuraColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isStressed
                ? 'Kỹ thuật thở 4-7-8 giúp giảm căng thẳng nhanh chóng. Hít vào 4 giây, giữ 7 giây, thở ra 8 giây.'
                : 'Box Breathing giúp cân bằng hệ thần kinh. Hít vào 4 giây, giữ 4 giây, thở ra 4 giây, giữ 4 giây.',
            style: AuraTypography.bodyMedium.copyWith(
              color: AuraColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Steps
          ...(_buildBreathingSteps(isStressed)),
        ],
      ),
    );
  }

  List<Widget> _buildBreathingSteps(bool isStressed) {
    final steps = isStressed
        ? [
            _BreathStep(icon: '1️⃣', text: 'Hít vào bằng mũi — 4 giây'),
            _BreathStep(icon: '2️⃣', text: 'Giữ hơi thở — 7 giây'),
            _BreathStep(icon: '3️⃣', text: 'Thở ra bằng miệng — 8 giây'),
            _BreathStep(icon: '🔄', text: 'Lặp lại 3-4 lần'),
          ]
        : [
            _BreathStep(icon: '1️⃣', text: 'Hít vào bằng mũi — 4 giây'),
            _BreathStep(icon: '2️⃣', text: 'Giữ hơi thở — 4 giây'),
            _BreathStep(icon: '3️⃣', text: 'Thở ra từ từ — 4 giây'),
            _BreathStep(icon: '4️⃣', text: 'Giữ hết hơi — 4 giây'),
          ];

    return steps
        .map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(step.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 10),
                  Text(
                    step.text,
                    style: AuraTypography.bodySmall.copyWith(
                      color: AuraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CRISIS SECTION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildCrisisSection(BuildContext context, bool isCrisis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCrisis)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AuraColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AuraColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AuraColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chúng mình nhận thấy bạn có dấu hiệu cần được hỗ trợ. '
                      'Đừng ngại liên hệ các dịch vụ bên dưới nhé.',
                      style: AuraTypography.bodySmall.copyWith(
                        color: AuraColors.error,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        CrisisResourceCard(
          onDismiss: null,
          onStartAnonymousChat: () => context.push('/chat'),
          onCallHotline: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đang kết nối tới đường dây nóng...'),
              ),
            );
          },
        ),

        // Additional resources
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AuraColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AuraColors.surfaceBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Các đường dây hỗ trợ khác',
                style: AuraTypography.labelMedium.copyWith(
                  color: AuraColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildHotlineRow(
                  '🏥', 'Tổng đài Sức khỏe Tâm thần', '1800 599 920'),
              const SizedBox(height: 8),
              _buildHotlineRow(
                  '📞', 'Tổng đài Tư vấn Tâm lý', '1800 599 100'),
              const SizedBox(height: 8),
              _buildHotlineRow(
                  '👶', 'Tổng đài bảo vệ trẻ em', '111'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotlineRow(String icon, String name, String phone) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: AuraTypography.bodySmall.copyWith(
              color: AuraColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AuraColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            phone,
            style: AuraTypography.labelSmall.copyWith(
              color: AuraColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: AuraTypography.titleMedium.copyWith(
          color: AuraColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  int _calculateWellbeingScore(EmotionProfileModel profile) {
    if (profile.weeklyTrend.containsKey('wellbeing_score')) {
      return (profile.weeklyTrend['wellbeing_score'] as num).toInt();
    }
    final stability = (profile.weeklyTrend['stability_score'] ?? 0.7) as num;
    final avgValence = (profile.weeklyTrend['avg_valence'] ?? 0.35) as num;
    final score =
        (50 + (avgValence * 30) + (stability * 20)).round().clamp(0, 100);
    return score;
  }

  Color _getScoreColor(int score) {
    if (score >= 75) return AuraColors.success;
    if (score >= 50) return AuraColors.warning;
    return AuraColors.error;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Tuyệt vời! 🌟';
    if (score >= 60) return 'Khá tốt 😊';
    if (score >= 40) return 'Cần chú ý 😐';
    if (score >= 20) return 'Nên nghỉ ngơi 😔';
    return 'Cần hỗ trợ 💙';
  }

  String _getEmoji(String emotion) {
    const map = {
      'joy': '😊',
      'trust': '🤝',
      'anticipation': '🎯',
      'surprise': '😮',
      'sadness': '😢',
      'fear': '😰',
      'anger': '😠',
      'disgust': '🤢',
    };
    return map[emotion] ?? '🧭';
  }

  String _capitalize(String s) =>
      s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
}

/// Helper model cho breathing steps (private, chỉ dùng trong file này)
class _BreathStep {
  final String icon;
  final String text;
  const _BreathStep({required this.icon, required this.text});
}
