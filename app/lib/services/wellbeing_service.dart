import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../providers/api_service_provider.dart';

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
  final AuraApiService _apiService;

  WellbeingService(this._apiService);

  /// Lấy báo cáo sức khỏe tinh thần hàng tuần từ FastAPI backend
  Future<Map<String, dynamic>> getWeeklyReport() async {
    try {
      final response = await _apiService.get('/api/v1/wellbeing/report');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      // ignore: avoid_print
      print('[WellbeingService] Error fetching weekly report: $e');
      rethrow;
    }
  }

  /// Check wellbeing status dựa trên behavioral data
  ///
  /// API: POST /wellbeing/check
  /// Body: { session_duration_minutes, current_emotion_vector }
  Future<WellbeingResult> checkWellbeing({
    required int sessionDurationMinutes,
    required Map<String, double> currentEmotionVector,
  }) async {
    try {
      final response = await _apiService.post('/api/v1/wellbeing/check', data: {
        'session_duration_minutes': sessionDurationMinutes,
        'current_emotion_vector': currentEmotionVector,
      });

      final data = response.data;
      final breakTypeStr = data['break_type'] as String?;
      BreakType type = BreakType.none;
      if (breakTypeStr == 'session_break') {
        type = BreakType.sessionBreak;
      } else if (breakTypeStr == 'positive_inject') {
        type = BreakType.positiveInject;
      }

      return WellbeingResult(
        shouldBreak: data['should_break'] ?? false,
        breakType: type,
        title: data['title'] ?? '',
        subtitle: data['subtitle'] ?? '',
        wellbeingScore: data['wellbeing_score'] ?? 75,
        suggestion: data['suggestion'],
      );
    } catch (e) {
      // ignore: avoid_print
      print('[WellbeingService] Error checking wellbeing: $e');
      
      // Fallback local logic
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
  }

  /// Lấy wellbeing score tổng hợp từ backend
  Future<int> getWellbeingScore() async {
    try {
      final response = await _apiService.get('/api/v1/wellbeing/score');
      return response.data['score'] ?? 75;
    } catch (e) {
      // ignore: avoid_print
      print('[WellbeingService] Error fetching wellbeing score: $e');
      return 72; // Fallback mock score
    }
  }

  /// Lấy daily insight cho Emotional Compass từ backend
  Future<WellbeingInsight> getDailyInsight() async {
    try {
      final response = await _apiService.get('/api/v1/wellbeing/daily-insight');
      final data = response.data;
      return WellbeingInsight(
        summary: data['summary'] ?? '',
        positivePattern: data['positive_pattern'] ?? '',
        suggestion: data['suggestion'] ?? '',
        wellbeingScore: data['wellbeing_score'] ?? 72,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[WellbeingService] Error fetching daily insight: $e');
      return WellbeingInsight(
        summary: 'Bạn thường vui vào cuối tuần và stressed vào T3-T4',
        positivePattern: 'Hoạt động thể chất giúp tăng mood của bạn',
        suggestion: 'Hãy thử dành 15 phút tập thể dục vào buổi sáng',
        wellbeingScore: 72,
      );
    }
  }

  /// Lấy danh sách thử thách sức khỏe tinh thần đang hoạt động
  Future<List<ChallengeItem>> getActiveChallenges() async {
    try {
      final response = await _apiService.get('/api/v1/challenges/active');
      final list = response.data['challenges'] as List?;
      return list?.map((item) => ChallengeItem.fromJson(Map<String, dynamic>.from(item))).toList() ?? [];
    } catch (e) {
      // ignore: avoid_print
      print('[WellbeingService] Error fetching active challenges: $e');
      return [];
    }
  }

  /// Hoàn thành / cập nhật tiến độ của thử thách
  Future<bool> completeChallenge(String challengeId, {int progressIncrement = 1}) async {
    try {
      final response = await _apiService.post('/api/v1/challenges/complete', data: {
        'challenge_id': challengeId,
        'progress_increment': progressIncrement,
      });
      return response.data['success'] ?? false;
    } catch (e) {
      // ignore: avoid_print
      print('[WellbeingService] Error completing challenge: $e');
      return false;
    }
  }
}

/// Provider cho WellbeingService
final wellbeingServiceProvider = Provider<WellbeingService>((ref) {
  return WellbeingService(ref.read(apiServiceProvider));
});

/// Provider cho báo cáo tuần từ backend
final weeklyReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final service = ref.watch(wellbeingServiceProvider);
  return service.getWeeklyReport();
});

/// StateNotifier quản lý danh sách thử thách đang hoạt động
class ActiveChallengesNotifier extends StateNotifier<AsyncValue<List<ChallengeItem>>> {
  final WellbeingService _wellbeingService;

  ActiveChallengesNotifier(this._wellbeingService) : super(const AsyncValue.loading()) {
    loadChallenges();
  }

  Future<void> loadChallenges() async {
    state = const AsyncValue.loading();
    try {
      final challenges = await _wellbeingService.getActiveChallenges();
      state = AsyncValue.data(challenges);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> completeChallenge(String challengeId) async {
    try {
      final success = await _wellbeingService.completeChallenge(challengeId);
      if (success) {
        await loadChallenges();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}

/// Provider cho ActiveChallengesNotifier
final activeChallengesProvider = StateNotifierProvider.autoDispose<ActiveChallengesNotifier, AsyncValue<List<ChallengeItem>>>((ref) {
  return ActiveChallengesNotifier(ref.watch(wellbeingServiceProvider));
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

class ChallengeItem {
  final String id;
  final String title;
  final String description;
  final int durationDays;
  final String category;
  final String status; // "active", "completed", "expired"
  final int progress;
  final int maxProgress;
  final String createdAt;
  final String? completedAt;

  ChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.category,
    required this.status,
    required this.progress,
    required this.maxProgress,
    required this.createdAt,
    this.completedAt,
  });

  factory ChallengeItem.fromJson(Map<String, dynamic> json) {
    return ChallengeItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      durationDays: json['duration_days'] ?? 1,
      category: json['category'] ?? 'default',
      status: json['status'] ?? 'active',
      progress: json['progress'] ?? 0,
      maxProgress: json['max_progress'] ?? 1,
      createdAt: json['created_at'] ?? '',
      completedAt: json['completed_at'],
    );
  }
}

