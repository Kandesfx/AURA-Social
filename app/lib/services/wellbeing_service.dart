import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AURA Social – Wellbeing Service
///
/// Person 4, Task #4
/// Gọi FastAPI /wellbeing/check để kiểm tra tình trạng sức khỏe tinh thần.
/// Hiện tại sử dụng mock data.
///
/// Wellbeing Guard logic:
/// 1. Sau mỗi 30 phút scrolling → suggest break
/// 2. Phát hiện negative emotion trend → inject positive content
/// 3. Cảnh báo nếu session quá dài
class WellbeingService {
  WellbeingService();

  /// Check wellbeing status dựa trên behavioral data
  ///
  /// API: POST /wellbeing/check
  /// Body: { user_id, session_duration, emotion_trend, scroll_depth }
  Future<WellbeingResult> checkWellbeing({
    required int sessionDurationMinutes,
    required Map<String, double> currentEmotionVector,
  }) async {
    // TODO: Replace với real API call
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock logic: suggest break sau 30 phút
    if (sessionDurationMinutes >= 30) {
      return WellbeingResult(
        shouldBreak: true,
        breakType: BreakType.sessionBreak,
        title: '🌙 Nghỉ ngơi một chút nhé!',
        subtitle: 'Bạn đã sử dụng AURA được $sessionDurationMinutes phút. '
            'Hãy dành chút thời gian để thư giãn.',
        wellbeingScore: 65,
        suggestion: 'Thử nhìn ra cửa sổ hoặc uống một ly nước 💧',
      );
    }

    // Mock logic: inject positive content nếu negative trend
    final negativeScore = (currentEmotionVector['sadness'] ?? 0) +
        (currentEmotionVector['fear'] ?? 0) +
        (currentEmotionVector['anger'] ?? 0);

    if (negativeScore > 0.4) {
      return WellbeingResult(
        shouldBreak: true,
        breakType: BreakType.positiveInject,
        title: '✨ Góc tươi sáng',
        subtitle: 'AURA nhận thấy bạn có thể cần một chút năng lượng tích cực.',
        wellbeingScore: 55,
        suggestion: 'Hãy xem Emotional Compass để hiểu rõ hơn cảm xúc của bạn 🧭',
      );
    }

    return WellbeingResult(
      shouldBreak: false,
      breakType: BreakType.none,
      title: '',
      subtitle: '',
      wellbeingScore: 85,
      suggestion: null,
    );
  }

  /// Lấy wellbeing score tổng hợp
  Future<int> getWellbeingScore() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 72; // Mock score
  }

  /// Lấy daily insight cho Emotional Compass
  Future<WellbeingInsight> getDailyInsight() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return WellbeingInsight(
      summary: 'Bạn thường vui vào cuối tuần và stressed vào T3-T4',
      positivePattern: 'Hoạt động thể chất giúp tăng mood của bạn',
      suggestion: 'Hãy thử dành 15 phút tập thể dục vào buổi sáng',
      wellbeingScore: 72,
    );
  }
}

/// Provider cho WellbeingService
final wellbeingServiceProvider = Provider<WellbeingService>((ref) {
  return WellbeingService();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum BreakType { none, sessionBreak, positiveInject }

class WellbeingResult {
  final bool shouldBreak;
  final BreakType breakType;
  final String title;
  final String subtitle;
  final int wellbeingScore;
  final String? suggestion;

  WellbeingResult({
    required this.shouldBreak,
    required this.breakType,
    required this.title,
    required this.subtitle,
    required this.wellbeingScore,
    this.suggestion,
  });
}

class WellbeingInsight {
  final String summary;
  final String positivePattern;
  final String suggestion;
  final int wellbeingScore;

  WellbeingInsight({
    required this.summary,
    required this.positivePattern,
    required this.suggestion,
    required this.wellbeingScore,
  });
}
